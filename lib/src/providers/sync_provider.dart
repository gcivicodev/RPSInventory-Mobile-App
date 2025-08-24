import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rpsinventory/src/config/main_config.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/models/m_deductible.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';
import 'package:rpsinventory/src/models/m_movements.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/models/m_warehouse_product.dart';
import 'package:sqflite/sqflite.dart';

enum SyncStatus { pending, inProgress, completed, error }

class SyncState {
  final SyncStatus uploadStatus;
  final bool isUploading;
  final SyncStatus productsStatus;
  final SyncStatus warehousesStatus;
  final SyncStatus warehousesProductsStatus;
  final SyncStatus conducesStatus;
  final SyncStatus deductiblesStatus;
  final SyncStatus movementsStatus;
  final SyncStatus inventoryProductsCountsStatus;
  final bool isSyncComplete;
  final String? errorMessage;

  SyncState({
    this.uploadStatus = SyncStatus.pending,
    this.isUploading = true,
    this.productsStatus = SyncStatus.pending,
    this.warehousesStatus = SyncStatus.pending,
    this.warehousesProductsStatus = SyncStatus.pending,
    this.conducesStatus = SyncStatus.pending,
    this.deductiblesStatus = SyncStatus.pending,
    this.movementsStatus = SyncStatus.pending,
    this.inventoryProductsCountsStatus = SyncStatus.pending,
    this.isSyncComplete = false,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? uploadStatus,
    bool? isUploading,
    SyncStatus? productsStatus,
    SyncStatus? warehousesStatus,
    SyncStatus? warehousesProductsStatus,
    SyncStatus? conducesStatus,
    SyncStatus? deductiblesStatus,
    SyncStatus? movementsStatus,
    SyncStatus? inventoryProductsCountsStatus,
    bool? isSyncComplete,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SyncState(
      uploadStatus: uploadStatus ?? this.uploadStatus,
      isUploading: isUploading ?? this.isUploading,
      productsStatus: productsStatus ?? this.productsStatus,
      warehousesStatus: warehousesStatus ?? this.warehousesStatus,
      warehousesProductsStatus:
      warehousesProductsStatus ?? this.warehousesProductsStatus,
      conducesStatus: conducesStatus ?? this.conducesStatus,
      deductiblesStatus: deductiblesStatus ?? this.deductiblesStatus,
      movementsStatus: movementsStatus ?? this.movementsStatus,
      inventoryProductsCountsStatus:
      inventoryProductsCountsStatus ?? this.inventoryProductsCountsStatus,
      isSyncComplete: isSyncComplete ?? this.isSyncComplete,
      errorMessage:
      clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState());

  final dbHelper = DBHelper.instance;

  Future<void> startSync(String token, String userId) async {
    state = SyncState();
    await _uploadCarreroData(token);
    if (state.uploadStatus == SyncStatus.completed) {
      state = state.copyWith(isUploading: false);
      await _startDownload(token, userId);
    }
  }

  Future<void> startSyncAlmacen(String token, String userId) async {
    state = SyncState();
    await _uploadAlmacenData(token);

    if (state.uploadStatus == SyncStatus.completed) {
      state = state.copyWith(isUploading: false);
      await _clearAlmacenTables();
      await _syncWarehousesAlmacen(token);
      if (state.warehousesStatus != SyncStatus.completed) return;
      await _syncWarehousesProductsAlmacen(token);
      if (state.warehousesProductsStatus != SyncStatus.completed) return;
      await _syncProductsAlmacen(token);
      if (state.productsStatus != SyncStatus.completed) return;
      await _syncMovementsAlmacen(token);
      if (state.movementsStatus != SyncStatus.completed) return;
      await _syncInventory(token);
      if (state.inventoryProductsCountsStatus != SyncStatus.completed) return;

      if (state.warehousesStatus == SyncStatus.completed &&
          state.warehousesProductsStatus == SyncStatus.completed &&
          state.productsStatus == SyncStatus.completed &&
          state.movementsStatus == SyncStatus.completed &&
          state.inventoryProductsCountsStatus == SyncStatus.completed) {
        state = state.copyWith(isSyncComplete: true);
      }
    }
  }

  Future<void> _clearAlmacenTables() async {
    final db = await dbHelper.database;
    await db.delete('warehouses');
    await db.delete('warehouses_products');
    await db.delete('products');
    await db.delete('movements');
    await db.delete('inventory_products_counts');
  }

  Future<void> _uploadCarreroData(String token) async {
    state = state.copyWith(
        uploadStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final conducesFromDb = await dbHelper.getConducesForSync();
      final detailsFromDb = await dbHelper.getConduceDetailsForSync();
      final notesToSync = await dbHelper.getConduceNotesForSync();

      final conducesToSync = conducesFromDb.map((conduce) {
        final newConduce = Map<String, dynamic>.from(conduce);
        return newConduce;
      }).toList();

      final detailsToSync = detailsFromDb.map((detail) {
        final newDetail = Map<String, dynamic>.from(detail);
        return newDetail;
      }).toList();

      if (conducesToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_conduces_carrero',
          token: token,
          body: {'token': token, 'conduces': conducesToSync},
        );
      }

      if (detailsToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_conduces_details_carrero',
          token: token,
          body: {'token': token, 'conduces_details': detailsToSync},
        );
      }

      if (notesToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_conduces_notes_carrero',
          token: token,
          body: {'token': token, 'conduces_notes': notesToSync},
        );
      }

      state = state.copyWith(uploadStatus: SyncStatus.completed);
    } catch (e) {
      state = state.copyWith(
        uploadStatus: SyncStatus.error,
        errorMessage: "Error en la subida: ${e.toString()}",
      );
    }
  }

  Future<void> _uploadAlmacenData(String token) async {
    state = state.copyWith(
        uploadStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final movementsToSync = await dbHelper.getMovementsForSync();
      final inventoryToSync =
      await dbHelper.getInventoryProductsCountsForSync();

      if (movementsToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_movements_almacen',
          token: token,
          body: {'token': token, 'movements': movementsToSync},
        );
      }

      if (inventoryToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_inventory_almacen',
          token: token,
          body: {'token': token, 'inventorys': inventoryToSync},
        );
      }

      state = state.copyWith(uploadStatus: SyncStatus.completed);
    } catch (e) {
      state = state.copyWith(
        uploadStatus: SyncStatus.error,
        errorMessage: "Error en la subida: ${e.toString()}",
      );
    }
  }

  Future<void> _postData({
    required String endpoint,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      final error =
          json.decode(response.body)['error'] ?? 'Error en $endpoint';
      throw Exception(error);
    }
  }

  Future<void> _startDownload(String token, String userId) async {
    await _syncProducts(token);
    if (state.productsStatus != SyncStatus.completed) return;

    await _syncWarehouses(token);
    if (state.warehousesStatus != SyncStatus.completed) return;

    await _syncWarehousesProducts(token);
    if (state.warehousesProductsStatus != SyncStatus.completed) return;

    await _syncConduces(token, userId);
    if (state.conducesStatus != SyncStatus.completed) return;

    await _syncDeductibles(token);
    if (state.deductiblesStatus != SyncStatus.completed) return;

    if (state.productsStatus == SyncStatus.completed &&
        state.warehousesStatus == SyncStatus.completed &&
        state.warehousesProductsStatus == SyncStatus.completed &&
        state.conducesStatus == SyncStatus.completed &&
        state.deductiblesStatus == SyncStatus.completed) {
      state = state.copyWith(isSyncComplete: true);
    }
  }

  Future<void> _syncProducts(String token) async {
    state = state.copyWith(
        productsStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_products');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> productList = json.decode(response.body);
        for (var productJson in productList) {
          await dbHelper.addOrUpdateProduct(Product.fromJson(productJson));
        }
        state = state.copyWith(productsStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar productos';
        state =
            state.copyWith(productsStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          productsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncWarehouses(String token) async {
    state = state.copyWith(
        warehousesStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url =
      Uri.parse('https://rpsinventory.com/public/api/sync_get_warehouses');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          await dbHelper.addOrUpdateWarehouse(Warehouse.fromJson(itemJson));
        }
        state = state.copyWith(warehousesStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar bodegas';
        state = state.copyWith(
            warehousesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          warehousesStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncWarehousesProducts(String token) async {
    state = state.copyWith(
        warehousesProductsStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          'https://rpsinventory.com/public/api/sync_get_warehouses_products');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          await dbHelper
              .addOrUpdateWarehouseProduct(WarehouseProduct.fromJson(itemJson));
        }
        state = state.copyWith(warehousesProductsStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar inventario de bodegas';
        state = state.copyWith(
            warehousesProductsStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          warehousesProductsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncConduces(String token, String userId) async {
    state = state.copyWith(
        conducesStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_conduces');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body:
          json.encode({'token': token, 'user_id': userId, 'conduces': []}));

      if (response.statusCode == 200) {
        final List<dynamic> conduceList = json.decode(response.body);
        for (var conduceJson in conduceList) {
          await dbHelper.addOrUpdateConduce(Conduce.fromJson(conduceJson));
        }
        state = state.copyWith(conducesStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar conduces';
        state =
            state.copyWith(conducesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          conducesStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncDeductibles(String token) async {
    state = state.copyWith(
        deductiblesStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_deductibles');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> deductibleList = json.decode(response.body);
        for (var deductibleJson in deductibleList) {
          await dbHelper
              .addOrUpdateDeductible(Deductible.fromMap(deductibleJson));
        }
        state = state.copyWith(deductiblesStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar deducibles';
        state = state.copyWith(
            deductiblesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          deductiblesStatus: SyncStatus.error,
          errorMessage:
          "Error de red al sincronizar deducibles: ${e.toString()}");
    }
  }

  Future<void> _syncWarehousesAlmacen(String token) async {
    state = state.copyWith(
        warehousesStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_warehouses_almacen');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          await dbHelper.addOrUpdateWarehouse(Warehouse.fromJson(itemJson));
        }
        state = state.copyWith(warehousesStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar almacenes';
        state = state.copyWith(
            warehousesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          warehousesStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncWarehousesProductsAlmacen(String token) async {
    state = state.copyWith(
        warehousesProductsStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_warehouses_products_almacen');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          await dbHelper
              .addOrUpdateWarehouseProduct(WarehouseProduct.fromJson(itemJson));
        }
        state = state.copyWith(warehousesProductsStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar productos de almacén';
        state = state.copyWith(
            warehousesProductsStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          warehousesProductsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncProductsAlmacen(String token) async {
    state = state.copyWith(
        productsStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_products_almacen');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> productList = json.decode(response.body);
        for (var productJson in productList) {
          await dbHelper.addOrUpdateProduct(Product.fromJson(productJson));
        }
        state = state.copyWith(productsStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar productos';
        state =
            state.copyWith(productsStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          productsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncMovementsAlmacen(String token) async {
    state = state.copyWith(
        movementsStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_warehouses_products_movements_almacen');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> movementList = json.decode(response.body);
        for (var movementJson in movementList) {
          final db = await dbHelper.database;
          await db.insert('movements', Movement.fromJson(movementJson).toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        state = state.copyWith(movementsStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar movimientos';
        state = state.copyWith(
            movementsStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          movementsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncInventory(String token) async {
    state = state.copyWith(
        inventoryProductsCountsStatus: SyncStatus.inProgress,
        errorMessage: null,
        clearErrorMessage: true);
    try {
      final url = Uri.parse(
          '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_inventory');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final db = await dbHelper.database;
        for (var itemJson in list) {
          await db.insert('inventory_products_counts',
              InventoryProductsCount.fromJson(itemJson).toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        state =
            state.copyWith(inventoryProductsCountsStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ??
            'Error al sincronizar inventario';
        state = state.copyWith(
            inventoryProductsCountsStatus: SyncStatus.error,
            errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          inventoryProductsCountsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

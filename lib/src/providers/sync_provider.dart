import 'dart:convert';
import 'dart:developer';
import 'dart:developer';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
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
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState());

  final dbHelper = DBHelper.instance;
  DateTime? _lastServerSync;

  DateTime? get lastServerSync => _lastServerSync;

  Future<void> startSync(String token, String userId) async {
    _lastServerSync = null;
    state = SyncState();
    await _uploadCarreroData(token);
    if (state.uploadStatus == SyncStatus.completed) {
      state = state.copyWith(isUploading: false);
      await _startDownload(token, userId);
    }
  }

  Future<void> startSyncAlmacen(
    String token,
    String userId, {
    String? lastSync,
  }) async {
    _lastServerSync = null;
    state = SyncState();
    await _uploadAlmacenData(token, lastSync: lastSync);

    if (state.uploadStatus == SyncStatus.completed) {
      state = state.copyWith(isUploading: false);
      final syncTimestamp = lastSync ?? '';
      await _syncWarehousesAlmacen(token, syncTimestamp);
      if (state.warehousesStatus != SyncStatus.completed) return;
      await _syncWarehousesProductsAlmacen(token, syncTimestamp);
      if (state.warehousesProductsStatus != SyncStatus.completed) return;
      await _syncProductsAlmacen(token, syncTimestamp);
      if (state.productsStatus != SyncStatus.completed) return;
      await _syncMovementsAlmacen(token, syncTimestamp);
      if (state.movementsStatus != SyncStatus.completed) return;
      await _syncInventory(token, syncTimestamp);
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

  Future<void> _uploadCarreroData(String token) async {
    state = state.copyWith(
      uploadStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final conducesFromDb = await dbHelper.getConducesForSync();
      final lastSync = await dbHelper.getLastSyncDate();
      final detailsFromDb = await dbHelper.getConduceDetailsForSync(
        lastSync: lastSync,
      );
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

  Future<void> _uploadAlmacenData(
    String token, {
    String? lastSync,
  }) async {
    state = state.copyWith(
      uploadStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final movementsToSync = await dbHelper.getMovementsForSync(
        lastSync: lastSync,
      );
      final inventoryToSync = await dbHelper.getInventoryProductsCountsForSync(
        lastSync: lastSync,
      );
      final sanitizedMovements = _sanitizeLocalIds(movementsToSync);
      final sanitizedInventory = _sanitizeLocalIds(inventoryToSync);

      if (sanitizedMovements.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_movements_almacen',
          token: token,
          body: {'token': token, 'movements': sanitizedMovements},
        );
      }

      if (sanitizedInventory.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_inventory_almacen',
          token: token,
          body: {'token': token, 'inventorys': sanitizedInventory},
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

  List<Map<String, dynamic>> _sanitizeLocalIds(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row);
      final localId = data['local_id'];
      if (localId != null && data['id'] == localId) {
        data['id'] = null;
      }
      return data;
    }).toList();
  }

  Future<void> _postData({
    required String endpoint,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse(
      '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/$endpoint',
    );
    final encodedBody = json.encode(body);
    // log('[sync_provider] POST $url');
    // log('[sync_provider] Token: $token');
    // log('[sync_provider] Body: $encodedBody');
    // try {
    //   final directory = await getApplicationDocumentsDirectory();
    //   final logFile = File('${directory.path}/logs.txt');
    //   final logContent = 'URL: $url\nToken: $token\nBody: $encodedBody';
    //   await logFile.writeAsString(logContent);
    // } catch (e) {
    //   log('Failed to write sync log: $e');
    // }
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: encodedBody,
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'] ?? 'Error en $endpoint';
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
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_products',
      );
      final lastSync = await dbHelper.getLastSyncDate();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync ?? ''}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final productList = _parseResponseList(
          response.body,
          listKeys: const ['products', 'data'],
        );
        for (var productJson in productList) {
          await dbHelper.addOrUpdateProduct(Product.fromJson(productJson));
        }
        state = state.copyWith(productsStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar productos';
        state = state.copyWith(
          productsStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        productsStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncWarehouses(String token) async {
    state = state.copyWith(
      warehousesStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        'https://rpsinventory.com/public/api/sync_get_warehouses',
      );
      final lastSync = await dbHelper.getLastSyncDate();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync ?? ''}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final list = _parseResponseList(
          response.body,
          listKeys: const ['warehouses', 'data'],
        );
        for (var itemJson in list) {
          await dbHelper.addOrUpdateWarehouse(Warehouse.fromJson(itemJson));
        }
        state = state.copyWith(warehousesStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar bodegas';
        state = state.copyWith(
          warehousesStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        warehousesStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncWarehousesProducts(String token) async {
    state = state.copyWith(
      warehousesProductsStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        'https://rpsinventory.com/public/api/sync_get_warehouses_products',
      );
      final lastSync = await dbHelper.getLastSyncDate();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync ?? ''}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final list = _parseResponseList(
          response.body,
          listKeys: const ['warehouses_products', 'data'],
        );
        for (var itemJson in list) {
          await dbHelper.addOrUpdateWarehouseProduct(
            WarehouseProduct.fromJson(itemJson),
          );
        }
        state = state.copyWith(warehousesProductsStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar inventario de bodegas';
        state = state.copyWith(
          warehousesProductsStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        warehousesProductsStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncConduces(String token, String userId) async {
    state = state.copyWith(
      conducesStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_conduces',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'user_id': userId, 'conduces': []}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final List<dynamic> conduceList = json.decode(response.body);
        for (var conduceJson in conduceList) {
          await dbHelper.addOrUpdateConduce(Conduce.fromJson(conduceJson));
        }
        state = state.copyWith(conducesStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar conduces';
        state = state.copyWith(
          conducesStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        conducesStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncDeductibles(String token) async {
    state = state.copyWith(
      deductiblesStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_deductibles',
      );
      final lastSync = await dbHelper.getLastSyncDate();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync ?? ''}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final deductibleList = _parseResponseList(
          response.body,
          listKeys: const ['deductibles', 'data'],
        );
        for (var deductibleJson in deductibleList) {
          await dbHelper.addOrUpdateDeductible(
            Deductible.fromMap(deductibleJson),
          );
        }
        state = state.copyWith(deductiblesStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar deducibles';
        state = state.copyWith(
          deductiblesStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        deductiblesStatus: SyncStatus.error,
        errorMessage: "Error de red al sincronizar deducibles: ${e.toString()}",
      );
    }
  }

  List<dynamic> _parseResponseList(
    String body, {
    required List<String> listKeys,
  }) {
    final decoded = json.decode(body);
    return _extractList(decoded, listKeys);
  }

  List<dynamic> _extractList(dynamic data, List<String> listKeys) {
    if (data is List<dynamic>) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is String && error.isNotEmpty) {
          throw Exception(error);
        }
      }

      for (final key in listKeys) {
        if (!data.containsKey(key)) {
          continue;
        }
        final nested = _extractList(data[key], listKeys);
        if (nested.isNotEmpty || data[key] is List<dynamic>) {
          return nested;
        }
      }

      if (data.containsKey('data')) {
        final nested = _extractList(data['data'], listKeys);
        if (nested.isNotEmpty || data['data'] is List<dynamic>) {
          return nested;
        }
      }

      if (data.containsKey('results')) {
        final nested = _extractList(data['results'], listKeys);
        if (nested.isNotEmpty || data['results'] is List<dynamic>) {
          return nested;
        }
      }
    }

    return <dynamic>[];
  }

  Future<void> _syncWarehousesAlmacen(String token, String lastSync) async {
    state = state.copyWith(
      warehousesStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_warehouses_almacen',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          await dbHelper.addOrUpdateWarehouse(Warehouse.fromJson(itemJson));
        }
        state = state.copyWith(warehousesStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar almacenes';
        state = state.copyWith(
          warehousesStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        warehousesStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncWarehousesProductsAlmacen(
    String token,
    String lastSync,
  ) async {
    state = state.copyWith(
      warehousesProductsStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_warehouses_products_almacen',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          await dbHelper.addOrUpdateWarehouseProduct(
            WarehouseProduct.fromJson(itemJson),
          );
        }
        state = state.copyWith(warehousesProductsStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar productos de almacén';
        state = state.copyWith(
          warehousesProductsStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        warehousesProductsStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncProductsAlmacen(String token, String lastSync) async {
    state = state.copyWith(
      productsStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_products_almacen',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final List<dynamic> productList = json.decode(response.body);
        for (var productJson in productList) {
          await dbHelper.addOrUpdateProduct(Product.fromJson(productJson));
        }
        state = state.copyWith(productsStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar productos';
        state = state.copyWith(
          productsStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        productsStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncMovementsAlmacen(String token, String lastSync) async {
    state = state.copyWith(
      movementsStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_warehouses_products_movements_almacen',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final List<dynamic> movementList = json.decode(response.body);
        for (var movementJson in movementList) {
          final movement = Movement.fromJson(movementJson);
          await dbHelper.syncMovementFromServer(movement);
        }
        state = state.copyWith(movementsStatus: SyncStatus.completed);
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar movimientos';
        state = state.copyWith(
          movementsStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        movementsStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  Future<void> _syncInventory(String token, String lastSync) async {
    state = state.copyWith(
      inventoryProductsCountsStatus: SyncStatus.inProgress,
      errorMessage: null,
      clearErrorMessage: true,
    );
    try {
      final url = Uri.parse(
        '${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_inventory',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'last_sync': lastSync}),
      );

      if (response.statusCode == 200) {
        _recordServerSync(_extractServerDate(response.headers));
        final List<dynamic> list = json.decode(response.body);
        for (var itemJson in list) {
          final inventoryCount = InventoryProductsCount.fromJson(itemJson);
          await dbHelper.syncInventoryCountFromServer(inventoryCount);
        }
        state = state.copyWith(
          inventoryProductsCountsStatus: SyncStatus.completed,
        );
      } else {
        final error =
            json.decode(response.body)['error'] ??
            'Error al sincronizar inventario';
        state = state.copyWith(
          inventoryProductsCountsStatus: SyncStatus.error,
          errorMessage: error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        inventoryProductsCountsStatus: SyncStatus.error,
        errorMessage: "Error de red: ${e.toString()}",
      );
    }
  }

  DateTime? _extractServerDate(Map<String, String> headers) {
    final headerValue = headers['date'];
    if (headerValue == null) {
      return null;
    }
    try {
      return parseHttpDate(headerValue);
    } catch (_) {
      return null;
    }
  }

  void _recordServerSync(DateTime? serverUtc) {
    if (serverUtc == null) {
      return;
    }
    final alignedTimestamp = _alignWithServerClock(serverUtc);
    if (_lastServerSync == null || alignedTimestamp.isAfter(_lastServerSync!)) {
      _lastServerSync = alignedTimestamp;
    }
  }

  DateTime _alignWithServerClock(DateTime serverUtc) {
    final localNow = DateTime.now();
    final utcNow = localNow.toUtc();
    final delta = serverUtc.difference(utcNow);
    return localNow.add(delta);
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rpsinventory/src/config/main_config.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/models/m_deductible.dart';
import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';
import 'package:rpsinventory/src/models/m_warehouse_product.dart';

enum SyncStatus { pending, inProgress, completed, error }

// --- ESTADO MODIFICADO ---
// Se añaden estados para controlar la fase de subida de datos.
class SyncState {
  // Estados para la fase de subida
  final SyncStatus uploadStatus;
  final bool isUploading;

  // Estados para la fase de bajada/descarga
  final SyncStatus productsStatus;
  final SyncStatus warehousesStatus;
  final SyncStatus warehousesProductsStatus;
  final SyncStatus conducesStatus;
  final SyncStatus deductiblesStatus;

  final bool isSyncComplete;
  final String? errorMessage;

  SyncState({
    this.uploadStatus = SyncStatus.pending,
    this.isUploading = true, // Inicia en modo subida
    this.productsStatus = SyncStatus.pending,
    this.warehousesStatus = SyncStatus.pending,
    this.warehousesProductsStatus = SyncStatus.pending,
    this.conducesStatus = SyncStatus.pending,
    this.deductiblesStatus = SyncStatus.pending,
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
      isSyncComplete: isSyncComplete ?? this.isSyncComplete,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(SyncState());

  final dbHelper = DBHelper.instance;

  // --- MÉTODO PRINCIPAL MODIFICADO ---
  // Orquesta todo el proceso: primero sube los datos y luego los baja.
  Future<void> startSync(String token, String userId) async {
    // 1. Inicia el proceso, reseteando el estado al modo de subida.
    state = SyncState();

    // 2. Ejecuta la fase de subida de datos.
    await _uploadAllData(token);

    // 3. Si la subida fue exitosa, procede con la fase de bajada.
    if (state.uploadStatus == SyncStatus.completed) {
      state = state.copyWith(isUploading: false); // Cambia de fase
      await _startDownload(token, userId);
    }
  }

  // --- NUEVO MÉTODO PRIVADO PARA LA SUBIDA DE DATOS ---
  Future<void> _uploadAllData(String token) async {
    state = state.copyWith(uploadStatus: SyncStatus.inProgress, errorMessage: null, clearErrorMessage: true);
    try {
      // Obtener datos de SQLite
      final conducesToSync = await dbHelper.getConducesForSync();
      final detailsToSync = await dbHelper.getConduceDetailsForSync();
      final notesToSync = await dbHelper.getConduceNotesForSync();

      // Endpoint 1: Subir Conduces
      if (conducesToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_conduces_carrero',
          token: token,
          body: {'token': token, 'conduces': conducesToSync},
        );
      }

      // Endpoint 2: Subir Detalles de Conduces
      if (detailsToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_conduces_details_carrero',
          token: token,
          body: {'token': token, 'conduces_details': detailsToSync},
        );
      }

      // Endpoint 3: Subir Notas de Conduces
      if (notesToSync.isNotEmpty) {
        await _postData(
          endpoint: 'sync_update_conduces_notes_carrero',
          token: token,
          body: {'token': token, 'conduces_notes': notesToSync},
        );
      }

      // Si todo sale bien, marca la subida como completada.
      state = state.copyWith(uploadStatus: SyncStatus.completed);

    } catch (e) {
      state = state.copyWith(
        uploadStatus: SyncStatus.error,
        errorMessage: "Error en la subida: ${e.toString()}",
      );
    }
  }

  // --- NUEVO MÉTODO HELPER PARA HACER POST ---
  Future<void> _postData({
    required String endpoint,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse('${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body)['error'] ?? 'Error en $endpoint';
      throw Exception(error);
    }
  }

  // --- LÓGICA DE DESCARGA (EXTRAÍDA A SU PROPIO MÉTODO) ---
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

  // Métodos de sincronización de bajada (sin cambios)
  Future<void> _syncProducts(String token) async {
    state = state.copyWith(productsStatus: SyncStatus.inProgress, errorMessage: null, clearErrorMessage: true);
    try {
      final url = Uri.parse('${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_products');
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
        final error = json.decode(response.body)['error'] ?? 'Error al sincronizar productos';
        state = state.copyWith(productsStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          productsStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncWarehouses(String token) async {
    state = state.copyWith(warehousesStatus: SyncStatus.inProgress, errorMessage: null, clearErrorMessage: true);
    try {
      final url = Uri.parse('https://rpsinventory.com/public/api/sync_get_warehouses');
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
        final error = json.decode(response.body)['error'] ?? 'Error al sincronizar bodegas';
        state = state.copyWith(warehousesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          warehousesStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncWarehousesProducts(String token) async {
    state = state.copyWith(
        warehousesProductsStatus: SyncStatus.inProgress, errorMessage: null, clearErrorMessage: true);
    try {
      final url = Uri.parse('https://rpsinventory.com/public/api/sync_get_warehouses_products');
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
        final error = json.decode(response.body)['error'] ?? 'Error al sincronizar inventario de bodegas';
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
    state = state.copyWith(conducesStatus: SyncStatus.inProgress, errorMessage: null, clearErrorMessage: true);
    try {
      final url = Uri.parse('${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_conduces');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token, 'user_id': userId, 'conduces': []}));

      if (response.statusCode == 200) {
        final List<dynamic> conduceList = json.decode(response.body);
        for (var conduceJson in conduceList) {
          await dbHelper.addOrUpdateConduce(Conduce.fromJson(conduceJson));
        }
        state = state.copyWith(conducesStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ?? 'Error al sincronizar conduces';
        state = state.copyWith(conducesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          conducesStatus: SyncStatus.error,
          errorMessage: "Error de red: ${e.toString()}");
    }
  }

  Future<void> _syncDeductibles(String token) async {
    state = state.copyWith(deductiblesStatus: SyncStatus.inProgress, errorMessage: null, clearErrorMessage: true);
    try {
      final url = Uri.parse('${MainConfig.baseApiUrl}${MainConfig.baseApiUrlPath}/sync_get_deductibles');
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token}));

      if (response.statusCode == 200) {
        final List<dynamic> deductibleList = json.decode(response.body);
        for (var deductibleJson in deductibleList) {
          await dbHelper.addOrUpdateDeductible(Deductible.fromMap(deductibleJson));
        }
        state = state.copyWith(deductiblesStatus: SyncStatus.completed);
      } else {
        final error = json.decode(response.body)['error'] ?? 'Error al sincronizar deducibles';
        state = state.copyWith(deductiblesStatus: SyncStatus.error, errorMessage: error);
      }
    } catch (e) {
      state = state.copyWith(
          deductiblesStatus: SyncStatus.error,
          errorMessage: "Error de red al sincronizar deducibles: ${e.toString()}");
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

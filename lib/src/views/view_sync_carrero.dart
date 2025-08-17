import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/models/m_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rpsinventory/src/providers/sync_provider.dart';
import 'package:rpsinventory/src/views/view_conduces.dart';

class ViewSyncCarrero extends ConsumerStatefulWidget {
  const ViewSyncCarrero({super.key});
  static String path = '/syncCarrero';

  @override
  ConsumerState<ViewSyncCarrero> createState() => _ViewSyncCarreroState();
}

class _ViewSyncCarreroState extends ConsumerState<ViewSyncCarrero> {
  @override
  void initState() {
    super.initState();
    _initiateSync();
  }

  Future<void> _initiateSync() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userDataString = prefs.getString('userData');

    if (token != null && userDataString != null) {
      final userData = User.fromJson(json.decode(userDataString));
      final userId = userData.id;

      if (userId != null) {
        // Llama al método principal que orquesta subida y bajada.
        Future.microtask(
                () => ref.read(syncProvider.notifier).startSync(token, userId.toString()));
      } else {
        // Manejar error: no se encontró el ID del usuario
        // Aquí podrías, por ejemplo, navegar a la pantalla de login.
      }
    } else {
      // Manejar error: no se encontró el token o los datos del usuario
      // Aquí también podrías navegar a la pantalla de login.
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    const primaryColor = Color(0xff0088CC);

    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.isSyncComplete) {
        // Navega a la siguiente pantalla cuando toda la sincronización (subida y bajada) ha terminado.
        Navigator.of(context).pushReplacementNamed(ViewConduces.path);
      }
    });

    final appBarTitle = syncState.isUploading
        ? 'Subiendo Datos'
        : 'Recibiendo Datos';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Elige qué widget mostrar basado en la fase de sincronización
          child: syncState.isUploading
              ? _buildUploadingView(syncState)
              : _buildDownloadingView(syncState),
        ),
      ),
      bottomNavigationBar: syncState.isSyncComplete
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context)
                .pushReplacementNamed(ViewConduces.path);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: const Text('Continuar'),
        ),
      )
          : null,
    );
  }

  // --- WIDGET PARA LA VISTA DE SUBIDA DE DATOS ---
  Widget _buildUploadingView(SyncState syncState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Preparando tus datos locales para enviarlos a la nube. Por favor, espere.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        _buildSyncItem(
          label: 'Actualizando datos en la nube',
          status: syncState.uploadStatus,
        ),
        if (syncState.errorMessage != null && syncState.uploadStatus == SyncStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Error: ${syncState.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // --- WIDGET PARA LA VISTA DE BAJADA DE DATOS ---
  Widget _buildDownloadingView(SyncState syncState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Actualizando datos en dispositivo. Por favor, espere.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 40),
        _buildSyncItem(
          label: 'Sincronizando Productos',
          status: syncState.productsStatus,
        ),
        const SizedBox(height: 24),
        _buildSyncItem(
          label: 'Sincronizando Bodegas',
          status: syncState.warehousesStatus,
        ),
        const SizedBox(height: 24),
        _buildSyncItem(
          label: 'Sincronizando Inventario',
          status: syncState.warehousesProductsStatus,
        ),
        const SizedBox(height: 24),
        _buildSyncItem(
          label: 'Sincronizando Conduces',
          status: syncState.conducesStatus,
        ),
        const SizedBox(height: 24),
        _buildSyncItem(
          label: 'Sincronizando Deducibles',
          status: syncState.deductiblesStatus,
        ),
        if (syncState.errorMessage != null && !syncState.isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Error: ${syncState.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSyncItem({required String label, required SyncStatus status}) {
    return ListTile(
      leading: _buildStatusIcon(status),
      title: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    const primaryColor = Color(0xff0088CC);
    switch (status) {
      case SyncStatus.inProgress:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      case SyncStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 30);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 30);
      case SyncStatus.pending:
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.grey, size: 30);
    }
  }
}

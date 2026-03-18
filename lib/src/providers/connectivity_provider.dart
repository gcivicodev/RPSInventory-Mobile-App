import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que expone un stream con los cambios en el estado de la conectividad.
///
/// Permite que la UI reaccione y se actualice automáticamente cuando el estado
/// de la conexión a internet cambia (ej: de WiFi a datos móviles o a sin conexión).
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  // Retorna el stream que emite un nuevo estado cada vez que la conectividad cambia.
  return Connectivity().onConnectivityChanged;
});

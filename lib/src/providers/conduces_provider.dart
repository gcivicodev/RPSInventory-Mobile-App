import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';

/// Provider para obtener la lista de conduces desde la base de datos local.
///
/// Utiliza un [FutureProvider] para cargar de forma asíncrona los datos
/// y gestionar los estados de carga, datos y error.
final conducesProvider = FutureProvider.autoDispose<List<Conduce>>((ref) async {
  // Retorna la lista de conduces obtenida a través de DBHelper.
  return DBHelper.instance.getConduces();
});

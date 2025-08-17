import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';

/// Provider para obtener la instancia de DBHelper.
final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper.instance);

/// Provider que obtiene la lista de todas las bodegas.
///
/// Este provider es auto-dispose, lo que significa que su estado se destruirá
/// cuando ya no se esté utilizando, liberando memoria.
final warehousesProvider = FutureProvider.autoDispose<List<Warehouse>>((ref) async {
  final dbHelper = ref.watch(dbHelperProvider);
  return await dbHelper.getWarehouses();
});

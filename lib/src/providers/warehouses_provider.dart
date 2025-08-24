import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';

final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper.instance);

final warehousesProvider = FutureProvider.autoDispose<List<Warehouse>>((ref) async {
  final dbHelper = ref.watch(dbHelperProvider);
  return await dbHelper.getWarehouses();
});

final movementWarehousesProvider = FutureProvider.autoDispose<List<Warehouse>>((ref) async {
  final dbHelper = ref.watch(dbHelperProvider);
  return await dbHelper.getWarehouses(type: 'warehouse');
});

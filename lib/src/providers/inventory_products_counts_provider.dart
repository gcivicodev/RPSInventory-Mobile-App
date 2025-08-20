import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';

final inventoryProductsCountsProvider = FutureProvider<List<InventoryProductsCount>>((ref) async {
  final dbHelper = DBHelper.instance;
  return await dbHelper.getInventoryProductsCounts();
});

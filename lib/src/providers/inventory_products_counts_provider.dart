import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final inventoryProductsCountsProvider =
    FutureProvider<List<InventoryProductsCount>>((ref) async {
  final dbHelper = DBHelper.instance;
  final searchTerm = ref.watch(inventorySearchQueryProvider);
  return await dbHelper.getInventoryProductsCounts(searchTerm: searchTerm);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_inventory_products_counts.dart';

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

class InventoryDateRange {
  const InventoryDateRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

final inventoryDateRangeProvider =
    StateProvider<InventoryDateRange>((ref) => const InventoryDateRange());

final inventoryProductsCountsProvider =
    FutureProvider<List<InventoryProductsCount>>((ref) async {
  final dbHelper = DBHelper.instance;
  final searchTerm = ref.watch(inventorySearchQueryProvider);
  final dateRange = ref.watch(inventoryDateRangeProvider);
  return await dbHelper.getInventoryProductsCounts(
    searchTerm: searchTerm,
    fromDate: dateRange.from,
    toDate: dateRange.to,
  );
});

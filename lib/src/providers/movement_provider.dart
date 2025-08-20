import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_movement_detail.dart';

class MovementNotifier extends StateNotifier<AsyncValue<void>> {
  MovementNotifier() : super(const AsyncValue.data(null));

  Future<void> addMovement({
    required int originWarehouseId,
    required int destinationWarehouseId,
    required int productId,
    required double quantity,
    int? userId,
    String? username,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dbHelper = DBHelper.instance;
      await dbHelper.addMovement(
        originWarehouseId: originWarehouseId,
        destinationWarehouseId: destinationWarehouseId,
        productId: productId,
        quantity: quantity,
        userId: userId,
        username: username,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final movementProvider =
StateNotifierProvider<MovementNotifier, AsyncValue<void>>((ref) {
  return MovementNotifier();
});

final movementSearchQueryProvider = StateProvider<String>((ref) => '');

final movementsProvider = FutureProvider<List<MovementDetail>>((ref) async {
  final dbHelper = DBHelper.instance;
  final searchTerm = ref.watch(movementSearchQueryProvider);
  return dbHelper.getMovements(searchTerm: searchTerm);
});

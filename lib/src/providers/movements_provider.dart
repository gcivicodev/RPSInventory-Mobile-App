import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_movement_detail.dart';

final movementSearchQueryProvider = StateProvider<String>((ref) => '');

final movementsProvider = FutureProvider<List<MovementDetail>>((ref) async {
  final dbHelper = DBHelper.instance;
  final searchTerm = ref.watch(movementSearchQueryProvider);
  return await dbHelper.getMovements(searchTerm: searchTerm);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_movement_detail.dart';

final movementsProvider = FutureProvider<List<MovementDetail>>((ref) async {
  final dbHelper = DBHelper.instance;
  return await dbHelper.getMovements();
});

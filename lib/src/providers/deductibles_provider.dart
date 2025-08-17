import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_deductible.dart';


final dbHelperProvider = Provider<DBHelper>((ref) {
  return DBHelper.instance;
});

final getDeductiblesProvider = FutureProvider<List<Deductible>>((ref) async {
  final dbHelper = ref.watch(dbHelperProvider);
  return dbHelper.getDeductibles();
});

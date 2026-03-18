import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';

final getConduceProvider =
FutureProvider.autoDispose.family<Conduce, int>((ref, conduceId) async {
  return DBHelper.instance.getConduce(conduceId);
});

final updateConduceStatusProvider =
FutureProvider.autoDispose.family<void, int>((ref, conduceId) async {
  return DBHelper.instance.updateConduceStatus(conduceId);
});

final checkIfConduceDetailsWereAssignedProvider =
FutureProvider.autoDispose.family<bool, int>((ref, conduceId) async {
  return DBHelper.instance.checkIfConduceDetailsWereAssigned(conduceId);
});

final updateConduceProvider =
FutureProvider.autoDispose.family<void, Conduce>((ref, conduce) async {
  return DBHelper.instance.addOrUpdateConduce(conduce);
});

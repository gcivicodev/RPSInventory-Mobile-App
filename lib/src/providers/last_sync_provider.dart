import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';

typedef LastSyncUpdater = Future<void> Function(DateTime dateTime);

final lastSyncUpdaterProvider = Provider<LastSyncUpdater>((ref) {
  final dbHelper = DBHelper.instance;
  return (DateTime dateTime) => dbHelper.updateLastSyncDate(dateTime);
});

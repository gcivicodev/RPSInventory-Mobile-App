import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';

/// Modelo para los filtros de conduces.
class ConduceFilter {
  final DateTime fromDate;
  final DateTime toDate;
  final String status;

  ConduceFilter({
    required this.fromDate,
    required this.toDate,
    required this.status,
  });

  ConduceFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) {
    return ConduceFilter(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
    );
  }
}

/// Provider para el estado del filtro de conduces.
final conduceFilterProvider = StateProvider<ConduceFilter>((ref) {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  return ConduceFilter(
    fromDate: yesterday,
    toDate: now,
    status: 'Todos',
  );
});

/// Provider para obtener la lista de conduces filtrada desde la base de datos local.
final conducesProvider = FutureProvider.autoDispose<List<Conduce>>((ref) async {
  final filter = ref.watch(conduceFilterProvider);
  // Retorna la lista de conduces filtrada obtenida a través de DBHelper.
  return DBHelper.instance.getConduces(
    fromDate: filter.fromDate,
    toDate: filter.toDate,
    status: filter.status,
  );
});

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/providers/auth_provider.dart';
import 'package:rpsinventory/src/providers/conduces_provider.dart';
import 'package:rpsinventory/src/providers/connectivity_provider.dart';
import 'package:rpsinventory/src/views/view_conduce_detail.dart';
import 'package:rpsinventory/src/views/view_login.dart';
import 'package:rpsinventory/src/views/view_sync_carrero.dart';

class ViewConduces extends ConsumerWidget {
  const ViewConduces({super.key});
  static String path = '/conduces';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conducesAsync = ref.watch(conducesProvider);
    final connectivity = ref.watch(connectivityStreamProvider);
    const primaryColor = Color(0xff0088CC);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Conduces',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await Navigator.pushNamed(context, ViewSyncCarrero.path);
              ref.invalidate(conducesProvider);
            },
            tooltip: 'Sincronizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              // ignore: use_build_context_synchronously
              Navigator.pushNamedAndRemoveUntil(
                  context, ViewLogin.path, (route) => false);
            },
            tooltip: 'Cerrar sesión',
          ),
          connectivity.when(
            data: (result) {
              final hasConnection = result.contains(ConnectivityResult.mobile) ||
                  result.contains(ConnectivityResult.wifi) ||
                  result.contains(ConnectivityResult.ethernet);
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  hasConnection ? Icons.wifi : Icons.wifi_off,
                  color: hasConnection ? Colors.green : Colors.white38,
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
            error: (err, stack) => const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(Icons.error_outline, color: Colors.redAccent),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, ref),
          Expanded(
            child: conducesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error al cargar conduces: $err')),
              data: (conduces) {
                if (conduces.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay conduces para mostrar.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                // Agrupamiento de conduces
                final pendiente = conduces
                    .where((c) => (c.status ?? 'Pendiente') == 'Pendiente')
                    .toList();
                final actualizado =
                    conduces.where((c) => c.status == 'Actualizado').toList();
                final completado =
                    conduces.where((c) => c.status == 'Completado').toList();

                // Otros estados si los hubiera
                final otros = conduces
                    .where((c) =>
                        c.status != 'Pendiente' &&
                        c.status != 'Actualizado' &&
                        c.status != 'Completado' &&
                        c.status != null)
                    .toList();

                // Función de ordenamiento por fecha ASC
                void sortAsc(List<Conduce> list) {
                  list.sort((a, b) {
                    final aDate = a.serviceDate;
                    final bDate = b.serviceDate;
                    if (aDate == null && bDate == null) return 0;
                    if (aDate == null) return 1;
                    if (bDate == null) return -1;
                    return aDate.compareTo(bDate);
                  });
                }

                sortAsc(pendiente);
                sortAsc(actualizado);
                sortAsc(completado);
                sortAsc(otros);

                final List<Widget> listItems = [];

                if (pendiente.isNotEmpty) {
                  listItems.add(_buildSectionHeader(
                      'Conduces Pendiente', Colors.red.shade700,
                      isFirst: listItems.isEmpty));
                  listItems.addAll(pendiente.map(
                      (c) => _buildConduceCard(context, ref, c, primaryColor)));
                }

                if (actualizado.isNotEmpty) {
                  listItems.add(_buildSectionHeader(
                      'Conduces Actualizado', Colors.orange.shade800,
                      isFirst: listItems.isEmpty));
                  listItems.addAll(actualizado.map(
                      (c) => _buildConduceCard(context, ref, c, primaryColor)));
                }

                if (completado.isNotEmpty) {
                  listItems.add(_buildSectionHeader(
                      'Conduces Completado', Colors.green.shade700,
                      isFirst: listItems.isEmpty));
                  listItems.addAll(completado.map(
                      (c) => _buildConduceCard(context, ref, c, primaryColor)));
                }

                if (otros.isNotEmpty) {
                  listItems.add(_buildSectionHeader(
                      'Otros Estados', Colors.blueGrey,
                      isFirst: listItems.isEmpty));
                  listItems.addAll(otros.map(
                      (c) => _buildConduceCard(context, ref, c, primaryColor)));
                }

                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  children: listItems,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(conduceFilterProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filter.fromDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: const Locale('es', 'ES'),
                    );
                    if (picked != null) {
                      ref.read(conduceFilterProvider.notifier).state =
                          filter.copyWith(fromDate: picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Desde: ${dateFormat.format(filter.fromDate)}',
                      style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filter.toDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: const Locale('es', 'ES'),
                    );
                    if (picked != null) {
                      ref.read(conduceFilterProvider.notifier).state =
                          filter.copyWith(toDate: picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Hasta: ${dateFormat.format(filter.toDate)}',
                      style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'Todos',
                'Pendiente',
                'Actualizado',
                'Completado'
              ].map((status) {
                final isSelected = filter.status == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(conduceFilterProvider.notifier).state =
                            filter.copyWith(status: status);
                      }
                    },
                    selectedColor: const Color(0xff0088CC).withOpacity(0.2),
                    checkmarkColor: const Color(0xff0088CC),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? const Color(0xff0088CC) : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, {bool isFirst = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, isFirst ? 4 : 50, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: color.withOpacity(0.3), thickness: 1),
        ],
      ),
    );
  }

  Widget _buildConduceCard(BuildContext context, WidgetRef ref, Conduce conduce, Color primaryColor) {
    final statusColor = (conduce.status?.toLowerCase() == 'completado' ||
            conduce.status?.toLowerCase() == 'actualizado')
        ? Colors.green.shade700
        : Colors.red.shade700;

    String formattedDate = 'Fecha no disponible';
    if (conduce.serviceDate != null) {
      formattedDate = DateFormat.yMMMMd('es_ES').format(conduce.serviceDate!);
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        conduce.patientName ?? 'Nombre no disponible',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        conduce.status ?? 'N/A',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const Divider(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conduce.patientAddress ?? 'Dirección no disponible',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conduce.patientPhone ?? 'Teléfono no disponible',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          conduce.patientPlanName ?? 'Plan no disponible',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Asegurado: ${conduce.patientPlanNumber ?? 'N/A'}',
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewConduceDetail(conduceId: conduce.id),
                  ),
                );
                ref.invalidate(conducesProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Trabajar Conduce'),
            ),
          ),
        ],
      ),
    );
  }
}

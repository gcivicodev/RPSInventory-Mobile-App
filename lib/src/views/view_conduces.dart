import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/providers/conduces_provider.dart';
import 'package:rpsinventory/src/providers/connectivity_provider.dart';
import 'package:rpsinventory/src/views/view_conduce_detail.dart';
import 'package:rpsinventory/src/views/view_sync_carrero.dart';

class ViewConduces extends ConsumerWidget {
  const ViewConduces({super.key});
  static String path = '/conduces';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa el estado de los providers.
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
          // Botón para sincronizar
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await Navigator.pushNamed(context, ViewSyncCarrero.path);
              ref.invalidate(conducesProvider);
            },
            tooltip: 'Sincronizar',
          ),
          // Indicador de estado de conexión
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
      body: conducesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar conduces: $err')),
        data: (conduces) {
          if (conduces.isEmpty) {
            return const Center(
              child: Text(
                'No hay conduces para mostrar.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: conduces.length,
            itemBuilder: (context, index) {
              final conduce = conduces[index];
              // **MODIFICADO**: Se pasa `ref` al método que construye la tarjeta.
              return _buildConduceCard(context, ref, conduce, primaryColor);
            },
          );
        },
      ),
    );
  }

  /// **MODIFICADO**: Acepta `ref` para poder invalidar el provider después de la navegación.
  Widget _buildConduceCard(BuildContext context, WidgetRef ref, Conduce conduce, Color primaryColor) {
    final statusColor = (conduce.status?.toLowerCase() == 'completado')
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
              // **MODIFICADO**: Se convierte en `async` para esperar el resultado de la navegación.
              onPressed: () async {
                // Espera a que la pantalla de detalle se cierre.
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewConduceDetail(conduceId: conduce.id),
                  ),
                );
                // Una vez que se regresa, invalida el provider para refrescar la lista.
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

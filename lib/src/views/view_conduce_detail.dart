import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/models/m_conduce_detail.dart';
import 'package:rpsinventory/src/providers/conduce_provider.dart';
import 'package:rpsinventory/src/views/view_update_conduce.dart';
import 'package:rpsinventory/src/views/view_update_conduce_detail.dart';
import 'package:rpsinventory/src/views/view_update_note.dart';


class ViewConduceDetail extends ConsumerStatefulWidget {
  static String path = '/conduce';
  final int conduceId;
  final bool showSuccessSnackbar;

  const ViewConduceDetail({
    super.key,
    required this.conduceId,
    this.showSuccessSnackbar = false,
  });

  @override
  ConsumerState<ViewConduceDetail> createState() => _ViewConduceDetailState();
}

class _ViewConduceDetailState extends ConsumerState<ViewConduceDetail> {
  @override
  void initState() {
    super.initState();


    if (widget.showSuccessSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conduce actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  void _showMissingProductsSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Faltan productos por asignar.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conduceAsync = ref.watch(getConduceProvider(widget.conduceId));
    const primaryColor = Color(0xff0088CC);

    return conduceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del Conduce'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Error: $err')),
      ),
      data: (conduceData) {
        final bool hasDetails = conduceData.details.isNotEmpty;
        final bool allProductsAssigned = hasDetails && conduceData.details.every((detail) => detail.productId != null);
        final bool canUpdate = conduceData.status?.toLowerCase() == 'pendiente' && allProductsAssigned;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Detalle del Conduce',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            actions: [
              if (canUpdate)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: TextButton(
                    onPressed: () {
                      ref.invalidate(getConduceProvider(widget.conduceId));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewUpdateConduce(
                            conduceId: widget.conduceId,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Actualizar conduce',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGeneralInfoCard(context, ref, conduceData),
                const SizedBox(height: 24),
                _buildPatientInfoCard(context, conduceData),
                const SizedBox(height: 24),
                _buildProductsCard(
                    context, ref, widget.conduceId, conduceData.details, conduceData.status?.toLowerCase() == 'pendiente'),
                const SizedBox(height: 24),
                _buildNotesCard(context, ref, conduceData, conduceData.status?.toLowerCase() == 'pendiente'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralInfoCard(
      BuildContext context, WidgetRef ref, Conduce conduceData) {
    String formattedDate = 'No disponible';
    if (conduceData.createdAt != null) {
      formattedDate = DateFormat.yMMMMd('es_ES').format(conduceData.createdAt!);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información general',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: const [
                DataColumn(
                    label: Text('No.',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('PO Number',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Tipo',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Estado',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Fecha',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text(conduceData.id.toString())),
                  DataCell(Text(conduceData.poNumber ?? 'N/A')),
                  DataCell(Text(conduceData.serviceType ?? 'N/A')),
                  DataCell(_buildStatusChip(conduceData.status)),
                  DataCell(Text(formattedDate)),
                ]),
              ],
              columnSpacing: 16,
              horizontalMargin: 16,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(BuildContext context, Conduce conduceData) {
    String formattedDob = 'No disponible';
    if (conduceData.patientDob != null) {
      formattedDob = DateFormat.yMMMMd('es_ES').format(conduceData.patientDob!);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Información del paciente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2.5),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(3.5),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('ID Paciente'),
                    _buildTableHeader('No. Contrato'),
                    _buildTableHeader('Paciente'),
                    _buildTableHeader('Teléfono'),
                    _buildTableHeader('Dirección'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell(conduceData.recordNumber ?? 'N/A'),
                    _buildTableCell(conduceData.patientPlanNumber ?? 'N/A'),
                    _buildTableCell(conduceData.patientName ?? 'N/A'),
                    _buildTableCell(conduceData.patientPhone ?? 'N/A'),
                    _buildTableCell(conduceData.patientAddress ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Table(
              columnWidths: const <int, TableColumnWidth>{
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(),
                4: FlexColumnWidth(),
                5: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('Ciudad'),
                    _buildTableHeader('Estado'),
                    _buildTableHeader('Nacimiento'),
                    _buildTableHeader('Sexo'),
                    _buildTableHeader('Peso'),
                    _buildTableHeader('Altura'),
                  ],
                ),
                TableRow(
                  children: [
                    _buildTableCell(conduceData.physicalCity ?? 'N/A'),
                    _buildTableCell(conduceData.physicalState ?? 'N/A'),
                    _buildTableCell(formattedDob),
                    _buildTableCell(conduceData.patientSex ?? 'N/A'),
                    _buildTableCell(
                        conduceData.patientWeight?.toString() ?? 'N/A'),
                    _buildTableCell(
                        conduceData.patientHeight?.toString() ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(BuildContext context, WidgetRef ref, int conduceId,
      List<ConduceDetail> details, bool canUpdate) {
    final double totalQuantity =
    details.fold(0.0, (sum, item) => sum + (item.productQuantity ?? 0));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Productos (${totalQuantity.toStringAsFixed(0)})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          if (details.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay productos en este conduce.')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: details.length,
              itemBuilder: (context, index) {
                return _buildProductItem(
                    context, ref, conduceId, details[index], canUpdate);
              },
              separatorBuilder: (context, index) {
                return const Column(
                  children: [
                    SizedBox(height: 16.0),
                    Divider(
                        height: 1, thickness: 1, indent: 16, endIndent: 16),
                    SizedBox(height: 16.0),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      BuildContext context, WidgetRef ref, int conduceId, ConduceDetail detail, bool canUpdate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Código:', detail.productHcpcCode ?? 'N/A'),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                        'Producto:',
                        detail.productName ??
                            detail.productHcpcShortDescription ??
                            'N/A'),
                    const SizedBox(height: 4),
                    _buildDetailRow('Tag:', detail.tagNumber ?? 'N/A'),
                  ],
                ),
              ),
              if (canUpdate)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewUpdateConduceDetail(
                          conduceDetail: detail,
                        ),
                      ),
                    );
                  },
                  child: const Text('Asignar producto'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
              6: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Número'),
                  _buildTableHeader('Tamaño'),
                  _buildTableHeader('Modelo'),
                  _buildTableHeader('Color'),
                  _buildTableHeader('Cantidad'),
                  _buildTableHeader('Deducibles'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell(detail.productSku ?? 'N/A'),
                  _buildTableCell(detail.productSize ?? 'N/A'),
                  _buildTableCell(detail.productModel ?? 'N/A'),
                  _buildTableCell(detail.productColor ?? 'N/A'),
                  _buildTableCell(detail.productQuantity?.toString() ?? 'N/A'),
                  _buildTableCell(detail.productDeductible ?? 'N/A'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(
      BuildContext context, WidgetRef ref, Conduce conduceData, bool canUpdate) {
    final int currentUserId = conduceData.userId ?? -1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notas (${conduceData.notes.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canUpdate)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewUpdateNote(
                            conduceId: conduceData.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          if (conduceData.notes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay notas en este conduce.')),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                columnWidths: const <int, TableColumnWidth>{
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(4),
                  3: FlexColumnWidth(2.5),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    children: [
                      _buildTableHeader('No.'),
                      _buildTableHeader('Creador'),
                      _buildTableHeader('Nota'),
                      _buildTableHeader('Fecha'),
                      _buildTableHeader(''),
                    ],
                  ),
                  ...conduceData.notes.map((note) {
                    String formattedDate = 'N/A';
                    if (note.updatedAt != null) {
                      formattedDate = DateFormat(
                          "d 'de' MMMM 'de' yyyy\nh:mm a", 'es_ES')
                          .format(note.updatedAt!);
                    }

                    final canEdit = note.userId == currentUserId;

                    return TableRow(
                      children: [
                        _buildTableCell(note.id.toString()),
                        _buildTableCell(note.username ?? 'N/A'),
                        _buildTableCell(note.note ?? ''),
                        _buildTableCell(formattedDate),
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: canEdit && canUpdate
                              ? TextButton(
                            child: const Text('Actualizar'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewUpdateNote(
                                    conduceId: conduceData.id,
                                    conduceNoteId: note.id,
                                  ),
                                ),
                              );
                            },
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text, textAlign: TextAlign.start),
    );
  }

  Widget _buildStatusChip(String? status) {
    final statusText = status ?? 'N/A';
    final statusColor = (statusText.toLowerCase() == 'completado')
        ? Colors.green.shade700
        : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rpsinventory/src/models/m_conduce.dart';
import 'package:rpsinventory/src/models/m_conduce_detail.dart';
import 'package:rpsinventory/src/providers/conduce_provider.dart';
import 'package:rpsinventory/src/providers/conduces_provider.dart';
import 'package:rpsinventory/src/views/view_conduces.dart';
import 'package:signature/signature.dart';

class ViewUpdateConduce extends ConsumerStatefulWidget {
  final int conduceId;
  const ViewUpdateConduce({super.key, required this.conduceId});
  static String path = '/updateConduce';

  @override
  ConsumerState<ViewUpdateConduce> createState() => _ViewUpdateConduceState();
}

class _ViewUpdateConduceState extends ConsumerState<ViewUpdateConduce> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _patientWeightController;
  late TextEditingController _patientHeightController;
  late TextEditingController _paymentAmountController;
  late TextEditingController _patientNoSignatureReasonController;
  late TextEditingController _otherPersonSignatureRelationshipController;

  String? _patientSex;
  int? _insulin;
  String? _paymentAmountType;
  String? _payMethod;

  bool _guaranteeCommitment = false;
  bool _certificationOfInstructions = false;

  final SignatureController _patientSignatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );
  final SignatureController _employSignatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );

  bool _isFormInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _patientWeightController = TextEditingController();
    _patientHeightController = TextEditingController();
    _paymentAmountController = TextEditingController();
    _patientNoSignatureReasonController = TextEditingController();
    _otherPersonSignatureRelationshipController = TextEditingController();

    _patientNoSignatureReasonController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _patientWeightController.dispose();
    _patientHeightController.dispose();
    _paymentAmountController.dispose();
    _patientNoSignatureReasonController.dispose();
    _otherPersonSignatureRelationshipController.dispose();
    _patientSignatureController.dispose();
    _employSignatureController.dispose();
    super.dispose();
  }

  void _initializeForm(Conduce conduce) {
    _patientWeightController.text = conduce.patientWeight?.toString() ?? '';
    _patientHeightController.text = conduce.patientHeight?.toString() ?? '';
    _paymentAmountController.text = conduce.paymentAmount ?? '';
    _patientNoSignatureReasonController.text =
        conduce.patientNoSignatureReason ?? '';
    _otherPersonSignatureRelationshipController.text =
        conduce.otherPersonSignatureRelationship ?? '';

    _patientSex = conduce.patientSex;
    _insulin = conduce.insulin;
    _paymentAmountType = conduce.paymentAmountType;
    _payMethod = conduce.payMethod;

    _guaranteeCommitment = conduce.guaranteeCommitment == 1;
    _certificationOfInstructions = conduce.certificationOfInstructions == 1;
  }

  Future<void> _submitForm() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (_patientNoSignatureReasonController.text.trim().isNotEmpty &&
        _otherPersonSignatureRelationshipController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debe proporcionar la relación con el paciente.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!_guaranteeCommitment) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debe aceptar el Compromiso de Garantía.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!_certificationOfInstructions) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debe certificar la entrega de instrucciones.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_patientSignatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La firma del paciente o representante es requerida.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_employSignatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La firma del empleado es requerida.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      if (_patientNoSignatureReasonController.text.trim().isEmpty) {
        _otherPersonSignatureRelationshipController.clear();
      }

      try {
        final originalConduce =
        await ref.read(getConduceProvider(widget.conduceId).future);

        Uint8List? patientSignatureBytes =
        await _patientSignatureController.toPngBytes();
        String? patientSignatureBase64 = patientSignatureBytes != null
            ? base64Encode(patientSignatureBytes)
            : null;

        Uint8List? employeeSignatureBytes =
        await _employSignatureController.toPngBytes();
        String? employeeSignatureBase64 = employeeSignatureBytes != null
            ? base64Encode(employeeSignatureBytes)
            : null;

        final updatedConduce = originalConduce.copyWith(
          patientWeight: double.tryParse(_patientWeightController.text),
          patientHeight: double.tryParse(_patientHeightController.text),
          paymentAmount: _paymentAmountController.text,
          patientNoSignatureReason: _patientNoSignatureReasonController.text,
          otherPersonSignatureRelationship:
          _otherPersonSignatureRelationshipController.text,
          patientSex: _patientSex,
          insulin: _insulin,
          paymentAmountType: _paymentAmountType,
          payMethod: _payMethod,
          guaranteeCommitment: _guaranteeCommitment ? 1 : 0,
          certificationOfInstructions: _certificationOfInstructions ? 1 : 0,
          status: 'Completado',
          patientSignature: patientSignatureBase64,
          employeeSignature: employeeSignatureBase64,
          patientSignatureDatetime:
          patientSignatureBase64 != null ? DateTime.now() : null,
          employeeSignatureDatetime:
          employeeSignatureBase64 != null ? DateTime.now() : null,
          updatedAt: DateTime.now(),
        );

        await ref.read(updateConduceProvider(updatedConduce).future);

        ref.invalidate(conducesProvider);

        ref.invalidate(getConduceProvider(widget.conduceId));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ViewConduces()),
                (Route<dynamic> route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conduce actualizado.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conduceAsync = ref.watch(getConduceProvider(widget.conduceId));
    const primaryColor = Color(0xff0088CC);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Actualizar Conduce',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white))),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: const Text(
                'Guardar Cambios',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: conduceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (conduceData) {
          if (!_isFormInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _initializeForm(conduceData);
                setState(() {
                  _isFormInitialized = true;
                });
              }
            });
          }

          return AbsorbPointer(
            absorbing: _isSaving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildReadOnlyInfoCard(conduceData),
                    const SizedBox(height: 24),
                    _buildEditableInfoCard(),
                    const SizedBox(height: 24),
                    _buildProductsCard(context, conduceData.details),
                    const SizedBox(height: 24),
                    _buildSignatureCard(
                        'Firma de Paciente/Representante', _patientSignatureController,
                        isRequired: false),
                    const SizedBox(height: 24),
                    _buildSignatureCard(
                        'Firma de Empleado', _employSignatureController,
                        isRequired: true),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyInfoCard(Conduce conduce) {
    String formattedDob = 'No disponible';
    if (conduce.patientDob != null) {
      formattedDob = DateFormat.yMMMMd('es_ES').format(conduce.patientDob!);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información del Paciente',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            _buildReadOnlyField('Paciente', conduce.patientName),
            _buildReadOnlyField('Plan médico', conduce.patientPlanName),
            _buildReadOnlyField(
                'Número de asegurado', conduce.patientPlanNumber),
            _buildReadOnlyField('Dirección', conduce.patientAddress),
            _buildReadOnlyField('Teléfono', conduce.patientPhone),
            _buildReadOnlyField('Nacimiento', formattedDob),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value ?? 'N/A',
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildEditableInfoCard() {
    bool isReasonProvided =
        _patientNoSignatureReasonController.text.trim().isNotEmpty;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles Adicionales',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    label: 'Sexo',
                    value: _patientSex,
                    items: const [
                      DropdownMenuItem(
                          value: null, child: Text('Seleccionar...')),
                      DropdownMenuItem(value: 'M', child: Text('Masculino')),
                      DropdownMenuItem(value: 'F', child: Text('Femenino')),
                    ],
                    onChanged: (val) => setState(() => _patientSex = val),
                    validator: (value) =>
                    (value == null) ? 'Campo requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Insulina',
                    value: _insulin,
                    items: const [
                      DropdownMenuItem(
                          value: null, child: Text('Seleccionar...')),
                      DropdownMenuItem(value: 0, child: Text('No')),
                      DropdownMenuItem(value: 1, child: Text('Sí')),
                    ],
                    onChanged: (val) => setState(() => _insulin = val),
                    validator: (value) =>
                    value == null ? 'Campo requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(_patientWeightController, 'Peso (Lbs)',
                        required: false)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField(
                        _patientHeightController, 'Altura (Pulg.)',
                        required: false)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Método de pago',
              value: _payMethod,
              items: const [
                DropdownMenuItem(value: null, child: Text('Seleccionar...')),
                DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Giro', child: Text('Giro')),
                DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
              ],
              onChanged: (val) => setState(() => _payMethod = val),
              validator: (value) =>
              (value == null) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Forma de pago',
              value: _paymentAmountType,
              items: const [
                DropdownMenuItem(value: null, child: Text('Seleccionar...')),
                DropdownMenuItem(
                    value: 'Pago Total', child: Text('Pago Total')),
                DropdownMenuItem(
                    value: 'Pago Parcial', child: Text('Pago Parcial')),
                DropdownMenuItem(value: 'No Pagado', child: Text('No Pagado')),
              ],
              onChanged: (val) => setState(() => _paymentAmountType = val),
              validator: (value) =>
              (value == null) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _paymentAmountController,
              'Cantidad Pagada',
              required: false,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_patientNoSignatureReasonController,
                'Razón por la cual Paciente no pudo firmar',
                required: false),
            const SizedBox(height: 16),
            if (isReasonProvided)
              _buildTextField(
                _otherPersonSignatureRelationshipController,
                'Relación con el paciente',
                validator: (value) {
                  if (isReasonProvided && (value == null || value.isEmpty)) {
                    return 'Campo requerido si hay una razón';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            _buildCheckboxField(
              title: 'Compromiso de Garantía',
              subtitle:
              'Hago constar que al firmar éste Conduce de entrega he leído y comprendido en su totalidad la garantía entregada por el personal de RPS Medical Service y estoy de acuerdo con lo que en ella se estipula.',
              value: _guaranteeCommitment,
              onChanged: (newValue) {
                setState(() {
                  _guaranteeCommitment = newValue ?? false;
                });
              },
              isRequired: true,
            ),
            const SizedBox(height: 8),
            _buildCheckboxField(
              title: 'Certificación de entrega de instrucciones',
              subtitle:
              'Certifico que he recibido y he comprendido el uso y cuidado del producto entregado durante el día de hoy.',
              value: _certificationOfInstructions,
              onChanged: (newValue) {
                setState(() {
                  _certificationOfInstructions = newValue ?? false;
                });
              },
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(
      BuildContext context, List<ConduceDetail> details) {
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
                return _buildProductItem(context, details[index]);
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

  Widget _buildProductItem(BuildContext context, ConduceDetail detail) {
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
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('SKU'),
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

  Widget _buildCheckboxField({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CheckboxListTile(
          title: RichText(
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: title),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: Text(subtitle),
          ),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xff0088CC),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = true,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ??
              (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Campo requerido';
            }
            return null;
          },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String? Function(T?) validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSignatureCard(String title, SignatureController controller,
      {required bool isRequired}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    if (isRequired)
                      const Text(' *',
                          style: TextStyle(color: Colors.red, fontSize: 20)),
                  ],
                ),
                TextButton(
                  onPressed: () => controller.clear(),
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            height: 200,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Signature(
              controller: controller,
              backgroundColor: Colors.transparent,
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
}

import 'dart:convert';
import 'm_conduce_detail.dart';
import 'm_conduce_note.dart';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<Conduce> conducesFromJson(String str) =>
    List<Conduce>.from(json.decode(str).map((x) => Conduce.fromJson(x)));
String conduceToJson(Conduce data) => json.encode(data.toMap());

class Conduce {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? completedAt;
  final DateTime? serviceDate;
  final String? poNumber;
  final int? userId;
  final String? serviceType;
  final String? recordNumber;
  final String? patientName;
  final String? patientPlanNumber;
  final int? patientPlan;
  final String? patientPlanName;
  final String? patientAddress;
  final String? physicalCity;
  final String? physicalState;
  final int? documentId;
  final String? patientPhone;
  final String? patientPhone2;
  final DateTime? patientDob;
  final String? patientSex;
  final double? patientWeight;
  final double? patientHeight;
  final int? insulin;
  final DateTime? patientSignatureDatetime;
  final DateTime? employeeSignatureDatetime;
  final String? patientNoSignatureReason;
  final String? otherPersonSignatureRelationship;
  final int? denialId;
  final String? status;
  final String? userName;
  final int? localId;
  final String? deductibleTotal1;
  final String? deductibleTotal2;
  final String? deductibleTotal2Overwritten;
  final String? annualTotal;
  final String? annualTotalLabel;
  final String? total;
  final String? paymentStatus;
  final String? paymentAmount;
  final String? paymentAmountType;
  final String? payMethod;
  final int? itemsCount;
  final int? guaranteeCommitment;
  final int? certificationOfInstructions;
  final String? patientSignature;
  final String? employeeSignature;
  final int? exonerated;
  final List<ConduceNote> notes;
  final List<ConduceDetail> details;

  Conduce({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.completedAt,
    this.serviceDate,
    this.poNumber,
    this.userId,
    this.serviceType,
    this.recordNumber,
    this.patientName,
    this.patientPlanNumber,
    this.patientPlan,
    this.patientPlanName,
    this.patientAddress,
    this.physicalCity,
    this.physicalState,
    this.documentId,
    this.patientPhone,
    this.patientPhone2,
    this.patientDob,
    this.patientSex,
    this.patientWeight,
    this.patientHeight,
    this.insulin,
    this.patientSignatureDatetime,
    this.employeeSignatureDatetime,
    this.patientNoSignatureReason,
    this.otherPersonSignatureRelationship,
    this.denialId,
    this.status,
    this.userName,
    this.localId,
    this.deductibleTotal1,
    this.deductibleTotal2,
    this.deductibleTotal2Overwritten,
    this.annualTotal,
    this.annualTotalLabel,
    this.total,
    this.paymentStatus,
    this.paymentAmount,
    this.paymentAmountType,
    this.payMethod,
    this.itemsCount,
    this.guaranteeCommitment,
    this.certificationOfInstructions,
    this.patientSignature,
    this.employeeSignature,
    this.exonerated,
    required this.notes,
    required this.details,
  });

  Conduce copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? completedAt,
    DateTime? serviceDate,
    String? poNumber,
    int? userId,
    String? serviceType,
    String? recordNumber,
    String? patientName,
    String? patientPlanNumber,
    int? patientPlan,
    String? patientPlanName,
    String? patientAddress,
    String? physicalCity,
    String? physicalState,
    int? documentId,
    String? patientPhone,
    String? patientPhone2,
    DateTime? patientDob,
    String? patientSex,
    double? patientWeight,
    double? patientHeight,
    int? insulin,
    DateTime? patientSignatureDatetime,
    DateTime? employeeSignatureDatetime,
    String? patientNoSignatureReason,
    String? otherPersonSignatureRelationship,
    int? denialId,
    String? status,
    String? userName,
    int? localId,
    String? deductibleTotal1,
    String? deductibleTotal2,
    String? deductibleTotal2Overwritten,
    String? annualTotal,
    String? annualTotalLabel,
    String? total,
    String? paymentStatus,
    String? paymentAmount,
    String? paymentAmountType,
    String? payMethod,
    int? itemsCount,
    int? guaranteeCommitment,
    int? certificationOfInstructions,
    String? patientSignature,
    String? employeeSignature,
    int? exonerated,
    List<ConduceNote>? notes,
    List<ConduceDetail>? details,
  }) {
    return Conduce(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      completedAt: completedAt ?? this.completedAt,
      serviceDate: serviceDate ?? this.serviceDate,
      poNumber: poNumber ?? this.poNumber,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      recordNumber: recordNumber ?? this.recordNumber,
      patientName: patientName ?? this.patientName,
      patientPlanNumber: patientPlanNumber ?? this.patientPlanNumber,
      patientPlan: patientPlan ?? this.patientPlan,
      patientPlanName: patientPlanName ?? this.patientPlanName,
      patientAddress: patientAddress ?? this.patientAddress,
      physicalCity: physicalCity ?? this.physicalCity,
      physicalState: physicalState ?? this.physicalState,
      documentId: documentId ?? this.documentId,
      patientPhone: patientPhone ?? this.patientPhone,
      patientPhone2: patientPhone2 ?? this.patientPhone2,
      patientDob: patientDob ?? this.patientDob,
      patientSex: patientSex ?? this.patientSex,
      patientWeight: patientWeight ?? this.patientWeight,
      patientHeight: patientHeight ?? this.patientHeight,
      insulin: insulin ?? this.insulin,
      patientSignatureDatetime:
      patientSignatureDatetime ?? this.patientSignatureDatetime,
      employeeSignatureDatetime:
      employeeSignatureDatetime ?? this.employeeSignatureDatetime,
      patientNoSignatureReason:
      patientNoSignatureReason ?? this.patientNoSignatureReason,
      otherPersonSignatureRelationship: otherPersonSignatureRelationship ??
          this.otherPersonSignatureRelationship,
      denialId: denialId ?? this.denialId,
      status: status ?? this.status,
      userName: userName ?? this.userName,
      localId: localId ?? this.localId,
      deductibleTotal1: deductibleTotal1 ?? this.deductibleTotal1,
      deductibleTotal2: deductibleTotal2 ?? this.deductibleTotal2,
      deductibleTotal2Overwritten:
      deductibleTotal2Overwritten ?? this.deductibleTotal2Overwritten,
      annualTotal: annualTotal ?? this.annualTotal,
      annualTotalLabel: annualTotalLabel ?? this.annualTotalLabel,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentAmountType: paymentAmountType ?? this.paymentAmountType,
      payMethod: payMethod ?? this.payMethod,
      itemsCount: itemsCount ?? this.itemsCount,
      guaranteeCommitment: guaranteeCommitment ?? this.guaranteeCommitment,
      certificationOfInstructions:
      certificationOfInstructions ?? this.certificationOfInstructions,
      patientSignature: patientSignature ?? this.patientSignature,
      employeeSignature: employeeSignature ?? this.employeeSignature,
      exonerated: exonerated ?? this.exonerated,
      notes: notes ?? this.notes,
      details: details ?? this.details,
    );
  }

  factory Conduce.fromJson(Map<String, dynamic> json) {
    final notesData = json["notes"];
    final detailsData = json["details"];

    return Conduce(
      id: json["id"],
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
      deletedAt: _parseDate(json["deleted_at"]),
      completedAt: _parseDate(json["completed_at"]),
      serviceDate: _parseDate(json["service_date"]),
      poNumber: json["po_number"],
      userId: _parseInt(json["user_id"]),
      serviceType: json["service_type"],
      recordNumber: json["record_number"],
      patientName: json["patient_name"],
      patientPlanNumber: json["patient_plan_number"],
      patientPlan: _parseInt(json["patient_plan"]),
      patientPlanName: json["patient_plan_name"],
      patientAddress: json["patient_address"],
      physicalCity: json["physical_city"],
      physicalState: json["physical_state"],
      documentId: _parseInt(json["document_id"]),
      patientPhone: json["patient_phone"],
      patientPhone2: json["patient_phone_2"],
      patientDob: _parseDate(json["patient_dob"]),
      patientSex: json["patient_sex"],
      patientWeight: _parseDouble(json["patient_weight"]),
      patientHeight: _parseDouble(json["patient_height"]),
      insulin: _parseInt(json["insulin"]),
      patientSignatureDatetime: _parseDate(json["patient_signature_datetime"]),
      employeeSignatureDatetime:
      _parseDate(json["employee_signature_datetime"]),
      patientNoSignatureReason: json["patient_no_signature_reason"],
      otherPersonSignatureRelationship:
      json["other_person_signature_relationship"],
      denialId: _parseInt(json["denial_id"]),
      status: json["status"],
      userName: json["user_name"],
      localId: _parseInt(json["local_id"]),
      deductibleTotal1: json["deductible_total1"],
      deductibleTotal2: json["deductible_total2"],
      deductibleTotal2Overwritten: json["deductible_total2_overwritten"],
      annualTotal: json["annual_total"],
      annualTotalLabel: json["annual_total_label"],
      total: json["total"],
      paymentStatus: json["payment_status"],
      paymentAmount: json["payment_amount"],
      paymentAmountType: json["payment_amount_type"],
      payMethod: json["pay_method"],
      itemsCount: _parseInt(json["items_count"]),
      guaranteeCommitment: _parseInt(json["guarantee_commitment"]),
      certificationOfInstructions:
      _parseInt(json["certification_of_instructions"]),
      patientSignature: json["patient_signature"],
      employeeSignature: json["employee_signature"],
      exonerated: _parseInt(json["exonerated"]),
      notes: notesData == null
          ? []
          : List<ConduceNote>.from(
          notesData.map((x) => ConduceNote.fromJson(x))),
      details: detailsData == null
          ? []
          : List<ConduceDetail>.from(
          detailsData.map((x) => ConduceDetail.fromJson(x))),
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "completed_at": completedAt?.toIso8601String(),
    "service_date": serviceDate?.toIso8601String(),
    "po_number": poNumber,
    "user_id": userId,
    "service_type": serviceType,
    "record_number": recordNumber,
    "patient_name": patientName,
    "patient_plan_number": patientPlanNumber,
    "patient_plan": patientPlan,
    "patient_plan_name": patientPlanName,
    "patient_address": patientAddress,
    "physical_city": physicalCity,
    "physical_state": physicalState,
    "document_id": documentId,
    "patient_phone": patientPhone,
    "patient_phone_2": patientPhone2,
    "patient_dob": patientDob?.toIso8601String(),
    "patient_sex": patientSex,
    "patient_weight": patientWeight,
    "patient_height": patientHeight,
    "insulin": insulin,
    "patient_signature_datetime":
    patientSignatureDatetime?.toIso8601String(),
    "employee_signature_datetime":
    employeeSignatureDatetime?.toIso8601String(),
    "patient_no_signature_reason": patientNoSignatureReason,
    "other_person_signature_relationship": otherPersonSignatureRelationship,
    "denial_id": denialId,
    "status": status,
    "user_name": userName,
    "local_id": localId,
    "deductible_total1": deductibleTotal1,
    "deductible_total2": deductibleTotal2,
    "deductible_total2_overwritten": deductibleTotal2Overwritten,
    "annual_total": annualTotal,
    "annual_total_label": annualTotalLabel,
    "total": total,
    "payment_status": paymentStatus,
    "payment_amount": paymentAmount,
    "payment_amount_type": paymentAmountType,
    "pay_method": payMethod,
    "items_count": itemsCount,
    "guarantee_commitment": guaranteeCommitment,
    "certification_of_instructions": certificationOfInstructions,
    "patient_signature": patientSignature,
    "employee_signature": employeeSignature,
    "exonerated": exonerated,
  };
}

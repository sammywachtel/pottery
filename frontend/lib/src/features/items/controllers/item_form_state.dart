import 'package:intl/intl.dart';

import '../../../data/models/measurement_detail.dart';
import '../../../data/models/measurements.dart';
import '../../../data/models/pottery_item.dart';
import '../../../data/repositories/item_repository.dart';

class ItemFormState {
  ItemFormState({
    this.id,
    this.name = '',
    this.clayType = '',
    this.location = '',
    DateTime? createdDateTime,
    this.currentStatus = 'greenware',
    this.glaze,
    this.cone,
    this.note,
    MeasurementDetail? greenware,
    MeasurementDetail? bisque,
    MeasurementDetail? finalMeasurement,
  })  : createdDateTime = createdDateTime ?? DateTime.now(),
        greenware = greenware,
        bisque = bisque,
        finalMeasurement = finalMeasurement;

  factory ItemFormState.fromItem(PotteryItemModel item) {
    return ItemFormState(
      id: item.id,
      name: item.name,
      clayType: item.clayType,
      location: item.location,
      createdDateTime: item.createdDateTime,
      currentStatus: item.currentStatus,
      glaze: item.glaze,
      cone: item.cone,
      note: item.note,
      greenware: item.measurements?.greenware,
      bisque: item.measurements?.bisque,
      finalMeasurement: item.measurements?.finalMeasurement,
    );
  }

  final String? id;
  final String name;
  final String clayType;
  final String location;
  final DateTime createdDateTime;
  final String currentStatus;
  final String? glaze;
  final String? cone;
  final String? note;
  final MeasurementDetail? greenware;
  final MeasurementDetail? bisque;
  final MeasurementDetail? finalMeasurement;

  ItemFormState copyWith({
    String? id,
    String? name,
    String? clayType,
    String? location,
    DateTime? createdDateTime,
    String? currentStatus,
    String? glaze,
    String? cone,
    String? note,
    MeasurementDetail? greenware,
    MeasurementDetail? bisque,
    MeasurementDetail? finalMeasurement,
  }) {
    return ItemFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      clayType: clayType ?? this.clayType,
      location: location ?? this.location,
      createdDateTime: createdDateTime ?? this.createdDateTime,
      currentStatus: currentStatus ?? this.currentStatus,
      glaze: glaze ?? this.glaze,
      cone: cone ?? this.cone,
      note: note ?? this.note,
      greenware: greenware ?? this.greenware,
      bisque: bisque ?? this.bisque,
      finalMeasurement: finalMeasurement ?? this.finalMeasurement,
    );
  }

  bool get isValid =>
      name.trim().isNotEmpty && clayType.trim().isNotEmpty && location.isNotEmpty;

  Measurements toMeasurements() {
    return Measurements(
      greenware: greenware,
      bisque: bisque,
      finalMeasurement: finalMeasurement,
    );
  }

  Map<String, dynamic> toPayload(ItemRepository repository) {
    final measurements = (greenware != null || bisque != null || finalMeasurement != null)
        ? toMeasurements()
        : null;
    return repository.buildItemPayload(
      name: name,
      clayType: clayType,
      location: location,
      createdDateTime: createdDateTime,
      currentStatus: currentStatus,
      glaze: glaze,
      cone: cone,
      note: note,
      measurements: measurements,
    );
  }

  String formattedCreatedDate() {
    return DateFormat.yMMMd().add_jm().format(createdDateTime);
  }
}

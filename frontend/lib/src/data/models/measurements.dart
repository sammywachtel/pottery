import 'measurement_detail.dart';

class Measurements {
  const Measurements({
    this.greenware,
    this.bisque,
    this.finalMeasurement,
  });

  final MeasurementDetail? greenware;
  final MeasurementDetail? bisque;
  final MeasurementDetail? finalMeasurement;

  factory Measurements.fromJson(Map<String, dynamic> json) {
    return Measurements(
      greenware: json['greenware'] == null
          ? null
          : MeasurementDetail.fromJson(
              Map<String, dynamic>.from(json['greenware'] as Map),
            ),
      bisque: json['bisque'] == null
          ? null
          : MeasurementDetail.fromJson(
              Map<String, dynamic>.from(json['bisque'] as Map),
            ),
      finalMeasurement: json['final'] == null
          ? null
          : MeasurementDetail.fromJson(
              Map<String, dynamic>.from(json['final'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (greenware != null) 'greenware': greenware!.toJson(),
      if (bisque != null) 'bisque': bisque!.toJson(),
      if (finalMeasurement != null) 'final': finalMeasurement!.toJson(),
    };
  }
}

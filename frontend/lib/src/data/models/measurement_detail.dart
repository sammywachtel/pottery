class MeasurementDetail {
  const MeasurementDetail({
    this.height,
    this.width,
    this.depth,
  });

  final double? height;
  final double? width;
  final double? depth;

  factory MeasurementDetail.fromJson(Map<String, dynamic> json) {
    return MeasurementDetail(
      height: _toDouble(json['height']),
      width: _toDouble(json['width']),
      depth: _toDouble(json['depth']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'width': width,
      'depth': depth,
    }..removeWhere((_, value) => value == null);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

import 'measurements.dart';
import 'photo.dart';

class PotteryItemModel {
  const PotteryItemModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.clayType,
    required this.location,
    required this.createdDateTime,
    this.currentStatus = 'greenware',
    this.glaze,
    this.cone,
    this.note,
    this.isBroken = false,
    this.isArchived = false,
    this.updatedDateTime,
    this.measurements,
    this.photos = const [],
  });

  final String id;
  final String userId;
  final String name;
  final String clayType;
  final String location;
  final DateTime createdDateTime;
  final String currentStatus;
  final String? glaze;
  final String? cone;
  final String? note;
  final bool isBroken;
  final bool isArchived;
  final DateTime? updatedDateTime;
  final Measurements? measurements;
  final List<PhotoModel> photos;

  factory PotteryItemModel.fromJson(Map<String, dynamic> json) {
    final photosJson = json['photos'];
    return PotteryItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      clayType: json['clayType'] as String,
      location: json['location'] as String,
      createdDateTime: DateTime.parse(json['createdDateTime'] as String),
      currentStatus: json['currentStatus'] as String? ?? 'greenware',
      glaze: json['glaze'] as String?,
      cone: json['cone'] as String?,
      note: json['note'] as String?,
      isBroken: json['isBroken'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      updatedDateTime: json['updatedDateTime'] != null
          ? DateTime.parse(json['updatedDateTime'] as String)
          : null,
      measurements: json['measurements'] == null
          ? null
          : Measurements.fromJson(
              Map<String, dynamic>.from(json['measurements'] as Map),
            ),
      photos: photosJson is List
          ? photosJson
              .whereType<Map>()
              .map((item) =>
                  PhotoModel.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'clayType': clayType,
      'location': location,
      'createdDateTime': createdDateTime.toIso8601String(),
      'currentStatus': currentStatus,
      'glaze': glaze,
      'cone': cone,
      'note': note,
      'isBroken': isBroken,
      'isArchived': isArchived,
      if (updatedDateTime != null) 'updatedDateTime': updatedDateTime!.toIso8601String(),
      if (measurements != null) 'measurements': measurements!.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
    }..removeWhere((_, value) => value == null);
  }

  PotteryItemModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? clayType,
    String? location,
    DateTime? createdDateTime,
    String? currentStatus,
    String? glaze,
    String? cone,
    String? note,
    bool? isBroken,
    bool? isArchived,
    DateTime? updatedDateTime,
    Measurements? measurements,
    List<PhotoModel>? photos,
  }) {
    return PotteryItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      clayType: clayType ?? this.clayType,
      location: location ?? this.location,
      createdDateTime: createdDateTime ?? this.createdDateTime,
      currentStatus: currentStatus ?? this.currentStatus,
      glaze: glaze ?? this.glaze,
      cone: cone ?? this.cone,
      note: note ?? this.note,
      isBroken: isBroken ?? this.isBroken,
      isArchived: isArchived ?? this.isArchived,
      updatedDateTime: updatedDateTime ?? this.updatedDateTime,
      measurements: measurements ?? this.measurements,
      photos: photos ?? this.photos,
    );
  }
}

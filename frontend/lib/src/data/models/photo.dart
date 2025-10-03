class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.stage,
    required this.uploadedAt,
    this.signedUrl,
    this.imageNote,
    this.fileName,
    this.isPrimary = false,
  });

  final String id;
  final String stage;
  final DateTime uploadedAt;
  final String? signedUrl;
  final String? imageNote;
  final String? fileName;
  final bool isPrimary;

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      stage: json['stage'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      signedUrl: json['signedUrl'] as String?,
      imageNote: json['imageNote'] as String?,
      fileName: json['fileName'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stage': stage,
      'uploadedAt': uploadedAt.toIso8601String(),
      'signedUrl': signedUrl,
      'imageNote': imageNote,
      'fileName': fileName,
      'isPrimary': isPrimary,
    }..removeWhere((_, value) => value == null);
  }
}

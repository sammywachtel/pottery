class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.stage,
    required this.uploadedAt,
    this.signedUrl,
    this.imageNote,
    this.fileName,
  });

  final String id;
  final String stage;
  final DateTime uploadedAt;
  final String? signedUrl;
  final String? imageNote;
  final String? fileName;

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      stage: json['stage'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      signedUrl: json['signedUrl'] as String?,
      imageNote: json['imageNote'] as String?,
      fileName: json['fileName'] as String?,
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
    }..removeWhere((_, value) => value == null);
  }
}

class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.stage,
    required this.uploadedAt,
    this.signedUrl,
    this.imageNote,
    this.fileName,
    this.isPrimary = false,
    this.aspectRatio,
  });

  final String id;
  final String stage;
  final DateTime uploadedAt;
  final String? signedUrl;
  final String? imageNote;
  final String? fileName;
  final bool isPrimary;
  final double? aspectRatio; // width/height (e.g., 1.5 for landscape, 0.75 for portrait)

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      stage: json['stage'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      signedUrl: json['signedUrl'] as String?,
      imageNote: json['imageNote'] as String?,
      fileName: json['fileName'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
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
      'aspectRatio': aspectRatio,
    }..removeWhere((_, value) => value == null);
  }

  /// Helper to determine if photo is landscape (aspect ratio > 1.3)
  bool get isLandscape => (aspectRatio ?? 1.0) > 1.3;

  /// Helper to determine if photo is portrait (aspect ratio < 0.8)
  bool get isPortrait => (aspectRatio ?? 1.0) < 0.8;

  /// Helper to determine if photo is square-ish (aspect ratio ~1.0)
  bool get isSquare => !isLandscape && !isPortrait;
}

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class PhotoUploadRequest {
  PhotoUploadRequest({
    required this.stage,
    required this.fileName,
    required this.bytes,
    required this.contentType,
    this.note,
  });

  final String stage;
  final String fileName;
  final List<int> bytes;
  final String contentType;
  final String? note;

  FormData toFormData() {
    return FormData.fromMap(
      {
        'photo_stage': stage,
        if (note != null) 'photo_note': note,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      },
    );
  }
}

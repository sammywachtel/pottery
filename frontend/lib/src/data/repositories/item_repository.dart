import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../datasources/api_client.dart';
import '../models/measurement_detail.dart';
import '../models/measurements.dart';
import '../models/photo.dart';
import '../models/photo_upload_request.dart';
import '../models/pottery_item.dart';

class ItemRepository {
  ItemRepository(this._client);

  final ApiClient _client;

  Future<List<PotteryItemModel>> fetchItems() async {
    try {
      final response = await _client.dio.get('/api/items/');
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => PotteryItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      throw const AppException('Unexpected items response format');
    } on DioException catch (error) {
      throw AppException(
        error.response?.data['detail']?.toString() ?? 'Failed to fetch items',
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<PotteryItemModel> fetchItem(String id) async {
    try {
      final response = await _client.dio.get('/api/items/$id');
      return PotteryItemModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw AppException(
        error.response?.data['detail']?.toString() ?? 'Failed to fetch item',
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<PotteryItemModel> createItem(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/api/items/', data: payload);
      return PotteryItemModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw AppException(
        error.response?.data['detail']?.toString() ?? 'Failed to create item',
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<PotteryItemModel> updateItem(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.dio.put('/api/items/$id', data: payload);
      return PotteryItemModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      throw AppException(
        error.response?.data['detail']?.toString() ?? 'Failed to update item',
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _client.dio.delete('/api/items/$id');
    } on DioException catch (error) {
      throw AppException(
        error.response?.data['detail']?.toString() ?? 'Failed to delete item',
        statusCode: error.response?.statusCode,
      );
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<PhotoModel> uploadPhoto(
    String itemId,
    PhotoUploadRequest request,
  ) async {
    try {
      final response = await _client.dio.post(
        '/api/items/$itemId/photos/',
        data: request.toFormData(),
      );
      return PhotoModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      final message = _extractErrorMessage(error, 'Failed to upload photo');
      throw AppException(message, statusCode: error.response?.statusCode);
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<void> deletePhoto(String itemId, String photoId) async {
    try {
      await _client.dio.delete('/api/items/$itemId/photos/$photoId');
    } on DioException catch (error) {
      final message = _extractErrorMessage(error, 'Failed to delete photo');
      throw AppException(message, statusCode: error.response?.statusCode);
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<PhotoModel> updatePhoto(
    String itemId,
    String photoId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.dio.put(
        '/api/items/$itemId/photos/$photoId',
        data: payload,
      );
      return PhotoModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      final message = _extractErrorMessage(error, 'Failed to update photo');
      throw AppException(message, statusCode: error.response?.statusCode);
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Future<PhotoModel> setPrimaryPhoto(String itemId, String photoId) async {
    try {
      final response = await _client.dio.patch(
        '/api/items/$itemId/photos/$photoId/primary',
      );
      return PhotoModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (error) {
      final message = _extractErrorMessage(error, 'Failed to set primary photo');
      throw AppException(message, statusCode: error.response?.statusCode);
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(error.toString());
    }
  }

  Map<String, dynamic> buildItemPayload({
    required String name,
    required String clayType,
    required String location,
    required DateTime createdDateTime,
    required String currentStatus,
    String? glaze,
    String? cone,
    String? note,
    Measurements? measurements,
  }) {
    final payload = {
      'name': name,
      'clayType': clayType,
      'location': location,
      'createdDateTime': createdDateTime.toIso8601String(),
      'currentStatus': currentStatus,
      if (glaze != null && glaze.isNotEmpty) 'glaze': glaze,
      if (cone != null && cone.isNotEmpty) 'cone': cone,
      if (note != null && note.isNotEmpty) 'note': note,
      if (measurements != null) 'measurements': measurements.toJson(),
    };
    return payload;
  }

  Measurements buildMeasurements({
    MeasurementDetail? greenware,
    MeasurementDetail? bisque,
    MeasurementDetail? finalMeasurement,
  }) {
    return Measurements(
      greenware: greenware,
      bisque: bisque,
      finalMeasurement: finalMeasurement,
    );
  }

  String _extractErrorMessage(DioException error, String fallback) {
    final response = error.response;
    if (response?.data is Map<String, dynamic>) {
      final map = Map<String, dynamic>.from(response!.data as Map);
      final detail = map['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        final first = detail.firstWhereOrNull((element) => element != null);
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
      }
    }
    return fallback;
  }
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ItemRepository(client);
});

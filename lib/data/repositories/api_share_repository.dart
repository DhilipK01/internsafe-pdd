import 'package:dio/dio.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';

class ApiShareRepository implements ShareRepository {
  ApiShareRepository(this._api);

  final ApiClient _api;

  @override
  Future<ShareLinkResult> createShare({
    required ShareResourceType resourceType,
    String? resourceId,
    String? companyName,
    String? query,
    ShareVisibility visibility = ShareVisibility.public,
    ShareExpiryOption expiry = ShareExpiryOption.days14,
    bool confirmSensitive = false,
  }) async {
    try {
      Map<String, dynamic> data;
      try {
        data = await _api.postJson(
          '/share/create',
          body: _body(
            resourceType,
            resourceId,
            companyName,
            query,
            visibility,
            expiry,
            confirmSensitive,
          ),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          data = await _api.postJson(
            '/shares',
            body: _body(
              resourceType,
              resourceId,
              companyName,
              query,
              visibility,
              expiry,
              confirmSensitive,
            ),
          );
        } else {
          rethrow;
        }
      }

      final url = data['url'] as String?;
      final token = data['token'] as String?;
      if (url == null || url.isEmpty || token == null || token.isEmpty) {
        final err = data['error'] as String?;
        throw ApiException(err ?? 'Invalid share response from server.');
      }

      return ShareLinkResult(
        url: url,
        token: token,
        expiresAt: data['expiresAt'] as String? ?? '',
        viewUrl: data['viewUrl'] as String?,
        appUrl: data['appUrl'] as String?,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(e.message ?? 'Could not create share link');
    }
  }

  Map<String, dynamic> _body(
    ShareResourceType resourceType,
    String? resourceId,
    String? companyName,
    String? query,
    ShareVisibility visibility,
    ShareExpiryOption expiry,
    bool confirmSensitive,
  ) =>
      {
        'resourceType': resourceType.apiValue,
        if (resourceId != null && resourceId.isNotEmpty) 'resourceId': resourceId,
        if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
        if (query != null && query.isNotEmpty) 'query': query,
        'visibility': visibility.apiValue,
        'expiry': expiry.apiValue,
        'confirmSensitive': confirmSensitive,
      };

  @override
  Future<SharedSnapshot> getShare(String token) async {
    const paths = ['/share/', '/shares/', '/s/'];
    ApiException? last;
    for (final prefix in paths) {
      try {
        final res = await _api.dio.get<Map<String, dynamic>>(
          '$prefix$token',
          options: Options(
            headers: const {'Accept': 'application/json'},
          ),
        );
        final data = res.data ?? {};
        final share = data['share'] as Map<String, dynamic>?;
        if (share == null) {
          throw ApiException('Share not found or expired.');
        }
        return SharedSnapshot(
          resourceType: share['resourceType'] as String? ?? '',
          snapshot: Map<String, dynamic>.from(
            share['snapshot'] as Map<String, dynamic>? ?? {},
          ),
          expiresAt: share['expiresAt'] as String? ?? '',
          documentPreviewUrl: share['documentPreviewUrl'] as String?,
          webUrl: share['webUrl'] as String?,
          appUrl: share['appUrl'] as String?,
        );
      } on ApiException catch (e) {
        last = e;
        if (e.statusCode != 404) rethrow;
      } on DioException catch (e) {
        if (e.error is ApiException) {
          final ae = e.error as ApiException;
          last = ae;
          if (ae.statusCode != 404) rethrow;
        } else {
          rethrow;
        }
      }
    }
    throw last ?? ApiException('Share not found or expired.');
  }

  @override
  Future<void> revokeShare(String token) async {
    await _api.postJson('/share/revoke', body: {'token': token});
  }
}

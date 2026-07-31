import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockTokenStorage tokenStorage;
  late ApiClient apiClient;

  setUp(() {
    tokenStorage = MockTokenStorage();
    apiClient = ApiClient(tokenStorage: tokenStorage);
  });

  test('attaches Authorization header when access token exists', () async {
    when(() => tokenStorage.readAccessToken())
        .thenAnswer((_) async => 'test-token');

    apiClient.dio.httpClientAdapter = _RecordingAdapter();
    final response = await apiClient.get<Map<String, dynamic>>('/ping');

    expect(
      (apiClient.dio.httpClientAdapter as _RecordingAdapter).lastHeaders?['Authorization'],
      'Bearer test-token',
    );
    expect(response.statusCode, 200);
  });

  test('omits Authorization header when no token stored', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);

    apiClient.dio.httpClientAdapter = _RecordingAdapter();
    await apiClient.get<Map<String, dynamic>>('/ping');

    expect(
      (apiClient.dio.httpClientAdapter as _RecordingAdapter).lastHeaders?.containsKey('Authorization'),
      false,
    );
  });
}

/// Minimal fake adapter that always returns 200 with an empty JSON body,
/// recording the headers it was called with so the interceptor can be
/// asserted without a real HTTP server.
class _RecordingAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = options.headers;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

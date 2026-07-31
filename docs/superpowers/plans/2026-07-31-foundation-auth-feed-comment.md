# Foundation Architecture + Auth/Feed/Comment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the freshly-created `tiktok_mobile` Flutter project into a running app with a
shared architectural foundation and a working Auth → Feed → Comment vertical slice.

**Architecture:** Feature-first folders (`lib/features/<feature>/{data,presentation}`) on top of
a shared `lib/core/` (network, router, theme, shared widgets). Riverpod (codegen) for state,
`go_router` for navigation, `dio` for REST, `freezed`/`json_serializable` for models. No domain
layer — repositories return models directly.

**Tech Stack:** Flutter, Dart ^3.10, `flutter_riverpod` + `riverpod_generator`, `go_router`,
`dio`, `web_socket_channel`, `freezed` + `json_serializable`, `flutter_secure_storage`,
`video_player`, `cached_network_image`, `mocktail` (tests), `build_runner`.

## Global Constraints

- Every feature uses exactly two layers: `data/` and `presentation/` — no `domain/` layer (per
  spec decision to reduce boilerplate).
- All models are immutable `freezed` classes with `json_serializable` `fromJson`/`toJson`.
- All async state (auth, feed, comments) is exposed via Riverpod `AsyncValue`; widgets must not
  contain manual `try/catch` around repository calls — errors surface through `AsyncValue.error`.
- All repository/datasource errors are converted to one of `AppException`'s four variants
  (`network`, `server`, `unauthorized`, `unknown`) before leaving the `data/` layer.
- `ApiClient` base URL comes from `--dart-define=API_BASE_URL=...`, never hardcoded.
- The REST response envelope (`ApiResponse<T>`) and all endpoint paths in this plan are
  **provisional** — the backend is being built in parallel and isn't finalized. When the real
  contract lands, only `core/network/api_response.dart` and the `*_remote_datasource.dart` files
  should need to change.
- `WebSocketService` is built as a scaffold in this plan but is **not** wired into Auth, Feed, or
  Comment — realtime wiring is out of scope here (per spec) and will be a future plan.
- No social login, no product tagging, no realtime like-count, no chat, no notifications, no
  video upload flow — all explicitly out of scope per the approved spec.

---

## Task 1: Project setup — dependencies and folder skeleton

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/network/.gitkeep`, `lib/core/router/.gitkeep`, `lib/core/di/.gitkeep`, `lib/core/theme/.gitkeep`, `lib/core/widgets/.gitkeep`, `lib/core/utils/.gitkeep`, `lib/core/constants/.gitkeep`
- Create: `lib/features/auth/data/.gitkeep`, `lib/features/auth/presentation/.gitkeep`
- Create: `lib/features/feed/data/.gitkeep`, `lib/features/feed/presentation/.gitkeep`
- Create: `lib/features/comment/data/.gitkeep`, `lib/features/comment/presentation/.gitkeep`

**Interfaces:**
- Produces: a working `flutter pub get` and `flutter analyze` baseline every later task builds on.

- [ ] **Step 1: Add dependencies to `pubspec.yaml`**

Edit the `dependencies:` block to:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.6.2
  dio: ^5.7.0
  web_socket_channel: ^3.0.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.3
  video_player: ^2.9.2
  cached_network_image: ^3.4.1
```

Edit the `dev_dependencies:` block to:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.3
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  mocktail: ^1.0.4
```

- [ ] **Step 2: Create folder skeleton**

```bash
mkdir -p lib/core/{network,router,di,theme,widgets,utils,constants}
mkdir -p lib/features/auth/{data,presentation}
mkdir -p lib/features/feed/{data,presentation}
mkdir -p lib/features/comment/{data,presentation}
touch lib/core/network/.gitkeep lib/core/router/.gitkeep lib/core/di/.gitkeep \
      lib/core/theme/.gitkeep lib/core/widgets/.gitkeep lib/core/utils/.gitkeep \
      lib/core/constants/.gitkeep \
      lib/features/auth/data/.gitkeep lib/features/auth/presentation/.gitkeep \
      lib/features/feed/data/.gitkeep lib/features/feed/presentation/.gitkeep \
      lib/features/comment/data/.gitkeep lib/features/comment/presentation/.gitkeep
```

- [ ] **Step 3: Install and verify**

Run: `flutter pub get`
Expected: resolves with no errors.

Run: `flutter analyze`
Expected: "No issues found!" (default counter app still present in `lib/main.dart` at this point).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core lib/features
git commit -m "chore: add core dependencies and feature-first folder skeleton"
```

---

## Task 2: Core error handling — `AppException` + `ApiResponse` envelope

**Files:**
- Create: `lib/core/network/app_exception.dart`
- Create: `lib/core/network/api_response.dart`
- Test: `test/core/network/app_exception_test.dart`

**Interfaces:**
- Produces: `sealed class AppException` with `NetworkException`, `ServerException(int statusCode, String message)`, `UnauthorizedException`, `UnknownException(String message)`; `AppException.fromDioException(DioException e)` factory.
- Produces: `class ApiResponse<T> { final bool success; final T? data; final ApiError? error; ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT); }` and `class ApiError { final String code; final String message; }`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/network/app_exception_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';

void main() {
  group('AppException.fromDioException', () {
    test('maps connection errors to NetworkException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = AppException.fromDioException(dioException);

      expect(result, isA<NetworkException>());
    });

    test('maps 401 responses to UnauthorizedException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        response: Response(
          requestOptions: RequestOptions(path: '/feed'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final result = AppException.fromDioException(dioException);

      expect(result, isA<UnauthorizedException>());
    });

    test('maps other bad responses to ServerException with status code', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/feed'),
        response: Response(
          requestOptions: RequestOptions(path: '/feed'),
          statusCode: 500,
          data: {'error': {'message': 'boom'}},
        ),
        type: DioExceptionType.badResponse,
      );

      final result = AppException.fromDioException(dioException) as ServerException;

      expect(result.statusCode, 500);
      expect(result.message, 'boom');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/app_exception_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:tiktok_mobile/core/network/app_exception.dart'`.

- [ ] **Step 3: Implement `AppException`**

```dart
// lib/core/network/app_exception.dart
import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  factory AppException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401) {
        return const UnauthorizedException();
      }
      final data = e.response?.data;
      final serverMessage = (data is Map && data['error'] is Map)
          ? (data['error']['message'] as String?) ?? 'Server error'
          : 'Server error';
      return ServerException(statusCode, serverMessage);
    }

    return UnknownException(e.message ?? 'Unknown error');
  }
}

final class NetworkException extends AppException {
  const NetworkException() : super('No internet connection');
}

final class ServerException extends AppException {
  const ServerException(this.statusCode, String message) : super(message);
  final int statusCode;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired, please log in again');
}

final class UnknownException extends AppException {
  const UnknownException(String message) : super(message);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/network/app_exception_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Implement `ApiResponse` envelope (no dedicated test — plain data holder exercised by later datasource tests)**

```dart
// lib/core/network/api_response.dart
class ApiError {
  const ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String? ?? 'unknown',
        message: json['message'] as String? ?? 'Unknown error',
      );

  final String code;
  final String message;
}

class ApiResponse<T> {
  const ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] == null ? null : fromJsonT(json['data']),
      error: json['error'] == null
          ? null
          : ApiError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }

  final bool success;
  final T? data;
  final ApiError? error;
}
```

- [ ] **Step 6: Run full test suite and analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS, no analyzer issues.

- [ ] **Step 7: Commit**

```bash
git add lib/core/network/app_exception.dart lib/core/network/api_response.dart test/core/network/app_exception_test.dart
git commit -m "feat: add AppException mapping and ApiResponse envelope"
```

---

## Task 3: Core network — `ApiClient` (Dio wrapper + interceptors)

**Files:**
- Create: `lib/core/network/api_client.dart`
- Create: `lib/core/constants/env.dart`
- Test: `test/core/network/api_client_test.dart`

**Interfaces:**
- Consumes: `AppException.fromDioException` from Task 2.
- Produces: `class ApiClient { ApiClient({required TokenStorage tokenStorage}); Dio get dio; Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}); Future<Response<T>> post<T>(String path, {Object? data}); }` and `abstract class TokenStorage { Future<String?> readAccessToken(); Future<String?> readRefreshToken(); Future<void> saveTokens({required String accessToken, required String refreshToken}); Future<void> clear(); }`.
- Produces: `class Env { static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080'); }`.

- [ ] **Step 1: Write `Env` (no test — trivial constant holder)**

```dart
// lib/core/constants/env.dart
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
```

- [ ] **Step 2: Write the failing test for `ApiClient`**

```dart
// test/core/network/api_client_test.dart
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/core/network/api_client_test.dart`
Expected: FAIL — `ApiClient`/`TokenStorage` don't exist yet.

- [ ] **Step 4: Implement `ApiClient`**

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/constants/env.dart';

abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

class ApiClient {
  ApiClient({required this.tokenStorage, Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )) {
    this.dio.interceptors.add(
          InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
        );
  }

  final Dio dio;
  final TokenStorage tokenStorage;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Token refresh-on-401 is added in a later task once AuthRepository
    // exists; for now errors pass through unchanged.
    handler.next(err);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return dio.post<T>(path, data: data);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/network/api_client_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/network/api_client.dart lib/core/constants/env.dart test/core/network/api_client_test.dart
git commit -m "feat: add ApiClient with token-attaching interceptor"
```

---

## Task 4: Core network — `WebSocketService` scaffold

**Files:**
- Create: `lib/core/network/websocket_service.dart`
- Test: `test/core/network/websocket_service_test.dart`

**Interfaces:**
- Produces: `class WebSocketService { WebSocketService(String url); Stream<dynamic> channel(String name); void dispose(); }` — reconnect-with-backoff logic lives here; **not consumed by any feature in this plan**.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/network/websocket_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/network/websocket_service.dart';

void main() {
  test('channel() returns the same broadcast stream for repeated calls with the same name', () {
    final service = WebSocketService('ws://localhost:8080/ws');

    final first = service.channel('feed_updates');
    final second = service.channel('feed_updates');

    expect(identical(first, second), isTrue);

    service.dispose();
  });

  test('channel() returns distinct streams for distinct channel names', () {
    final service = WebSocketService('ws://localhost:8080/ws');

    final feed = service.channel('feed_updates');
    final chat = service.channel('chat:123');

    expect(identical(feed, chat), isFalse);

    service.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/network/websocket_service_test.dart`
Expected: FAIL — `WebSocketService` doesn't exist.

- [ ] **Step 3: Implement `WebSocketService`**

```dart
// lib/core/network/websocket_service.dart
import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Single shared WebSocket connection exposing per-channel broadcast
/// streams. Not wired to any feature yet — connection is created lazily
/// on first use and reconnects with exponential backoff on drop.
class WebSocketService {
  WebSocketService(this._url);

  final String _url;
  WebSocketChannel? _channel;
  final Map<String, StreamController<dynamic>> _controllers = {};
  int _backoffSeconds = 1;

  Stream<dynamic> channel(String name) {
    final controller = _controllers.putIfAbsent(
      name,
      () => StreamController<dynamic>.broadcast(),
    );
    _ensureConnected();
    return controller.stream;
  }

  void _ensureConnected() {
    if (_channel != null) return;
    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _channel!.stream.listen(
      _routeMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
  }

  void _routeMessage(dynamic message) {
    // Messages are expected as {"channel": "...", "payload": ...} once the
    // backend contract is finalized; broadcast raw for now.
    for (final controller in _controllers.values) {
      controller.add(message);
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    Timer(Duration(seconds: _backoffSeconds), () {
      _backoffSeconds = (_backoffSeconds * 2).clamp(1, 30);
      _ensureConnected();
    });
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _channel?.sink.close();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/network/websocket_service_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/network/websocket_service.dart test/core/network/websocket_service_test.dart
git commit -m "feat: add WebSocketService scaffold (unwired)"
```

---

## Task 5: Core theme + shared widgets

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/widgets/loading_view.dart`
- Create: `lib/core/widgets/error_view.dart`
- Test: `test/core/widgets/error_view_test.dart`

**Interfaces:**
- Produces: `class AppTheme { static ThemeData get dark; }`, `class LoadingView extends StatelessWidget {}`, `class ErrorView extends StatelessWidget { const ErrorView({required this.message, this.onRetry}); final String message; final VoidCallback? onRetry; }`.

- [ ] **Step 1: Implement `AppTheme` and `LoadingView` (no dedicated tests — trivial presentational code exercised via screen widget tests later)**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFE2C55),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      );
}
```

```dart
// lib/core/widgets/loading_view.dart
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
```

- [ ] **Step 2: Write the failing test for `ErrorView`**

```dart
// test/core/widgets/error_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';

void main() {
  testWidgets('shows message and invokes onRetry when button tapped', (tester) async {
    var retried = false;

    await tester.pumpWidget(MaterialApp(
      home: ErrorView(
        message: 'Something went wrong',
        onRetry: () => retried = true,
      ),
    ));

    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('hides retry button when onRetry is null', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ErrorView(message: 'Oops'),
    ));

    expect(find.text('Retry'), findsNothing);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/core/widgets/error_view_test.dart`
Expected: FAIL — `ErrorView` doesn't exist.

- [ ] **Step 4: Implement `ErrorView`**

```dart
// lib/core/widgets/error_view.dart
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/widgets/error_view_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme lib/core/widgets test/core/widgets/error_view_test.dart
git commit -m "feat: add app theme and shared loading/error widgets"
```

---

## Task 6: Auth data layer — `UserModel`, `AuthRemoteDatasource`, `AuthRepository`

**Files:**
- Create: `lib/features/auth/data/user_model.dart`
- Create: `lib/features/auth/data/auth_remote_datasource.dart`
- Create: `lib/features/auth/data/auth_repository.dart`
- Test: `test/features/auth/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (Task 3), `TokenStorage` (Task 3), `AppException` (Task 2).
- Produces: `@freezed class UserModel { factory UserModel({required String id, required String username, required String email, String? avatarUrl}) = _UserModel; factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json); }`.
- Produces: `class AuthResult { final UserModel user; final String accessToken; final String refreshToken; }`.
- Produces: `class AuthRepository { AuthRepository({required AuthRemoteDatasource remoteDatasource, required TokenStorage tokenStorage}); Future<UserModel> login({required String email, required String password}); Future<UserModel> register({required String email, required String password, required String username}); Future<void> logout(); }` — throws `AppException` subtypes on failure, persists tokens via `TokenStorage` on success.

- [ ] **Step 1: Define `UserModel`**

```dart
// lib/features/auth/data/user_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    required String email,
    String? avatarUrl,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

- [ ] **Step 2: Define `AuthRemoteDatasource`**

```dart
// lib/features/auth/data/auth_remote_datasource.dart
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class AuthTokens {
  const AuthTokens({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;
}

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseTokens(response.data!);
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'username': username},
    );
    return _parseTokens(response.data!);
  }

  AuthTokens _parseTokens(Map<String, dynamic> data) {
    final body = data['data'] as Map<String, dynamic>;
    return AuthTokens(
      user: UserModel.fromJson(body['user'] as Map<String, dynamic>),
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );
  }
}
```

- [ ] **Step 3: Write the failing test for `AuthRepository`**

```dart
// test/features/auth/data/auth_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRemoteDatasource remoteDatasource;
  late MockTokenStorage tokenStorage;
  late AuthRepository repository;

  setUp(() {
    remoteDatasource = MockAuthRemoteDatasource();
    tokenStorage = MockTokenStorage();
    repository = AuthRepository(
      remoteDatasource: remoteDatasource,
      tokenStorage: tokenStorage,
    );
  });

  const user = UserModel(id: '1', username: 'jane', email: 'jane@test.com');
  const tokens = AuthTokens(
    user: user,
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  test('login persists tokens and returns the user on success', () async {
    when(() => remoteDatasource.login(email: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => tokens);
    when(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).thenAnswer((_) async {});

    final result = await repository.login(email: 'jane@test.com', password: 'pw');

    expect(result, user);
    verify(() => tokenStorage.saveTokens(
          accessToken: 'access',
          refreshToken: 'refresh',
        )).called(1);
  });

  test('login converts a DioException into an AppException', () async {
    when(() => remoteDatasource.login(email: 'jane@test.com', password: 'wrong'))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
      ),
      type: DioExceptionType.badResponse,
    ));

    expect(
      () => repository.login(email: 'jane@test.com', password: 'wrong'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('logout clears stored tokens', () async {
    when(() => tokenStorage.clear()).thenAnswer((_) async {});

    await repository.logout();

    verify(() => tokenStorage.clear()).called(1);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/auth/data/auth_repository_test.dart`
Expected: FAIL — `AuthRepository` doesn't exist.

- [ ] **Step 5: Implement `AuthRepository`**

```dart
// lib/features/auth/data/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDatasource remoteDatasource,
    required TokenStorage tokenStorage,
  })  : _remoteDatasource = remoteDatasource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDatasource _remoteDatasource;
  final TokenStorage _tokenStorage;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await _remoteDatasource.login(email: email, password: password);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.user;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final tokens = await _remoteDatasource.register(
        email: email,
        password: password,
        username: username,
      );
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens.user;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();
}
```

- [ ] **Step 6: Generate freezed/json code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/auth/data/auth_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/data test/features/auth/data pubspec.lock
git commit -m "feat: add auth data layer (UserModel, remote datasource, repository)"
```

---

## Task 7: `SecureTokenStorage` — concrete `TokenStorage` implementation

**Files:**
- Create: `lib/core/network/secure_token_storage.dart`
- Test: none (thin wrapper over `flutter_secure_storage`; exercised indirectly through `AuthRepository` tests using the mock, and manually in Task 19's smoke test).

**Interfaces:**
- Consumes: `TokenStorage` interface from Task 3.
- Produces: `class SecureTokenStorage implements TokenStorage` backed by `FlutterSecureStorage`.

- [ ] **Step 1: Implement `SecureTokenStorage`**

```dart
// lib/core/network/secure_token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/network/secure_token_storage.dart
git commit -m "feat: add SecureTokenStorage backed by flutter_secure_storage"
```

---

## Task 8: Auth state — `authStateProvider` (Riverpod)

**Files:**
- Create: `lib/features/auth/presentation/auth_provider.dart`
- Test: `test/features/auth/presentation/auth_provider_test.dart`

**Interfaces:**
- Consumes: `AuthRepository` (Task 6), `UserModel` (Task 6).
- Produces: `@riverpod class AuthState extends _$AuthState { @override FutureOr<UserModel?> build(); Future<void> login({required String email, required String password}); Future<void> register({required String email, required String password, required String username}); Future<void> logout(); }` exposed as `authStateProvider`.
- Produces: `final authRepositoryProvider = Provider<AuthRepository>(...)` (overridden in tests).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/auth_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late ProviderContainer container;

  const user = UserModel(id: '1', username: 'jane', email: 'jane@test.com');

  setUp(() {
    authRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build() starts as null (signed out) when no session', () async {
    final result = await container.read(authStateProvider.future);
    expect(result, isNull);
  });

  test('login() sets state to the logged-in user', () async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => user);
    await container.read(authStateProvider.future);

    await container.read(authStateProvider.notifier).login(
          email: 'jane@test.com',
          password: 'pw',
        );

    expect(container.read(authStateProvider).value, user);
  });

  test('logout() clears the state back to null', () async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'pw'))
        .thenAnswer((_) async => user);
    when(() => authRepository.logout()).thenAnswer((_) async {});
    await container.read(authStateProvider.future);
    await container.read(authStateProvider.notifier).login(
          email: 'jane@test.com',
          password: 'pw',
        );

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(authStateProvider).value, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/auth_provider_test.dart`
Expected: FAIL — `authStateProvider`/`authRepositoryProvider` don't exist.

- [ ] **Step 3: Implement the provider**

```dart
// lib/features/auth/presentation/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/core/network/secure_token_storage.dart';
import 'package:tiktok_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(TokenStorageRef ref) => SecureTokenStorage();

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) =>
    ApiClient(tokenStorage: ref.watch(tokenStorageProvider));

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) => AuthRepository(
      remoteDatasource: AuthRemoteDatasource(ref.watch(apiClientProvider)),
      tokenStorage: ref.watch(tokenStorageProvider),
    );

@riverpod
class AuthState extends _$AuthState {
  @override
  FutureOr<UserModel?> build() {
    // No "restore session" call to the backend yet (endpoint not defined
    // in the provisional contract) — app always starts signed out.
    return null;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            username: username,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
```

- [ ] **Step 4: Generate code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/auth/presentation/auth_provider_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/auth_provider.dart lib/features/auth/presentation/auth_provider.g.dart test/features/auth/presentation/auth_provider_test.dart
git commit -m "feat: add authStateProvider with login/register/logout"
```

---

## Task 9: Core router — `go_router` with auth guard

**Files:**
- Create: `lib/core/router/app_router.dart`
- Test: `test/core/router/app_router_test.dart`

**Interfaces:**
- Consumes: `authStateProvider` (Task 8).
- Produces: `final appRouterProvider = Provider<GoRouter>(...)` with routes `/login`, `/register`, `/feed`; redirects unauthenticated users to `/login` and authenticated users away from `/login`/`/register` to `/feed`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/router/app_router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

void main() {
  testWidgets('redirects to /login when signed out and /feed is requested', (tester) async {
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith(_SignedOutAuthState.new)],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    final router = container.read(appRouterProvider);
    router.go('/feed');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('redirects to /feed when signed in and /login is requested', (tester) async {
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith(_SignedInAuthState.new)],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);

    final router = container.read(appRouterProvider);
    router.go('/login');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feed'), findsOneWidget);
  });
}

class _SignedOutAuthState extends AuthState {
  @override
  FutureOr<dynamic> build() => null;
}

class _SignedInAuthState extends AuthState {
  @override
  FutureOr<dynamic> build() => const _FakeUser();
}

class _FakeUser {
  const _FakeUser();
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/router/app_router_test.dart`
Expected: FAIL — `appRouterProvider` doesn't exist (and `LoginScreen`/`FeedScreen` placeholders below don't exist yet either).

- [ ] **Step 3: Implement `app_router.dart`**

Note: this task references `LoginScreen`, `RegisterScreen`, `FeedScreen` by name — they are
built as trivial placeholders here and fleshed out in Tasks 10, 11, and 15 respectively. Router
tests only check navigation, not screen content beyond a `Scaffold` title.

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/login_screen.dart';
import 'package:tiktok_mobile/features/auth/presentation/register_screen.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/feed',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/feed';
      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
    ],
  );
});

/// Bridges Riverpod's authStateProvider changes into go_router's
/// ChangeNotifier-based refresh mechanism.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
```

- [ ] **Step 4: Create placeholder `LoginScreen`, `RegisterScreen`, `FeedScreen`**

```dart
// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Login')));
  }
}
```

```dart
// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Register')));
  }
}
```

```dart
// lib/features/feed/presentation/feed_screen.dart
import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Feed')));
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/router/app_router_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/core/router lib/features/auth/presentation/login_screen.dart lib/features/auth/presentation/register_screen.dart lib/features/feed/presentation/feed_screen.dart test/core/router/app_router_test.dart
git commit -m "feat: add go_router with auth-based redirect guard"
```

---

## Task 10: Auth UI — `LoginScreen`

**Files:**
- Modify: `lib/features/auth/presentation/login_screen.dart` (replace placeholder)
- Test: `test/features/auth/presentation/login_screen_test.dart`

**Interfaces:**
- Consumes: `authStateProvider.login(...)` (Task 8).
- Produces: real `LoginScreen` with email/password fields, submit button, error text on failure, link to `/register`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() => authRepository = MockAuthRepository());

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('submitting valid credentials calls repository.login', (tester) async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'secret12'))
        .thenAnswer((_) async => const UserModel(
              id: '1',
              username: 'jane',
              email: 'jane@test.com',
            ));

    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'jane@test.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'secret12');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    verify(() => authRepository.login(email: 'jane@test.com', password: 'secret12')).called(1);
  });

  testWidgets('shows an error message when login fails', (tester) async {
    when(() => authRepository.login(email: 'jane@test.com', password: 'wrong'))
        .thenThrow(Exception('invalid credentials'));

    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'jane@test.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'wrong');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid credentials'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: FAIL — placeholder `LoginScreen` has none of these keys/widgets.

- [ ] **Step 3: Implement real `LoginScreen`**

```dart
// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('login_email_field'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('login_password_field'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (authState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  authState.error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              key: const Key('login_submit_button'),
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authStateProvider.notifier).login(
                        email: _emailController.text,
                        password: _passwordController.text,
                      ),
              child: authState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Log in'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/login_screen.dart test/features/auth/presentation/login_screen_test.dart
git commit -m "feat: implement LoginScreen with real form and error state"
```

---

## Task 11: Auth UI — `RegisterScreen`

**Files:**
- Modify: `lib/features/auth/presentation/register_screen.dart` (replace placeholder)
- Test: `test/features/auth/presentation/register_screen_test.dart`

**Interfaces:**
- Consumes: `authStateProvider.register(...)` (Task 8).
- Produces: real `RegisterScreen` mirroring `LoginScreen`'s structure with an added username field.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/auth/presentation/register_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/auth/data/auth_repository.dart';
import 'package:tiktok_mobile/features/auth/data/user_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/auth/presentation/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('submitting valid data calls repository.register', (tester) async {
    final authRepository = MockAuthRepository();
    when(() => authRepository.register(
          email: 'jane@test.com',
          password: 'secret12',
          username: 'jane',
        )).thenAnswer((_) async => const UserModel(
          id: '1',
          username: 'jane',
          email: 'jane@test.com',
        ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.enterText(find.byKey(const Key('register_username_field')), 'jane');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'jane@test.com');
    await tester.enterText(find.byKey(const Key('register_password_field')), 'secret12');
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    verify(() => authRepository.register(
          email: 'jane@test.com',
          password: 'secret12',
          username: 'jane',
        )).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/presentation/register_screen_test.dart`
Expected: FAIL — placeholder has none of these keys.

- [ ] **Step 3: Implement real `RegisterScreen`**

```dart
// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('register_username_field'),
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('register_email_field'),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('register_password_field'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (authState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  authState.error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              key: const Key('register_submit_button'),
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authStateProvider.notifier).register(
                        email: _emailController.text,
                        password: _passwordController.text,
                        username: _usernameController.text,
                      ),
              child: authState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/presentation/register_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/register_screen.dart test/features/auth/presentation/register_screen_test.dart
git commit -m "feat: implement RegisterScreen with real form"
```

---

## Task 12: Feed data layer — `VideoModel`, `FeedRemoteDatasource`, `FeedRepository`

**Files:**
- Create: `lib/features/feed/data/video_model.dart`
- Create: `lib/features/feed/data/feed_remote_datasource.dart`
- Create: `lib/features/feed/data/feed_repository.dart`
- Test: `test/features/feed/data/feed_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (Task 3), `AppException` (Task 2).
- Produces: `@freezed class VideoModel { factory VideoModel({required String id, required String url, required String thumbnailUrl, required String caption, required String username, String? avatarUrl, required int likeCount, required int commentCount, required int shareCount, required bool isLiked, required bool isSaved}) = _VideoModel; factory VideoModel.fromJson(...); }`.
- Produces: `class FeedPage { final List<VideoModel> items; final String? nextCursor; }`.
- Produces: `class FeedRepository { Future<FeedPage> fetchFeed({String? cursor}); Future<VideoModel> toggleLike(String videoId); Future<VideoModel> toggleSave(String videoId); }`.

- [ ] **Step 1: Define `VideoModel`**

```dart
// lib/features/feed/data/video_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_model.freezed.dart';
part 'video_model.g.dart';

@freezed
class VideoModel with _$VideoModel {
  const factory VideoModel({
    required String id,
    required String url,
    required String thumbnailUrl,
    required String caption,
    required String username,
    String? avatarUrl,
    required int likeCount,
    required int commentCount,
    required int shareCount,
    required bool isLiked,
    required bool isSaved,
  }) = _VideoModel;

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);
}
```

- [ ] **Step 2: Define `FeedRemoteDatasource`**

```dart
// lib/features/feed/data/feed_remote_datasource.dart
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class FeedPage {
  const FeedPage({required this.items, this.nextCursor});

  final List<VideoModel> items;
  final String? nextCursor;
}

class FeedRemoteDatasource {
  FeedRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<FeedPage> fetchFeed({String? cursor}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/feed',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': 10,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return FeedPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  Future<VideoModel> toggleLike(String videoId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/$videoId/like',
    );
    return VideoModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<VideoModel> toggleSave(String videoId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/$videoId/save',
    );
    return VideoModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
```

- [ ] **Step 3: Write the failing test for `FeedRepository`**

```dart
// test/features/feed/data/feed_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class MockFeedRemoteDatasource extends Mock implements FeedRemoteDatasource {}

void main() {
  late MockFeedRemoteDatasource remoteDatasource;
  late FeedRepository repository;

  const video = VideoModel(
    id: 'v1',
    url: 'https://example.com/v1.mp4',
    thumbnailUrl: 'https://example.com/v1.jpg',
    caption: 'hello',
    username: 'jane',
    likeCount: 10,
    commentCount: 2,
    shareCount: 1,
    isLiked: false,
    isSaved: false,
  );

  setUp(() {
    remoteDatasource = MockFeedRemoteDatasource();
    repository = FeedRepository(remoteDatasource);
  });

  test('fetchFeed returns items and cursor from the datasource', () async {
    when(() => remoteDatasource.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [video], nextCursor: 'cursor2'),
    );

    final result = await repository.fetchFeed();

    expect(result.items, [video]);
    expect(result.nextCursor, 'cursor2');
  });

  test('fetchFeed converts a DioException into an AppException', () async {
    when(() => remoteDatasource.fetchFeed(cursor: null)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/feed'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repository.fetchFeed(), throwsA(isA<NetworkException>()));
  });

  test('toggleLike returns the updated video', () async {
    final liked = video.copyWith(isLiked: true, likeCount: 11);
    when(() => remoteDatasource.toggleLike('v1')).thenAnswer((_) async => liked);

    final result = await repository.toggleLike('v1');

    expect(result, liked);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/feed/data/feed_repository_test.dart`
Expected: FAIL — `FeedRepository` doesn't exist.

- [ ] **Step 5: Implement `FeedRepository`**

```dart
// lib/features/feed/data/feed_repository.dart
import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

class FeedRepository {
  FeedRepository(this._remoteDatasource);

  final FeedRemoteDatasource _remoteDatasource;

  Future<FeedPage> fetchFeed({String? cursor}) async {
    try {
      return await _remoteDatasource.fetchFeed(cursor: cursor);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> toggleLike(String videoId) async {
    try {
      return await _remoteDatasource.toggleLike(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<VideoModel> toggleSave(String videoId) async {
    try {
      return await _remoteDatasource.toggleSave(videoId);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
```

- [ ] **Step 6: Generate code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/feed/data/feed_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/features/feed/data test/features/feed/data
git commit -m "feat: add feed data layer (VideoModel, remote datasource, repository)"
```

---

## Task 13: Feed state — `FeedNotifier` (paginated)

**Files:**
- Create: `lib/features/feed/presentation/feed_provider.dart`
- Test: `test/features/feed/presentation/feed_provider_test.dart`

**Interfaces:**
- Consumes: `FeedRepository` (Task 12).
- Produces: `final feedRepositoryProvider = Provider<FeedRepository>(...)`, `@riverpod class FeedNotifier extends _$FeedNotifier { @override FutureOr<List<VideoModel>> build(); Future<void> loadMore(); Future<void> toggleLike(String videoId); Future<void> toggleSave(String videoId); }` exposed as `feedNotifierProvider`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/feed/presentation/feed_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository feedRepository;
  late ProviderContainer container;

  VideoModel makeVideo(String id) => VideoModel(
        id: id,
        url: 'https://example.com/$id.mp4',
        thumbnailUrl: 'https://example.com/$id.jpg',
        caption: 'caption $id',
        username: 'jane',
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLiked: false,
        isSaved: false,
      );

  setUp(() {
    feedRepository = MockFeedRepository();
    container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build() loads the first page', () async {
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v1')], nextCursor: 'c2'),
    );

    final result = await container.read(feedNotifierProvider.future);

    expect(result.map((v) => v.id), ['v1']);
  });

  test('loadMore() appends the next page using the stored cursor', () async {
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v1')], nextCursor: 'c2'),
    );
    when(() => feedRepository.fetchFeed(cursor: 'c2')).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v2')], nextCursor: null),
    );
    await container.read(feedNotifierProvider.future);

    await container.read(feedNotifierProvider.notifier).loadMore();

    final result = container.read(feedNotifierProvider).value!;
    expect(result.map((v) => v.id), ['v1', 'v2']);
  });

  test('toggleLike() replaces the updated video in place', () async {
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => FeedPage(items: [makeVideo('v1')], nextCursor: null),
    );
    await container.read(feedNotifierProvider.future);
    final liked = makeVideo('v1').copyWith(isLiked: true, likeCount: 1);
    when(() => feedRepository.toggleLike('v1')).thenAnswer((_) async => liked);

    await container.read(feedNotifierProvider.notifier).toggleLike('v1');

    final result = container.read(feedNotifierProvider).value!;
    expect(result.single.isLiked, isTrue);
    expect(result.single.likeCount, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/feed/presentation/feed_provider_test.dart`
Expected: FAIL — provider doesn't exist.

- [ ] **Step 3: Implement `FeedNotifier`**

```dart
// lib/features/feed/presentation/feed_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';

part 'feed_provider.g.dart';

@Riverpod(keepAlive: true)
FeedRepository feedRepository(FeedRepositoryRef ref) =>
    FeedRepository(FeedRemoteDatasource(ref.watch(apiClientProvider)));

@riverpod
class FeedNotifier extends _$FeedNotifier {
  String? _nextCursor;

  @override
  FutureOr<List<VideoModel>> build() async {
    final page = await ref.read(feedRepositoryProvider).fetchFeed();
    _nextCursor = page.nextCursor;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_nextCursor == null) return;
    final current = state.value ?? [];
    final page = await ref.read(feedRepositoryProvider).fetchFeed(cursor: _nextCursor);
    _nextCursor = page.nextCursor;
    state = AsyncData([...current, ...page.items]);
  }

  Future<void> toggleLike(String videoId) async {
    final updated = await ref.read(feedRepositoryProvider).toggleLike(videoId);
    _replace(updated);
  }

  Future<void> toggleSave(String videoId) async {
    final updated = await ref.read(feedRepositoryProvider).toggleSave(videoId);
    _replace(updated);
  }

  void _replace(VideoModel updated) {
    final current = state.value ?? [];
    state = AsyncData([
      for (final video in current)
        if (video.id == updated.id) updated else video,
    ]);
  }
}
```

- [ ] **Step 4: Generate code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/feed/presentation/feed_provider_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/feed/presentation/feed_provider.dart lib/features/feed/presentation/feed_provider.g.dart test/features/feed/presentation/feed_provider_test.dart
git commit -m "feat: add FeedNotifier with pagination and like/save toggles"
```

---

## Task 14: Feed UI — `VideoPlayerWidget`

**Files:**
- Create: `lib/features/feed/presentation/video_player_widget.dart`
- Test: `test/features/feed/presentation/video_player_widget_test.dart`

**Interfaces:**
- Produces: `class VideoPlayerWidget extends StatefulWidget { const VideoPlayerWidget({required this.url, required this.isActive}); final String url; final bool isActive; }` — plays when `isActive` is true, pauses otherwise; shows `LoadingView` until initialized.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/feed/presentation/video_player_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_player_widget.dart';

void main() {
  testWidgets('shows LoadingView before the video controller initializes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VideoPlayerWidget(
        url: 'https://example.com/does-not-load-in-tests.mp4',
        isActive: true,
      ),
    ));

    // Network video initialization never completes in the widget test
    // environment, so the widget must still show its loading state.
    expect(find.byType(LoadingView), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/feed/presentation/video_player_widget_test.dart`
Expected: FAIL — `VideoPlayerWidget` doesn't exist.

- [ ] **Step 3: Implement `VideoPlayerWidget`**

```dart
// lib/features/feed/presentation/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key, required this.url, required this.isActive});

  final String url;
  final bool isActive;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _syncPlayback();
      });
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _syncPlayback();
  }

  void _syncPlayback() {
    if (!_initialized) return;
    if (widget.isActive) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const LoadingView();
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/feed/presentation/video_player_widget_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/features/feed/presentation/video_player_widget.dart test/features/feed/presentation/video_player_widget_test.dart
git commit -m "feat: add VideoPlayerWidget with active-state-driven playback"
```

---

## Task 15: Comment data layer — `CommentModel`, `CommentRemoteDatasource`, `CommentRepository`

**Files:**
- Create: `lib/features/comment/data/comment_model.dart`
- Create: `lib/features/comment/data/comment_remote_datasource.dart`
- Create: `lib/features/comment/data/comment_repository.dart`
- Test: `test/features/comment/data/comment_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (Task 3), `AppException` (Task 2).
- Produces: `@freezed class CommentModel { factory CommentModel({required String id, required String videoId, required String userId, required String username, String? avatarUrl, required String text, required DateTime createdAt}) = _CommentModel; factory CommentModel.fromJson(...); }`.
- Produces: `class CommentPage { final List<CommentModel> items; final String? nextCursor; }`.
- Produces: `class CommentRepository { Future<CommentPage> fetchComments(String videoId, {String? cursor}); Future<CommentModel> postComment(String videoId, String text); }`.

- [ ] **Step 1: Define `CommentModel`**

```dart
// lib/features/comment/data/comment_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String id,
    required String videoId,
    required String userId,
    required String username,
    String? avatarUrl,
    required String text,
    required DateTime createdAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}
```

- [ ] **Step 2: Define `CommentRemoteDatasource`**

```dart
// lib/features/comment/data/comment_remote_datasource.dart
import 'package:tiktok_mobile/core/network/api_client.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';

class CommentPage {
  const CommentPage({required this.items, this.nextCursor});

  final List<CommentModel> items;
  final String? nextCursor;
}

class CommentRemoteDatasource {
  CommentRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<CommentPage> fetchComments(String videoId, {String? cursor}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/videos/$videoId/comments',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': 20,
      },
    );
    final body = response.data!['data'] as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CommentPage(items: items, nextCursor: body['nextCursor'] as String?);
  }

  Future<CommentModel> postComment(String videoId, String text) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/videos/$videoId/comments',
      data: {'text': text},
    );
    return CommentModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
```

- [ ] **Step 3: Write the failing test for `CommentRepository`**

```dart
// test/features/comment/data/comment_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';

class MockCommentRemoteDatasource extends Mock implements CommentRemoteDatasource {}

void main() {
  late MockCommentRemoteDatasource remoteDatasource;
  late CommentRepository repository;

  final comment = CommentModel(
    id: 'c1',
    videoId: 'v1',
    userId: 'u1',
    username: 'jane',
    text: 'nice video!',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    remoteDatasource = MockCommentRemoteDatasource();
    repository = CommentRepository(remoteDatasource);
  });

  test('fetchComments returns items and cursor', () async {
    when(() => remoteDatasource.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [comment], nextCursor: null),
    );

    final result = await repository.fetchComments('v1');

    expect(result.items, [comment]);
  });

  test('postComment converts a DioException into an AppException', () async {
    when(() => remoteDatasource.postComment('v1', '')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/videos/v1/comments'),
        response: Response(
          requestOptions: RequestOptions(path: '/videos/v1/comments'),
          statusCode: 500,
          data: {'error': {'message': 'empty comment'}},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(() => repository.postComment('v1', ''), throwsA(isA<ServerException>()));
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/comment/data/comment_repository_test.dart`
Expected: FAIL — `CommentRepository` doesn't exist.

- [ ] **Step 5: Implement `CommentRepository`**

```dart
// lib/features/comment/data/comment_repository.dart
import 'package:dio/dio.dart';
import 'package:tiktok_mobile/core/network/app_exception.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';

class CommentRepository {
  CommentRepository(this._remoteDatasource);

  final CommentRemoteDatasource _remoteDatasource;

  Future<CommentPage> fetchComments(String videoId, {String? cursor}) async {
    try {
      return await _remoteDatasource.fetchComments(videoId, cursor: cursor);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<CommentModel> postComment(String videoId, String text) async {
    try {
      return await _remoteDatasource.postComment(videoId, text);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}
```

- [ ] **Step 6: Generate code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/comment/data/comment_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/features/comment/data test/features/comment/data
git commit -m "feat: add comment data layer (CommentModel, remote datasource, repository)"
```

---

## Task 16: Comment state — `CommentNotifier` (family, paginated + post)

**Files:**
- Create: `lib/features/comment/presentation/comment_provider.dart`
- Test: `test/features/comment/presentation/comment_provider_test.dart`

**Interfaces:**
- Consumes: `CommentRepository` (Task 15).
- Produces: `final commentRepositoryProvider = Provider<CommentRepository>(...)`, `@riverpod class CommentNotifier extends _$CommentNotifier { @override FutureOr<List<CommentModel>> build(String videoId); Future<void> loadMore(); Future<void> postComment(String text); }` exposed as `commentNotifierProvider(videoId)` (family).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/comment/presentation/comment_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late MockCommentRepository commentRepository;
  late ProviderContainer container;

  CommentModel makeComment(String id) => CommentModel(
        id: id,
        videoId: 'v1',
        userId: 'u1',
        username: 'jane',
        text: 'comment $id',
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    commentRepository = MockCommentRepository();
    container = ProviderContainer(
      overrides: [commentRepositoryProvider.overrideWithValue(commentRepository)],
    );
  });

  tearDown(() => container.dispose());

  test('build(videoId) loads the first page for that video', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], nextCursor: null),
    );

    final result = await container.read(commentNotifierProvider('v1').future);

    expect(result.map((c) => c.id), ['c1']);
  });

  test('postComment() appends the new comment to the front', () async {
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [makeComment('c1')], nextCursor: null),
    );
    await container.read(commentNotifierProvider('v1').future);
    when(() => commentRepository.postComment('v1', 'new comment'))
        .thenAnswer((_) async => makeComment('c2'));

    await container.read(commentNotifierProvider('v1').notifier).postComment('new comment');

    final result = container.read(commentNotifierProvider('v1')).value!;
    expect(result.map((c) => c.id), ['c2', 'c1']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/comment/presentation/comment_provider_test.dart`
Expected: FAIL — provider doesn't exist.

- [ ] **Step 3: Implement `CommentNotifier`**

```dart
// lib/features/comment/presentation/comment_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';

part 'comment_provider.g.dart';

@Riverpod(keepAlive: true)
CommentRepository commentRepository(CommentRepositoryRef ref) =>
    CommentRepository(CommentRemoteDatasource(ref.watch(apiClientProvider)));

@riverpod
class CommentNotifier extends _$CommentNotifier {
  String? _nextCursor;

  @override
  FutureOr<List<CommentModel>> build(String videoId) async {
    final page = await ref.read(commentRepositoryProvider).fetchComments(videoId);
    _nextCursor = page.nextCursor;
    return page.items;
  }

  Future<void> loadMore() async {
    if (_nextCursor == null) return;
    final current = state.value ?? [];
    final page = await ref
        .read(commentRepositoryProvider)
        .fetchComments(videoId, cursor: _nextCursor);
    _nextCursor = page.nextCursor;
    state = AsyncData([...current, ...page.items]);
  }

  Future<void> postComment(String text) async {
    final created = await ref.read(commentRepositoryProvider).postComment(videoId, text);
    final current = state.value ?? [];
    state = AsyncData([created, ...current]);
  }
}
```

- [ ] **Step 4: Generate code and run tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/comment/presentation/comment_provider_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/comment/presentation/comment_provider.dart lib/features/comment/presentation/comment_provider.g.dart test/features/comment/presentation/comment_provider_test.dart
git commit -m "feat: add CommentNotifier family with pagination and post"
```

---

## Task 17: Comment UI — `CommentSheet`

**Files:**
- Create: `lib/features/comment/presentation/comment_sheet.dart`
- Test: `test/features/comment/presentation/comment_sheet_test.dart`

**Interfaces:**
- Consumes: `commentNotifierProvider(videoId)` (Task 16).
- Produces: `class CommentSheet extends ConsumerWidget { const CommentSheet({required this.videoId}); final String videoId; }` — scrollable list + text field + send button calling `postComment`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/comment/presentation/comment_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/comment/data/comment_model.dart';
import 'package:tiktok_mobile/features/comment/data/comment_repository.dart';
import 'package:tiktok_mobile/features/comment/data/comment_remote_datasource.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';

class MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  testWidgets('renders existing comments and posts a new one', (tester) async {
    final commentRepository = MockCommentRepository();
    final existing = CommentModel(
      id: 'c1',
      videoId: 'v1',
      userId: 'u1',
      username: 'jane',
      text: 'first comment',
      createdAt: DateTime(2026, 1, 1),
    );
    when(() => commentRepository.fetchComments('v1', cursor: null)).thenAnswer(
      (_) async => CommentPage(items: [existing], nextCursor: null),
    );
    when(() => commentRepository.postComment('v1', 'new one')).thenAnswer(
      (_) async => CommentModel(
        id: 'c2',
        videoId: 'v1',
        userId: 'u2',
        username: 'bob',
        text: 'new one',
        createdAt: DateTime(2026, 1, 2),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [commentRepositoryProvider.overrideWithValue(commentRepository)],
        child: const MaterialApp(home: Scaffold(body: CommentSheet(videoId: 'v1'))),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('first comment'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('comment_input_field')), 'new one');
    await tester.tap(find.byKey(const Key('comment_send_button')));
    await tester.pump();

    verify(() => commentRepository.postComment('v1', 'new one')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/comment/presentation/comment_sheet_test.dart`
Expected: FAIL — `CommentSheet` doesn't exist.

- [ ] **Step 3: Implement `CommentSheet`**

```dart
// lib/features/comment/presentation/comment_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_provider.dart';

class CommentSheet extends ConsumerStatefulWidget {
  const CommentSheet({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentNotifierProvider(widget.videoId));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Expanded(
              child: commentsState.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(message: error.toString()),
                data: (comments) => ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(comment.username),
                      subtitle: Text(comment.text),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('comment_input_field'),
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Add a comment...'),
                    ),
                  ),
                  IconButton(
                    key: const Key('comment_send_button'),
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      ref
                          .read(commentNotifierProvider(widget.videoId).notifier)
                          .postComment(text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/comment/presentation/comment_sheet_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/features/comment/presentation/comment_sheet.dart test/features/comment/presentation/comment_sheet_test.dart
git commit -m "feat: implement CommentSheet with list and post input"
```

---

## Task 18: Feed UI — `FeedScreen` (full implementation)

**Files:**
- Modify: `lib/features/feed/presentation/feed_screen.dart` (replace placeholder)
- Test: `test/features/feed/presentation/feed_screen_test.dart`

**Interfaces:**
- Consumes: `feedNotifierProvider` (Task 13), `VideoPlayerWidget` (Task 14), `CommentSheet` (Task 17 — already built by the time this task runs).
- Produces: real `FeedScreen` — vertical `PageView.builder` over `feedNotifierProvider`'s videos, overlay with like/comment/share/save buttons, `loadMore()` triggered when reaching the last two pages.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/feed/presentation/feed_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tiktok_mobile/features/feed/data/feed_repository.dart';
import 'package:tiktok_mobile/features/feed/data/feed_remote_datasource.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_screen.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  testWidgets('renders caption and like count for the first video', (tester) async {
    final feedRepository = MockFeedRepository();
    const video = VideoModel(
      id: 'v1',
      url: 'https://example.com/v1.mp4',
      thumbnailUrl: 'https://example.com/v1.jpg',
      caption: 'hello world',
      username: 'jane',
      likeCount: 5,
      commentCount: 0,
      shareCount: 0,
      isLiked: false,
      isSaved: false,
    );
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [video], nextCursor: null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('tapping like calls toggleLike on the repository', (tester) async {
    final feedRepository = MockFeedRepository();
    const video = VideoModel(
      id: 'v1',
      url: 'https://example.com/v1.mp4',
      thumbnailUrl: 'https://example.com/v1.jpg',
      caption: 'hello world',
      username: 'jane',
      likeCount: 5,
      commentCount: 0,
      shareCount: 0,
      isLiked: false,
      isSaved: false,
    );
    when(() => feedRepository.fetchFeed(cursor: null)).thenAnswer(
      (_) async => const FeedPage(items: [video], nextCursor: null),
    );
    when(() => feedRepository.toggleLike('v1')).thenAnswer(
      (_) async => video.copyWith(isLiked: true, likeCount: 6),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(feedRepository)],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('feed_like_button_v1')));
    await tester.pump();

    verify(() => feedRepository.toggleLike('v1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/feed/presentation/feed_screen_test.dart`
Expected: FAIL — placeholder `FeedScreen` renders none of this.

- [ ] **Step 3: Implement real `FeedScreen`**

```dart
// lib/features/feed/presentation/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/widgets/error_view.dart';
import 'package:tiktok_mobile/core/widgets/loading_view.dart';
import 'package:tiktok_mobile/features/comment/presentation/comment_sheet.dart';
import 'package:tiktok_mobile/features/feed/data/video_model.dart';
import 'package:tiktok_mobile/features/feed/presentation/feed_provider.dart';
import 'package:tiktok_mobile/features/feed/presentation/video_player_widget.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _pageController = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, List<VideoModel> videos) {
    setState(() => _activeIndex = index);
    if (index >= videos.length - 2) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedState.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(feedNotifierProvider),
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return const ErrorView(message: 'No videos yet');
          }
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) => _onPageChanged(index, videos),
            itemBuilder: (context, index) {
              final video = videos[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayerWidget(
                    url: video.url,
                    isActive: index == _activeIndex,
                  ),
                  Positioned(
                    left: 12,
                    right: 80,
                    bottom: 24,
                    child: Text(
                      video.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 24,
                    child: _ActionRail(video: video),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ActionRail extends ConsumerWidget {
  const _ActionRail({required this.video});

  final VideoModel video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        IconButton(
          key: Key('feed_like_button_${video.id}'),
          icon: Icon(
            video.isLiked ? Icons.favorite : Icons.favorite_border,
            color: video.isLiked ? Colors.red : Colors.white,
          ),
          onPressed: () => ref.read(feedNotifierProvider.notifier).toggleLike(video.id),
        ),
        Text('${video.likeCount}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        IconButton(
          key: Key('feed_comment_button_${video.id}'),
          icon: const Icon(Icons.comment, color: Colors.white),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CommentSheet(videoId: video.id),
          ),
        ),
        Text('${video.commentCount}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        IconButton(
          key: Key('feed_share_button_${video.id}'),
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {}, // share intent wiring is out of scope for this plan
        ),
        Text('${video.shareCount}', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        IconButton(
          key: Key('feed_save_button_${video.id}'),
          icon: Icon(
            video.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () => ref.read(feedNotifierProvider.notifier).toggleSave(video.id),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/feed/presentation/feed_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/feed/presentation/feed_screen.dart test/features/feed/presentation/feed_screen_test.dart
git commit -m "feat: implement FeedScreen with vertical paging and action rail"
```

---

## Task 19: Wire up `main.dart` and manual smoke test

**Files:**
- Modify: `lib/main.dart` (replace Flutter counter starter app)
- Test: none new (this task is integration wiring; covered by all prior unit/widget tests plus a manual run).

**Interfaces:**
- Consumes: `appRouterProvider` (Task 9), `AppTheme` (Task 5).

- [ ] **Step 1: Replace `main.dart`**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_mobile/core/router/app_router.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: TikTokMobileApp()));
}

class TikTokMobileApp extends ConsumerWidget {
  const TikTokMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'TikTok Mobile',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Delete the now-unused default counter widget test**

The starter `test/widget_test.dart` references the old counter app and will fail to compile
against the new `main.dart`. Remove it:

```bash
rm test/widget_test.dart
```

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: all tests across `core/`, `auth/`, `feed/`, and `comment/` PASS.

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 4: Manual smoke test**

Run: `flutter run -d <device> --dart-define=API_BASE_URL=http://localhost:8080`
Expected: app launches to `/login` (no backend running yet, so login will fail — that's expected;
the goal is confirming navigation, theming, and that no crash occurs on launch). Confirm tapping
"Don't have an account? Register" navigates to `/register`.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git rm test/widget_test.dart
git commit -m "feat: wire main.dart to router/theme and remove starter counter app"
```

---

## Self-Review Notes

- **Spec coverage:** architecture (Task 1), error handling (Task 2), network/realtime scaffold
  (Tasks 3–4), theme/shared widgets (Task 5), auth data+state+UI (Tasks 6–11), feed
  data+state+UI (Tasks 12–14, 18), comment data+state+UI (Tasks 15–17), main wiring + manual
  test (Task 19). Testing section of the spec is satisfied by a unit test in every data-layer
  task and a widget test in every presentation-layer task.
- **Ordering fixed during self-review:** `FeedScreen` (originally drafted before `CommentSheet`)
  imports `CommentSheet` directly. Reordered so Comment (Tasks 15–17) is fully built before
  `FeedScreen`'s real implementation (Task 18) — no forward references or stubs needed.
- **Type consistency checked:** `VideoModel`, `CommentModel`, `UserModel` field names/types match
  across every task that constructs or reads them (repository, provider, and widget tests all use
  the same field set defined in Tasks 6, 12, and 15).

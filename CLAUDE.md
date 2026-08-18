# Project Context: TikTok Mobile — Flutter Client

App Flutter cho [tiktok-backend](../tiktok-backend). Backend contract nằm ở `../tiktok-backend/docs/`;
khi API đổi, sửa datasource ở đây chứ không tự chế endpoint mới.

## 1. Tech Stack
- **Dart**: 3.10 (`environment.sdk: ^3.10.7`) — Flutter channel stable
- **State**: `flutter_riverpod` 2.6 + `riverpod_annotation` / `riverpod_generator` (codegen)
- **Routing**: `go_router` 14 — khai báo tập trung ở `lib/core/router/app_router.dart`
- **HTTP**: `dio` 5 — một `ApiClient` duy nhất, interceptor tự gắn Bearer + refresh token
- **Models**: `freezed` 2 + `json_serializable` 6 (sinh `.freezed.dart` / `.g.dart`)
- **Storage**: `flutter_secure_storage` cho token, `shared_preferences` cho preference thường
- **Media**: `video_player`, `cached_network_image`
- **Realtime**: `web_socket_channel` — `WebSocketService` đã có nhưng CHƯA feature nào dùng
- **Test**: `flutter_test`, `integration_test`, `mocktail`

## 2. Project Structure
```
lib/
├── main.dart                      # ProviderScope + mockOverrides() khi USE_MOCK=true
├── core/
│   ├── constants/env.dart         # API_BASE_URL, USE_MOCK — đọc qua String/bool.fromEnvironment
│   ├── network/
│   │   ├── api_client.dart        # Dio + TokenStorage interface + refresh interceptor
│   │   ├── api_response.dart      # Envelope {success, data, code, message, timestamp}
│   │   ├── page_response.dart     # {content, page, size, totalElements, last}
│   │   ├── app_exception.dart     # sealed AppException: Network/Server/Unauthorized/Unknown
│   │   ├── secure_token_storage.dart
│   │   └── websocket_service.dart
│   ├── router/app_router.dart     # GoRouter + redirect + _AuthStateListenable
│   ├── theme/app_theme.dart       # NowaColors — dark theme của app chính
│   ├── mock/mock_backend.dart     # Override repository bằng dữ liệu in-memory
│   ├── utils/
│   └── widgets/                   # design_system, nav_bar, action_rail, error_view, loading_view
└── features/
    ├── auth/      # options → email form → verify email → forgot/reset password
    ├── feed/      # For You feed, video player, video viewer, share sheet
    ├── comment/   # Comment sheet + phân trang
    ├── user/      # Profile, edit profile, follow/block/mute, user list
    ├── discover/  create/  inbox/   # Màn hình tab, phần lớn còn dữ liệu tĩnh
    └── shell/     # HomeShell — bottom nav 5 tab
```

## 3. Feature Structure (mỗi feature)
```
features/{feature}/
├── data/
│   ├── {feature}_remote_datasource.dart  # Chỉ gọi HTTP: path, query, parse ApiResponse/PageResponse
│   ├── {feature}_repository.dart         # try/catch DioException → AppException; API cho presentation
│   └── {x}_model.dart                    # @freezed + fromJson
└── presentation/
    ├── {feature}_provider.dart           # @riverpod / @Riverpod(keepAlive: true) → part '.g.dart'
    ├── {x}_screen.dart                   # ConsumerWidget / ConsumerStatefulWidget
    └── widgets/                          # Widget riêng của feature
```

## 4. Coding Conventions — BẮT BUỘC

### Layering
- `presentation → data → core`, một chiều. Screen/provider **KHÔNG** gọi thẳng datasource, luôn qua repository
- `core/` **KHÔNG BAO GIỜ** import `features/` — đó là lý do `ApiClient` tự gọi `/auth/refresh` bằng Dio thô thay vì dùng `AuthRemoteDatasource`
- Feature không import `presentation/` của feature khác; dùng chung thì đưa lên `core/widgets/`
- Import luôn dùng dạng package tuyệt đối: `package:tiktok_mobile/...`, không dùng `../..`

### Models
- `@freezed` + `factory _X.fromJson` — KHÔNG viết class DTO thủ công
- Enum từ server: `@JsonValue('PUBLISHED')` + luôn có nhánh `unknown` để giá trị mới không làm crash parse (xem `VideoStatus`)
- Sau khi sửa model/provider PHẢI chạy `dart run build_runner build --delete-conflicting-outputs`. KHÔNG sửa tay file `.g.dart` / `.freezed.dart`

### Networking
- Mọi request đi qua `ApiClient.dio`; base URL lấy từ `Env.apiBaseUrl`, KHÔNG hard-code host
- Response bọc trong `ApiResponse<T>`; danh sách bọc trong `PageResponse<T>` (offset paging: `page`, `size`, `last`)
- **Repository là ranh giới lỗi**: bắt `DioException`, ném lại `AppException.fromDioException(e)`. Lớp trên KHÔNG bao giờ thấy `DioException`
- Lỗi server đọc `code` (chuỗi máy đọc được, vd. `EMAIL_NOT_VERIFIED`) để map sang thông báo cho người dùng, đừng hiển thị `message` thô khi đã có nhánh xử lý riêng
- 401: interceptor tự refresh **một lần**, gộp các request 401 đồng thời vào cùng một lần gọi `/auth/refresh`. Đừng thêm logic retry ở repository nữa

### State (Riverpod)
- Dùng codegen: `@riverpod` cho state theo màn hình, `@Riverpod(keepAlive: true)` cho dependency dùng chung (`tokenStorage`, `apiClient`, các `*Repository`)
- Async state: `AsyncNotifier` + `AsyncValue.guard`, KHÔNG tự quản `isLoading`/`errorMessage` bằng `setState`
- UI đọc bằng `ref.watch(...)`, hành động (nút bấm) dùng `ref.read(...)`
- Auth: `authStateProvider` là nguồn sự thật duy nhất về đăng nhập. `register()` **không** nằm ở đây — đăng ký chưa tạo phiên (còn phải verify email), màn hình gọi thẳng `AuthRepository.register`

### Routing
- Thêm route: khai báo trong `app_router.dart`; nếu route mở được khi chưa đăng nhập thì thêm vào `_authRoutes` / `_guestRoutes`, nếu không redirect sẽ đá về `/login`
- Điều hướng bằng `context.go` / `context.push` với path chuỗi, KHÔNG `Navigator.push(MaterialPageRoute(...))`

### UI & Theme
- App chính: dark theme, màu lấy từ `NowaColors` (`core/theme/app_theme.dart`)
- Luồng auth: light theme riêng, màu lấy từ `AuthColors` và widget dùng chung trong `features/auth/presentation/widgets/auth_ui.dart` (`AuthScaffold`, `AuthField`, `AuthPrimaryButton`, `AuthOptionButton`)
- KHÔNG viết `Color(0xFF...)` rải rác trong screen — thêm token vào hai class màu trên
- Trạng thái tải/lỗi dùng `core/widgets/loading_view.dart` và `error_view.dart`

### Mock backend
- `--dart-define=USE_MOCK=true` → `mockOverrides()` thay các `*RepositoryProvider` bằng bản in-memory
- Thêm repository mới mà muốn chạy offline thì phải bổ sung override tương ứng trong `core/mock/mock_backend.dart`, đừng nhét dữ liệu giả vào code thật

## 5. Common Commands
```bash
flutter pub get                                            # Cài dependency
dart run build_runner build --delete-conflicting-outputs   # Sinh freezed/json/riverpod
dart run build_runner watch  --delete-conflicting-outputs  # Sinh liên tục khi dev

flutter run --dart-define=USE_MOCK=true                    # Chạy không cần backend
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1

flutter analyze                                            # Lint (flutter_lints)
flutter test                                               # Unit + widget
flutter test test/features/feed                            # Một thư mục
flutter test integration_test/auth_flow_test.dart \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1  # Cần backend thật + thiết bị
```

Android emulator gọi máy host bằng `10.0.2.2`, không phải `localhost`.

## 6. Key Rules — KHÔNG được vi phạm
- [ ] KHÔNG hard-code base URL / secret trong code — dùng `Env` + `--dart-define`
- [ ] KHÔNG lưu token ngoài `flutter_secure_storage`; KHÔNG log token, mật khẩu, OTP
- [ ] KHÔNG để `DioException` rò lên provider/UI — repository phải map sang `AppException`
- [ ] KHÔNG gọi datasource từ presentation
- [ ] KHÔNG sửa tay file sinh tự động (`*.g.dart`, `*.freezed.dart`)
- [ ] KHÔNG dùng `print` — bỏ debug log trước khi commit
- [ ] KHÔNG `Navigator.push` trực tiếp — đi qua go_router
- [ ] Widget list dài phải dùng `ListView.builder`/`PageView.builder`, không `Column` + `map`
- [ ] `dispose()` mọi `VideoPlayerController`, `TextEditingController`, `StreamSubscription`
- [ ] Sau `await` trong widget, kiểm tra `mounted` trước khi đụng `context`

## 7. Khi Claude sinh code — checklist
- [ ] Đặt file đúng `features/{feature}/{data|presentation}/`
- [ ] Model dùng `@freezed` + `fromJson`, enum có nhánh `unknown`
- [ ] Datasource chỉ HTTP; repository bọc lỗi; provider gọi repository
- [ ] Provider dùng `@riverpod` codegen, chạy `build_runner` sau khi thêm
- [ ] Route mới đã cập nhật `app_router.dart` (và whitelist nếu là route công khai)
- [ ] Màu/spacing lấy từ `NowaColors` hoặc `AuthColors`
- [ ] Có test tương ứng trong `test/` theo đúng đường dẫn gương của `lib/`
- [ ] `flutter analyze && flutter test` sạch trước khi báo xong

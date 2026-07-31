# TikTok Mobile — Foundation Architecture + Auth/Feed/Comment Module

Date: 2026-07-31

## Context

`tiktok_mobile` is a fresh Flutter project (`flutter create .`, unmodified) that will become a
TikTok-style app: video feed, like, comment, share, save, chat, e-commerce, notifications — all
real-time. This is too broad for one design, so this spec covers only:

1. The shared architectural foundation (used by every future feature).
2. The first vertical slice: **Auth**, **Feed**, **Comment** — enough to run a real app end to end.

Backend is a separate repo, being built in parallel (not ready yet). Chat, e-commerce,
notifications, and realtime like-counts are explicitly out of scope for this spec and will get
their own brainstorm/spec when built.

## Architecture

Feature-first organization. Each feature has two layers only (no separate domain layer —
chosen to reduce boilerplate; can be introduced later if a feature's business logic grows
complex enough to need it):

- `data/` — models (`freezed` + `json_serializable`), remote datasource (Dio calls), repository
  (returns models directly, converts network errors to `AppException`).
- `presentation/` — screens, widgets, Riverpod providers/notifiers (state via
  `riverpod_generator` codegen).

`core/` holds everything shared across features:

```
lib/
  core/
    network/        # ApiClient (Dio + interceptors), WebSocketService, api_response.dart, AppException
    router/         # go_router config + auth-based redirect guard
    di/             # global Riverpod providers/overrides
    theme/
    widgets/        # shared widgets (loaders, error views, buttons)
    utils/          # extensions, formatters
    constants/
  features/
    auth/
      data/
      presentation/
    feed/
      data/
      presentation/
    comment/
      data/
      presentation/
main.dart
```

Future features (chat, ecommerce, notification, save) follow the same `data/` + `presentation/`
pattern under `features/`.

## Dependencies

- State/DI: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
- Routing: `go_router`
- Network: `dio`, `web_socket_channel`
- Models: `freezed`, `json_serializable`, `build_runner`
- Video: `video_player` (+ manual preload of next video in feed `PageView`)
- Storage: `flutter_secure_storage` (auth token), `shared_preferences` (simple settings)
- Misc: `cached_network_image`, `flutter_lints`

## Networking & realtime layer

- `ApiClient`: Dio wrapper, base URL via `--dart-define` per environment (dev/staging/prod),
  interceptors for: attaching access token, refreshing token on 401, debug-only logging.
- `WebSocketService`: single shared connection, exposes per-channel `Stream`s (e.g.
  `feed_updates`, `chat:<id>`, `notifications`), auto-reconnect with backoff. Not wired to any
  feature yet in this spec — added when chat/notifications/realtime feed updates are built.
- Response/error envelope (`core/network/api_response.dart`) is a provisional REST shape since
  the backend isn't finalized yet; expected to be adjusted once the backend contract is fixed.

## Error handling

All network/repository errors are converted to `AppException` (network / server / unauthorized /
unknown) in `core/utils`. Presentation layer consumes state via Riverpod `AsyncValue`
(loading/error/data), no manual try/catch duplication in widgets.

## Routing

`go_router` with named routes (`/login`, `/register`, `/feed`). A redirect guard checks
`authStateProvider` — unauthenticated users are sent to `/login`.

## Feature scope: Auth

- Login and Register screens (email/password only — no social login/OTP in this slice).
- Token persisted via `flutter_secure_storage`.
- `authStateProvider` drives router redirect.

## Feature scope: Feed

- `FeedScreen`: vertical full-screen `PageView`, one video per page.
- `VideoPlayerWidget`: plays/pauses based on current page, preloads the next video.
- Right-side overlay: like, comment (opens comment sheet), share, save buttons — wired to API
  calls. No product tagging (e-commerce) yet.
- Pagination via REST cursor (`GET /feed?cursor=...`).
- No realtime like-count updates yet (would require `WebSocketService` wiring — future work).

## Feature scope: Comment

- Bottom sheet triggered from Feed's comment button.
- Paginated comment list (`GET /videos/:id/comments`) + text input to post a new comment
  (`POST /videos/:id/comments`).
- Same `data/` + `presentation/` structure as other features.

## Testing

- Unit tests for repositories (Dio mocked).
- Basic widget tests for Login screen and Feed screen skeleton (renders, navigates on success).

## Explicitly out of scope (future specs)

Chat, e-commerce (product tagging/checkout), push notifications, save/favorites list screen,
realtime like-count via WebSocket, social login, video upload/creation flow.

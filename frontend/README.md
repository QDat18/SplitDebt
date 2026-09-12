# SplitDebt Flutter frontend

Ứng dụng Flutter gọi trực tiếp Spring Boot REST API và lưu phiên JWT cục bộ bằng `shared_preferences`.

## Chạy local

1. Cài Flutter SDK phù hợp với `pubspec.yaml`.
2. Chạy `flutter pub get`.
3. Android Emulator có thể chạy trực tiếp bằng `flutter run`; API mặc định là `http://10.0.2.2:8080/api`.
4. Với điện thoại thật, truyền IP LAN của máy chạy backend, ví dụ:

```bash
flutter run --dart-define=API_URL=http://192.168.1.10:8080/api
```

Flutter desktop/web trên cùng máy backend có thể dùng:

```bash
flutter run --dart-define=API_URL=http://localhost:8080/api
```

Không cần Supabase Auth hoặc `config.json`. Xem thêm [SETUP](../docs/SETUP.md), [DESIGN_SYSTEM](../docs/DESIGN_SYSTEM.md), [VALIDATION](../docs/VALIDATION.md).


## Google Sign-In

```bash
flutter run -d chrome --web-port=5000 --dart-define=API_URL=http://localhost:8080/api --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```

Chi tiết Google Cloud, Android OAuth Client và quên mật khẩu: [AUTH_GOOGLE_PASSWORD_RESET](../docs/AUTH_GOOGLE_PASSWORD_RESET.md).

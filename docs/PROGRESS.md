# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr`; `external/holdout` 15 `uit_mlreceipts`):** Hoàn tất (labeled sau tinh chỉnh: `13/15` total, `37/38` item; holdout: `11/15` total, `34/59` item).
- **Privacy Consent Task 1–4, Task 6 & Review vòng 1 (P1–P3, Task 5 đã huỷ):** Hoàn tất (`purgeGroup` khi xoá tài khoản chủ duy nhất, 400 `WRONG_PASSWORD`, chuẩn hoá `platform`/`appVersion`; `.\mvnw.cmd test`: 101 passed).

- **Privacy Consent Task 1–9 & Review vòng 1–2 (P1–P3, A1–A2, Task 5 đã huỷ) hoàn tất:** `.\mvnw.cmd test` 101 passed; `flutter analyze` 0 error; `flutter test -j 1` 248 passed, 1 skipped (`holdout`); `RECEIPT_AI|DeepSeek` 0 kết quả.
- **Group Chat Review (C1–C5) hoàn tất:** khởi tạo `lastReadMessageId` cho thành viên mới, fallback `loadInitial()` khi `refreshNewer` lỗi rỗng, giới hạn 2000 ký tự + `rejected` trên HTTP 400, trạng thái `removed` trên HTTP 403, đọc lại ngoài transaction khi `DataIntegrityViolationException`; `.\mvnw.cmd test` 103 passed, `flutter analyze` 0 error (54 info/warning có sẵn), `flutter test -j 1` 256 passed, 1 skipped (`holdout`).
- **Group Chat Review vòng 1 (G1) hoàn tất:** thêm `@EntityGraph(attributePaths = {"sender", "group"})` cho `findBySenderIdAndClientMessageId` + `GroupChatNoTxTest` (không `@Transactional`); `.\mvnw.cmd test` 105 passed.
- **Chat Adaptive Polling (T1–T3) hoàn tất:** `chat_poll_policy.dart` (1s trong 30s hoạt động, 5s khi im lặng/lỗi), `RefreshResult` từ `refreshNewer`, timer tự lên lịch duy nhất trong `GroupChatScreen`; `flutter analyze` 0 error (54 info/warning có sẵn), `flutter test -j 1` 264 passed, 1 skipped (`holdout`).
- **Android Release APK (A1–A5) hoàn tất:** đổi Application ID thành `vn.hvnh.splitdebt`, cấu hình ký release (fallback khoá debug + `key.properties.example`), `android:label="SplitDebt"` + `app_version_test.dart`, `proguard-rules.pro` cho ML Kit, `tool/build_apk.ps1`, `docs/android-release.md`; `flutter analyze` 0 error, `flutter test -j 1` 265 passed, 1 skipped (`holdout`), `.\tool\build_apk.ps1 -ApiBaseUrl https://example.com/api` build thành công `app-release.apk` (85.58 MB).
- **Backend Deploy (D1–D6) hoàn tất:** `application.yaml` + `.env.example`, `api/Dockerfile` + `.dockerignore`, `render.yaml`, `api/tool/smoke_deploy.ps1`, `server_warmup.dart` + thông báo timeout thân thiện, `docs/backend-deploy.md`; `.\mvnw.cmd test` 105 passed, `flutter analyze` 0 error, `flutter test -j 1` 269 passed, 1 skipped (`holdout`). `docker build` / chạy container + `smoke_deploy.ps1`: **chưa chạy** (Docker Desktop daemon chưa bật).

## In progress
- Chưa thực hiện được kiểm thử thủ công trên `Pixel_8a` (máy ảo không lên `adb` trong phiên chạy nền) và chưa chạy thử `docker build` / `smoke_deploy.ps1` (Docker Desktop daemon chưa bật).

## Next
- Chủ dự án bật Docker Desktop để kiểm tra `docker build -t splitdebt-api api` + `smoke_deploy.ps1`, deploy Render theo `docs/backend-deploy.md`, thêm app Android `vn.hvnh.splitdebt` vào Firebase + cập nhật `FIREBASE_ANDROID_APP_ID` trong `.env`, tạo `.jks`/`key.properties` theo `docs/android-release.md`, kiểm thử thủ công trên `Pixel_8a` và điền `[CẦN ĐIỀN]` trong `docs/legal/`.

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS; `GroupServiceImpl.deleteGroup` có lỗi khoá ngoại từ trước khi nhóm có khoản chi (ngoài phạm vi plan).

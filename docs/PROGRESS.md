# SplitDebt Progress Tracking

- **Status**: Hoàn thành sửa lỗi post-login/QR/FCM, chuyển đổi ngôn ngữ VI/EN và lập plan OCR.
- **Done**:
  - Sửa `DashboardScreen` (`valueOrNull`) + invalidate `userGroupsProvider` khi đăng nhập; sửa `FcmTokenService` chống lỗi trùng token; sửa `GroupInviteDialog` hết tràn màn hình ngang.
  - Sửa `joinGroupByInviteCode` (backend + `JoinGroupDialog`) báo đúng khi đã ở trong nhóm.
  - Tính năng đa ngôn ngữ Tiếng Việt / English (`LocaleNotifier`, `AppLocaleScope`, `LanguageSettingsScreen`, `ProfileScreen`, `MainLayoutScreen`, `DashboardScreen`, `GroupsScreen`, `GroupChatScreen`, `HistoryScreen`).
  - Lập kế hoạch OCR tại `docs/superpowers/plans/2026-11-25-receipt-ocr.md`.
- **Verification**:
  - Backend: 72/72 tests passed (`mvnw test`).
  - Frontend: 67/67 tests passed (`flutter test`).
- **In progress**: Chờ chốt phương án OCR (không dùng DeepSeek / API key trả phí).
- **Next**: Cập nhật plan OCR sang ML Kit + Rule-based Parser (nếu được duyệt) và triển khai.
- **Blockers**: Không có.

# Review vòng 1: Deploy backend (D1–D6)

Claude Code review `9353fca..c22541a`. Áp dụng Global Constraints của `2026-11-27-backend-deploy.md`. Đây là **vòng 1 trên tối đa 3**.

**Đã kiểm tra, đạt:**
- D1: Claude Code chạy backend với `PORT=8091` (H2, profile test), server nghe đúng cổng 8091.
- D2: `Dockerfile` và `.dockerignore` đúng plan. Chưa build được vì Docker daemon chưa bật.
- D3: `render.yaml` không có secret.
- D5: warm-up và thông báo timeout đúng plan, có test.
- D6: tài liệu đủ các mục.

## R1. `smoke_deploy.ps1` đăng ký luôn lỗi 400 (phải sửa)

Script gửi `consents.accepted = true`. Nhưng `RegisterConsentsDto` dùng trường **`ageConfirmed`**, và `ConsentService` từ chối nếu `ageConfirmed` khác `true`.

Claude Code chạy script với backend local: bước `/health` PASS, bước đăng ký **400 Bad Request**. Khi đổi thành `ageConfirmed = $true` (bản thử nằm ngoài repo), cả 4 bước đều PASS: health, đăng ký và đăng nhập, nhóm và chat, xoá tài khoản.

**Sửa:**
- Trong `api/tool/smoke_deploy.ps1`, đổi `accepted = $true` thành `ageConfirmed = $true`.
- Thêm `exit 0` ở cuối khi mọi bước PASS, để mã thoát rõ ràng.

## R2. Lệnh tạo `JWT_SECRET` dùng bộ sinh số không an toàn (nên sửa)

`docs/backend-deploy.md` dòng 14 dùng `Get-Random`, vốn không phải bộ sinh số dùng cho mật mã. Thay bằng:
```powershell
$b = New-Object byte[] 48; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)
```
Sửa cùng chỗ đó trong plan gốc nếu có.

## Kiểm tra cuối

- Chạy backend local với H2: `cd api; $env:PORT=8091; .\mvnw.cmd spring-boot:run "-Dspring-boot.run.useTestClasspath=true" "-Dspring-boot.run.profiles=test"`. Ở cửa sổ khác chạy `.\api\tool\smoke_deploy.ps1 -BaseUrl http://localhost:8091/api`: 4 dòng PASS, mã thoát 0.
- Một commit. Cập nhật `docs/PROGRESS.md`. Không push.

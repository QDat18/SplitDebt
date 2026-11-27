Bạn là người triển khai cho dự án SplitDebt (backend Spring Boot trong `api/`, app Flutter trong `frontend/`), branch `dev2-dat`.

Việc cần làm: thực hiện đúng kế hoạch trong `docs/superpowers/plans/2026-11-24-review-fixes.md`.

Trước khi bắt đầu:
1. Đọc `docs/PROGRESS.md`, sau đó đọc toàn bộ file kế hoạch, kể cả các mục "Bối cảnh", "Global Constraints" và "Review Focus".
2. Dùng skill superpowers:executing-plans nếu có.

Cách làm:
- Làm lần lượt Task 1 → Task 6. Chỉ làm Task 7 khi tôi đồng ý.
- Mỗi task làm theo TDD đúng thứ tự trong plan: viết test → chạy để thấy FAIL → sửa code → chạy để thấy PASS → commit. Đánh dấu `- [x]` vào plan khi xong từng bước.
- Chỉ làm những gì plan ghi. Không refactor thêm, không thêm dependency, không đổi API ngoài phạm vi plan.
- Gặp chỗ plan mơ hồ, sai so với code thật, hoặc lệnh grep kiểm tra ra kết quả khác kỳ vọng: DỪNG lại và hỏi tôi, đừng tự đoán.
- Không đọc, không sửa, không commit bất kỳ file `.env` nào. Không đọc `node_modules`, `target`, `build`, lockfile.
- Không push, không tạo PR.

Kiểm tra:
- Backend: `cd api; .\mvnw.cmd test`
- Frontend: `cd frontend; flutter analyze; flutter test`
- Chỉ được báo "xong" khi đã chạy các lệnh trên và thấy PASS. Kèm output tóm tắt (số test pass/fail, số error của analyze).

Sau mỗi task: cập nhật `docs/PROGRESS.md` (tối đa ~30 dòng: Done / In progress (file nào) / Next / Blockers) để Claude Code có thể tiếp tục review.

Khi xong Task 6, báo lại cho tôi:
- danh sách commit,
- kết quả test,
- những gì bạn phải hỏi hoặc làm khác plan.

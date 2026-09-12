# SplitDebt UX + business rules update — 2026-09-12

- New expenses default to the group owner as payer; new-expense payer selection is locked in the UI.
- New expense participants default to the remaining group members, so the owner pays the total and the members receive their allocated shares.
- Settlement wording is user-centric: amount I need to pay, amount I will receive, amount I already paid, amount I collected.
- Expense/history cards identify group, expense, payer and time.
- Opening the notification bell marks all notifications as read; there is no per-item acknowledgement flow.
- Main navigation is unified to 6 destinations: Tổng quan, Nhóm, Thanh toán, Lịch sử, Thống kê, Cá nhân. The center + button remains a quick action.
- Dashboard uses tighter responsive spacing and adaptive debt cards for narrow phone widths.
- Statistics filters are Ngày / Tháng / Năm. The API returns `mySpent`, and the UI prioritizes “Mình đã chi”.

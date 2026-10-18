# Contributing Guide — TrekGuard AI

## 🌿 Branch Strategy

```
main          ← Production-ready, protected (PR only)
develop       ← Integration branch (merge feature here first)
feature/*     ← New features  (e.g. feature/first-aid-bloc)
fix/*         ← Bug fixes     (e.g. fix/gps-permission-crash)
chore/*       ← Setup, CI, docs (e.g. chore/add-fastlane)
```

**Rule:** Never push directly to `main`. Always create a PR from `develop → main`.

---

## 📝 Commit Message Format (Conventional Commits)

```
<type>(<scope>): <short description>

Types:
  feat     — Tính năng mới
  fix      — Sửa bug
  chore    — Cấu hình, CI/CD, dependencies
  docs     — Tài liệu
  test     — Thêm/sửa tests
  refactor — Tái cấu trúc code
  style    — Format, lint (không thay đổi logic)

Scopes:
  first-aid, navigation, trail, ai-assistant, auth,
  core, database, ci, theme, router

Examples:
  feat(first-aid): add TFLite inference for symptom prediction
  fix(navigation): fix GPS permission crash on Android 14
  chore(ci): add GitHub Actions flutter test workflow
  test(first-aid): add unit tests for PredictFirstAidUseCase
```

---

## 🏗️ Clean Architecture Rules

1. **Domain layer** không được import Flutter widgets, BLoC, hoặc bất kỳ package UI nào
2. **Data layer** implement các Repository interface từ Domain
3. **Presentation layer** chỉ được giao tiếp với Domain thông qua Use Cases
4. Mọi Use Case đều phải có unit test tương ứng

---

## 📐 Code Style

- Sử dụng `flutter format` trước khi commit
- Chạy `flutter analyze` và fix tất cả warnings
- Tối đa 80 ký tự mỗi dòng (có thể dài hơn cho URLs)
- Đặt tên biến/method theo camelCase, class theo PascalCase
- Prefix private members với `_`

---

## 🔀 Pull Request Process

1. Tạo branch từ `develop`: `git checkout -b feature/your-feature develop`
2. Implement tính năng + viết tests
3. Chạy `flutter test` — đảm bảo tất cả tests pass
4. Chạy `flutter analyze` — không còn lỗi nào
5. Push và tạo PR lên `develop`
6. Tag người review (Leader phải review trước khi merge)

---

## 📋 Task Assignment

| Member | Phạm vi | Label GitHub |
|--------|---------|--------------|
| Leader | core/, CI/CD, integration | `core`, `ci` |
| Member 2 | AI, FastAPI backend | `ai`, `backend` |
| Member 3 | UI, Maps | `ui`, `maps` |

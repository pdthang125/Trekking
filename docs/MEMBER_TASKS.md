# 📋 DANH SÁCH CÔNG VIỆC CHI TIẾT 3 THÀNH VIÊN (SPRINT 7 TUẦN)

> **Dự án:** TrekGuard AI — Capstone Project VKU  
> **Repository:** https://github.com/pdthang125/Trekking  
> **Thời gian:** 7 Tuần tăng tốc

---

## 👑 Danh sách việc Member 1 (Leader / Mobile Engine Architect)

### Tuần 1 — Kiến trúc & Nền tảng (✅ ĐÃ HOÀN THÀNH)
- [x] Khởi tạo Clean Architecture 3 lớp chuẩn Flutter
- [x] Cấu hình Drift SQLite 4 bảng (`FirstAidGuides`, `TrackPoints`, `OfflineWaypoints`, `SyncQueue`)
- [x] Cấu hình BLoC State Management & GoRouter 5 tab
- [x] Cấu hình Android Permissions (Foreground Service, GPS, Mic, Wakelock)
- [x] Đẩy mã nguồn lên GitHub (`main` & `develop`)

### Tuần 2 — Code Generation & Dart Tokenizer
- [ ] Chạy `dart run build_runner build --delete-conflicting-outputs` sinh Drift DB & DI
- [ ] Viết `TfliteTokenizer` bằng Dart thuần để tách từ, padding câu tiếng Việt cho model AI
- [ ] Thiết lập biến môi trường `.env` kết nối Supabase Cloud

### Tuần 3 — TFLite On-Device Engine & Audio
- [ ] Nhận model `.tflite` từ Member 2, cấu hình `tflite_flutter`
- [ ] Viết bộ nạp Tensor, chạy suy luận Offline và map kết quả vào `FirstAidBlocHandler`
- [ ] Tích hợp Micro (Speech-to-Text) và Loa (Text-to-Speech đọc to hướng dẫn sơ cứu)

### Tuần 4 — Offline Map Tile Caching Engine
- [ ] Viết module tải và lưu cache gạch bản đồ OpenStreetMap vào bộ nhớ trong
- [ ] Xử lý tải gạch theo Bounding Box địa lý và xoá cache cũ khi vượt 500MB

### Tuần 5 — Background GPS & Thuật toán lọc nhiễu
- [ ] Cấu hình Foreground Service định vị liên tục khi tắt màn hình
- [ ] Viết bộ lọc nhiễu GPS (Kalman/Distance filter) giảm trôi toạ độ và tiết kiệm pin

### Tuần 6 — Hardware SOS & Auto Sync
- [ ] Điều khiển đèn Flash nháy mã Morse SOS (`... --- ...`) và còi hú cứu nạn
- [ ] Kiểm thử `SyncService` tự động đồng bộ toạ độ lên Supabase khi phát hiện sóng 4G

### Tuần 7 — Release & Tổng duyệt
- [ ] Đóng gói Release APK signed qua Fastlane
- [ ] Nghiệm thu toàn bộ tính năng trong chế độ máy bay (100% Airplane Mode)
- [ ] Hoàn thiện báo cáo kỹ thuật và chủ trì buổi thuyết trình bảo vệ Capstone

---

## 🧠 Danh sách việc Member 2 (AI & Backend Specialist)

### Tuần 1–2 — Dataset & Model Training
- [ ] Clone repo: `git clone https://github.com/pdthang125/Trekking.git`
- [ ] Cài Python: `pip install torch transformers datasets scikit-learn tensorflow`
- [ ] Thu thập 150+ mẫu triệu chứng dã ngoại (tiếng Việt & Anh) vào `assets/data/first_aid_dataset.json`
- [ ] Chạy `docs/ai_pipeline/pipeline_guide.py` huấn luyện mô hình phân loại Intent (Accuracy ≥ 85%)
- [ ] Lượng tử hóa sang INT8 `.tflite` (< 20MB)
- [ ] Bàn giao `first_aid_model.tflite`, `labels.txt`, `vocab.txt` cho Member 1

### Tuần 3–4 — Supabase PostGIS & Elevation API
- [ ] Khởi tạo Supabase Cloud, chạy `docs/supabase/schema.sql` bật PostGIS
- [ ] Cấu hình Row Level Security (RLS) bảo mật dữ liệu cá nhân
- [ ] Viết hàm gọi Open-Elevation API / OpenTopography lấy độ cao địa hình
- [ ] Mở rộng cẩm nang từ 4 lên 15+ bệnh lý sơ cứu chuyên sâu

### Tuần 5–6 — Benchmark AI & Báo cáo
- [ ] Đo đạc độ trễ suy luận AI trên máy Android thật (Latency < 150ms)
- [ ] Tinh chỉnh cấu hình nhận diện giọng nói tiếng Việt
- [ ] Stress test database Supabase khi nhận hàng loạt toạ độ GPS
- [ ] Viết chương báo cáo: *"Kiến trúc mô hình On-Device AI và kỹ thuật lượng tử hoá"*

### Tuần 7 — Phản biện Hội đồng
- [ ] Chuẩn bị bảng số liệu so sánh mô hình gốc vs bản quantize INT8 để phản biện

---

## 🎨 Danh sách việc Member 3 (UI/UX & Offline Maps)

### Tuần 1–2 — Figma & Navigation UI
- [ ] Clone repo: `git clone https://github.com/pdthang125/Trekking.git`
- [ ] Tạo Figma project — design system chuẩn Material 3 High Contrast (nút tối thiểu 48x48dp)
- [ ] Wireframe 5 màn hình chính, share link Figma vào `README.md`
- [ ] Cải thiện `navigation_page.dart`: Nút căn giữa GPS, chọn lớp bản đồ
- [ ] Tích hợp Widget la bàn số xoay theo cảm biến máy (`compass_widget.dart`)

### Tuần 3–4 — Waypoint & Altitude Chart
- [ ] Popup tạo Waypoint: Nhập tên, chọn icon (💧 Nguồn nước, ⛺ Cắm trại, ⚠️ Nguy hiểm) kèm chụp ảnh
- [ ] Tuỳ biến hiển thị Marker sinh động trên bản đồ
- [ ] Dùng `fl_chart` vẽ biểu đồ trắc diện độ cao trong `trail_page.dart`
- [ ] Hiển thị thẻ tóm tắt: Độ cao cực đại (Max Peak), độ dốc trung bình, tổng leo dốc

### Tuần 5–6 — Màn hình SOS & Poster VKU
- [ ] Giao diện SOS khẩn cấp: Giữ nút 3 giây có vòng tròn đếm ngược
- [ ] Hoạt ảnh (Animations) minh hoạ từng bước xử lý vết thương trong `first_aid_detail_page.dart`
- [ ] Tinh chỉnh giao diện Dark Mode chuẩn OLED, thêm Shimmer loading skeleton
- [ ] Thiết kế Slide thuyết trình chuyên nghiệp và Poster A0 chuẩn nhận diện VKU

### Tuần 7 — Trình chiếu & Demo Sản phẩm
- [ ] Nạp bản APK Release vào điện thoại thật
- [ ] Cầm máy điều khiển thao tác trực tiếp kịch bản Demo mượt mà trong buổi bảo vệ

---

## 🌿 Quy tắc làm việc trên Git
```bash
git checkout develop
git pull origin develop
git checkout -b feature/ten-tinh-nang
# Làm việc & commit theo chuẩn:
git commit -m "feat(module): nội dung tính năng"
git push origin feature/ten-tinh-nang
# Tạo Pull Request vào nhánh develop để Leader review
```

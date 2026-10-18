# 🏔️ TrekGuard AI — Kế Hoạch Dự Án & Chi Tiết Kiến Trúc Toàn Diện
> **Đề tài Capstone:** Hệ thống hỗ trợ Trekking tích hợp AI On-Device sơ cứu khẩn cấp và định vị bản đồ ngoại tuyến  
> **Đơn vị:** Khoa Khoa học Máy tính — Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU)  
> **Giảng viên hướng dẫn:** TS. Nguyễn Thanh Tuấn  
> **Mã nguồn GitHub:** [https://github.com/pdthang125/Trekking](https://github.com/pdthang125/Trekking)  
> **Thời lượng thực hiện:** 7 Tuần Tăng Tốc (Tuần 1 — Tuần 7 Bảo Vệ)
> **Chiến lược phân bổ:** Member 1 (Leader) trực tiếp nắm giữ 4 lõi kỹ thuật khó nhất trên Mobile (TFLite Inference Engine, Background GPS Engine, Offline Map Tile Caching, Hardware SOS Controller).

---

## PHẦN 1: GIẢI THÍCH CHI TIẾT NHỮNG GÌ ĐÃ CÓ TRONG PROJECT

Dự án đã được khởi tạo hoàn chỉnh theo mô hình **Clean Architecture 3 lớp chuẩn công nghiệp**, giải quyết bài toán cốt lõi: **100% Offline-First** (hoạt động hoàn toàn không cần sóng di động giữa rừng núi).

```
                      ┌────────────────────────────────────────┐
                      │          PRESENTATION LAYER            │
                      │  BLoC (State Management) + UI Pages   │
                      └──────────────────┬─────────────────────┘
                                         │ Calls UseCases
                                         ▼
                      ┌────────────────────────────────────────┐
                      │             DOMAIN LAYER               │
                      │    Entities + Repository Interfaces    │
                      │          (Pure Dart, No DB/UI)         │
                      └──────────────────▲─────────────────────┘
                                         │ Implements Interfaces
                                         │
                      ┌──────────────────┴─────────────────────┐
                      │              DATA LAYER                │
                      │   Repositories Impl + DataSources      │
                      │  [Local: Drift SQLite]  [Remote: PostGIS]│
                      └────────────────────────────────────────┘
```

---

### 1.1. Tầng Hạ Tầng Cốt Lõi (`lib/core/`)

* **Cơ sở dữ liệu nội địa (`lib/core/database/app_database.dart`)**:
  * Sử dụng thư viện **Drift (SQLite)** tối ưu cho Flutter.
  * Đã định nghĩa 4 bảng dữ liệu hoạt động ngoại tuyến:
    1. `FirstAidGuides`: Lưu trữ hướng dẫn sơ cứu, các bước xử lý khẩn cấp, độ nguy cấp (`emergency`, `urgent`, `moderate`), tài nguyên media.
    2. `TrackPoints`: Ghi lại lộ trình GPS theo thời gian thực (vĩ độ, kinh độ, độ cao, vận tốc, độ chính xác).
    3. `OfflineWaypoints`: Đánh dấu điểm mốc quan trọng (nguồn nước, trạm cứu hộ, điểm cắm trại, vị trí nguy hiểm).
    4. `SyncQueue`: Hàng đợi dữ liệu để tự động đồng bộ lên đám mây khi điện thoại bắt lại được sóng 4G/Wifi.

* **Cơ chế đồng bộ thông minh (`lib/core/network/sync_service.dart`)**:
  * Tự động lắng nghe trạng thái kết nối mạng qua `connectivity_plus`.
  * Khi người dùng từ rừng ra vùng có mạng, service kích hoạt đẩy toàn bộ GPS tracks và waypoints chưa đồng bộ lên Supabase PostGIS mà không làm gián đoạn trải nghiệm người dùng.

* **Định tuyến ứng dụng (`lib/core/router/app_router.dart`)**:
  * Sử dụng **GoRouter** với 5 tab điều hướng chính:
    1. `/home`: Bảng điều khiển tổng quan, nút kích hoạt SOS khẩn cấp, tóm tắt chuyến đi.
    2. `/first-aid`: Tra cứu & chẩn đoán sơ cứu khẩn cấp.
    3. `/navigation`: Bản đồ ngoại tuyến và ghi nhận lộ trình GPS.
    4. `/trail`: Phân tích cung đường và đồ thị độ cao (Altitude Profile).
    5. `/assistant`: Trợ lý AI cứu sinh và lập kế hoạch dã ngoại.
  * Tích hợp route `/auth` với `AuthGuard` bảo vệ quyền truy cập tài khoản.

* **Hệ thống giao diện dã ngoại (`lib/core/theme/app_theme.dart`)**:
  * Thiết kế theo chuẩn **Material 3 High-Contrast Outdoor Theme**:
    * **Forest Green (`#1B4D3E`)**: Màu chủ đạo gần gũi thiên nhiên.
    * **Safety Orange (`#FF6F00`)**: Màu cảnh báo cứu nạn, dễ nhận biết dưới ánh nắng chói gắt.
    * **Dark Charcoal (`#121B18`)**: Chế độ nền tối tiết kiệm pin tối đa cho màn hình OLED khi đi rừng dài ngày.

* **Quản trị lỗi & Thất bại (`lib/core/error/failures.dart`)**:
  * Định nghĩa hệ thống `Failure` chuẩn hóa (`ServerFailure`, `CacheFailure`, `LocationFailure`, `ModelInferenceFailure`, `AuthFailure`).

---

### 1.2. Tính Năng Sơ Cứu Khẩn Cấp (`lib/features/first_aid/`)

* **Tầng Domain (`domain/`)**:
  * Thực thể `FirstAidGuide`, `FirstAidStep`, `FirstAidMedia`.
  * Hợp đồng `FirstAidRepository`.
  * 3 UseCases: `GetGuidesBySymptomUseCase`, `GetAllGuidesUseCase`, `GetGuideByIdUseCase`.
* **Tầng Data (`data/`)**:
  * `FirstAidLocalDatasource`: Đọc từ SQLite và tự động nạp dữ liệu mồi từ file JSON nếu DB trống.
  * `FirstAidRemoteDatasource`: Truy vấn cập nhật cẩm nang mới từ Supabase.
  * `FirstAidRepositoryImpl`: Chiến lược ưu tiên Offline trước.
* **Tầng Presentation (`presentation/`)**:
  * `FirstAidBloc` & `FirstAidBlocHandler`: Quản lý trạng thái tìm kiếm, lọc theo triệu chứng, xử lý giọng nói Text-to-Speech (TTS).
  * `FirstAidPage`: Giao diện tìm kiếm, danh mục khẩn cấp (Hạ thân nhiệt, Say nắng, Rắn cắn, Gãy xương/Bong gân).
  * `FirstAidDetailPage`: Hiển thị chi tiết từng bước sơ cứu từng bước (step-by-step checklist) kèm nút đọc giọng nói hướng dẫn khi người dùng đang hoảng loạn hoặc tay bị thương.
* **Tập dữ liệu sơ cứu mồi (`assets/data/first_aid_guides.json`)**:
  * Bộ dữ liệu song ngữ Việt - Anh chuẩn y khoa dã ngoại cho 4 tình huống nguy cấp hàng đầu.

---

### 1.3. Tính Năng Bản Đồ & Định Vị Ngoại Tuyến (`lib/features/navigation/`)

* **Tầng Domain (`domain/`)**:
  * Thực thể `GeoPointEntity`, `TrackPointEntity`, `WaypointEntity`.
  * Các UseCases: `StartTrackingUseCase`, `StopTrackingUseCase`, `GetTrackPointsUseCase`, `SaveWaypointUseCase`, `GetWaypointsUseCase`, `SyncTrackDataUseCase`.
* **Tầng Data (`data/`)**:
  * `NavigationLocalDatasource`: Tích hợp `geolocator` bắt toạ độ GPS liên tục, cấu hình chạy ngầm (Foreground Notification Service) và lưu trữ cục bộ vào bảng `TrackPoints`.
  * `NavigationRemoteDatasource`: Tải toạ độ lên Supabase dưới định dạng hình học không gian PostGIS `geometry(Point, 4326)`.
* **Tầng Presentation (`presentation/`)**:
  * `NavigationPage`: Bản đồ **flutter_map** tích hợp nguồn bản đồ OpenStreetMap, hiển thị vị trí thời gian thực, bảng đồng hồ đo tốc độ/độ cao, và thanh điều khiển ghi vết (Start / Pause / Stop).

---

### 1.4. Tính Năng Độ Cao & Phân Tích Đường Đi (`lib/features/trail/`)

* `TrailPage`: Giao diện hiển thị biểu đồ trắc diện độ cao (**Altitude Profile**) bằng thư viện `fl_chart`, tính toán độ cao tích luỹ (Elevation Gain), độ dốc tối đa và khoảng cách lộ trình.

---

### 1.5. Tính Năng Xác Thực & Trợ Lý (`lib/features/auth/` & `lib/features/ai_assistant/`)

* `AuthPage`: Hỗ trợ 3 chế độ: Đăng nhập email, Đăng ký mới, và **Chế độ Ẩn danh (Guest Mode)** cho phép dùng ngay lập tức khi không có mạng mà không bắt buộc tạo tài khoản.
* `AiAssistantPage`: Giao diện trò chuyện AI với Gemini API trực tuyến khi có mạng và danh mục câu hỏi sinh tồn có sẵn khi offline.

---

### 1.6. Tài Nguyên Hỗ Trợ & Cơ Sở Hạ Tầng Đã Thiết Lập

1. **Android Manifest (`android/app/src/main/AndroidManifest.xml`)**:
   * Cấp đủ toàn bộ quyền khẩn cấp: Định vị chính xác (`ACCESS_FINE_LOCATION`), định vị ngầm (`ACCESS_BACKGROUND_LOCATION`), chạy dịch vụ ngầm (`FOREGROUND_SERVICE_LOCATION`), ghi âm giọng nói (`RECORD_AUDIO`), chống tắt màn hình (`WAKE_LOCK`).
2. **Kịch bản huấn luyện AI (`docs/ai_pipeline/pipeline_guide.py`)**:
   * Pipeline hoàn chỉnh bằng Python: Chuẩn hóa dữ liệu triệu chứng, huấn luyện mô hình phân loại intent, lượng tử hóa INT8 và xuất file `.tflite` kích thước siêu nhẹ (< 25MB).
3. **Mã nguồn Cơ sở dữ liệu Cloud (`docs/supabase/schema.sql`)**:
   * Cấu hình PostgreSQL + PostGIS, hệ thống bảo mật phân quyền Row Level Security (RLS) cho người dùng cá nhân.
4. **Hệ thống Scripts & CI/CD**:
   * Fastlane config (`fastlane/Fastfile`).
   * GitHub Actions workflow (`deploy/.github/workflows/ci.yml`).
   * Tự động hóa đẩy mã nguồn lên GitHub (`scripts/push_to_github.ps1`).

---

## PHẦN 2: BẢNG PHÂN CHIA CÔNG VIỆC TĂNG TỐC 7 TUẦN (MEMBER 1 GÁNH LÕI KỸ THUẬT)

Do thời gian rút ngắn còn **7 tuần**, Leader (Member 1) không chỉ làm kiến trúc nền mà trực tiếp đảm nhận **4 mô-đun kỹ thuật nặng nhất trên Mobile** để tránh nghẽn tiến độ và khẳng định vai trò kỹ thuật nòng cốt trước Hội đồng chấm thi VKU.

### 👑 MEMBER 1: LEADER / FULL-STACK MOBILE ARCHITECT (Bạn)
> **Trách nhiệm chính:** Kiến trúc Clean Architecture, Bộ máy suy luận On-Device TFLite, Background GPS Engine, Offline Map Tile Caching, Hardware SOS Alert, Tích hợp & Đóng gói Release.

| Tuần | Giai đoạn | Chi tiết công việc cụ thể | File/Mô-đun phụ trách |
| :---: | :--- | :--- | :--- |
| **Tuần 1** | ✅ Khởi tạo Nền tảng | - Dựng khung Clean Architecture 3 lớp chuẩn.<br>- Cấu hình Drift SQLite 4 bảng, BLoC, GoRouter 5 tab, Dark Theme.<br>- Viết test mồi, cấu hình CI/CD và đẩy mã nguồn lên GitHub. | `lib/core/`<br>`lib/features/`<br>`pubspec.yaml` |
| **Tuần 2** | Code Gen & TFLite Tokenizer | - Chạy `build_runner` sinh mã Drift DB & Injectable DI.<br>- Viết `TfliteTokenizer` bằng ngôn ngữ Dart để tiền xử lý văn bản tiếng Việt/Anh (tách từ, padding sequence) tương thích với mô hình AI của Member 2. | `lib/core/di/`<br>`lib/core/database/`<br>`lib/features/first_aid/data/datasources/tflite_tokenizer.dart` |
| **Tuần 3** | TFLite On-Device Inference Engine | - Nhận model `.tflite` từ Member 2, nạp qua `tflite_flutter`.<br>- Tự tay viết code xử lý Input/Output Tensors, ánh xạ xác suất chẩn đoán ra cẩm nang sơ cứu trong `FirstAidBlocHandler`.<br>- Kết nối Micro (Speech-to-Text) và Loa (Text-to-Speech) hoạt động ngoại tuyến. | `lib/features/first_aid/data/datasources/first_aid_ai_service.dart`<br>`lib/features/first_aid/presentation/bloc/` |
| **Tuần 4** | Offline Map Tile Storage Engine | - Xây dựng cơ chế tải và lưu đệm gạch bản đồ OpenStreetMap theo Bounding Box địa lý (`flutter_map_cache`).<br>- Quản lý lưu trữ SQLite/file gạch bản đồ trong bộ nhớ máy, xử lý tự động xoá cache cũ nếu vượt quá 500MB. | `lib/features/navigation/data/datasources/tile_cache_manager.dart` |
| **Tuần 5** | Background GPS Engine & Pin | - Tối ưu Foreground Service chạy ngầm định vị liên tục khi tắt màn hình bằng `flutter_foreground_task`.<br>- Xử lý Wakelock và thuật toán lọc nhiễu toạ độ GPS (Kalman/Distance filter) để tiết kiệm pin tối đa cho chuyến đi dài ngày. | `lib/features/navigation/data/datasources/gps_service.dart` |
| **Tuần 6** | Hardware SOS & Auto Cloud Sync | - Viết bộ điều khiển phần cứng: Kích hoạt đèn Flash camera chớp mã Morse SOS (`... --- ...`) và còi hú cứu nạn âm lượng cực đại qua loa ngoài.<br>- Kiểm thử `SyncService` tự động đồng bộ toạ độ lên Supabase khi phát hiện sóng 4G. | `lib/features/sos/`<br>`lib/core/network/sync_service.dart` |
| **Tuần 7** | Đóng gói APK Release & Tổng duyệt | - Đóng gói APK Release signed có chữ ký số (Keystore) qua Fastlane.<br>- Chạy nghiệm thu toàn bộ tính năng trong chế độ máy bay (100% Airplane Mode).<br>- Hoàn thiện Software Architecture Document và cùng nhóm chuẩn bị Slide bảo vệ. | `fastlane/`<br>`build/app/outputs/flutter-apk/` |

---

### 🧠 MEMBER 2: AI ON-DEVICE & BACKEND SPECIALIST
> **Trách nhiệm chính:** Thu thập và chuẩn hoá Dataset sơ cứu, Huấn luyện mô hình Intent NLP, Lượng tử hóa TFLite INT8, Thiết lập Cloud Supabase PostGIS, API thời tiết & độ cao.

| Tuần | Giai đoạn | Chi tiết công việc cụ thể | File/Mô-đun phụ trách |
| :---: | :--- | :--- | :--- |
| **Tuần 1** | Chuẩn bị dữ liệu sơ cứu | - Thu thập & gán nhãn 150+ mẫu câu miêu tả triệu chứng dã ngoại (tiếng Việt & Anh): hạ thân nhiệt, say độ cao, rắn cắn, sốc nhiệt, trật khớp... | `assets/data/first_aid_dataset.json` |
| **Tuần 2** | Huấn luyện mô hình NLP & Export | - Chạy pipeline `pipeline_guide.py` huấn luyện mô hình phân loại intent triệu chứng (Accuracy ≥ 85%).<br>- Lượng tử hóa mô hình sang INT8 `.tflite` (< 20MB) và xuất file `labels.txt`, `vocab.txt` bàn giao cho Member 1. | `docs/ai_pipeline/`<br>`assets/models/` |
| **Tuần 3** | Triển khai Supabase PostGIS | - Khởi tạo project Supabase Cloud, chạy `docs/supabase/schema.sql` kích hoạt extension `postgis`.<br>- Cấu hình Row Level Security (RLS) và viết truy vấn không gian toạ độ mẫu. | Supabase Dashboard<br>`docs/supabase/` |
| **Tuần 4** | Độ cao & Mở rộng Cẩm nang | - Tích hợp Open-Elevation API / OpenTopography lấy dữ liệu độ cao bổ trợ cho bản đồ.<br>- Mở rộng cẩm nang từ 4 bệnh lên 15+ quy trình sơ cứu y khoa dã ngoại chuyên sâu. | `assets/data/first_aid_guides.json`<br>API Services |
| **Tuần 5** | Đo lường hiệu năng AI & Giọng nói | - Đo đạc độ trễ suy luận AI trên máy Android thật (yêu cầu Latency < 150ms).<br>- Tinh chỉnh cấu hình âm sắc tiếng Việt mượt mà cho `flutter_tts` và `speech_to_text`. | AI Benchmark Report |
| **Tuần 6** | Stress Test Backend & Báo cáo AI | - Kiểm tra tải Supabase khi nhận đồng loạt 1000+ điểm GPS.<br>- Viết chương báo cáo chuyên sâu: "Kiến trúc mô hình On-Device AI và kỹ thuật lượng tử hoá". | Báo cáo Capstone |
| **Tuần 7** | Phản biện AI & Hỗ trợ Hội đồng | - Chuẩn bị bảng số liệu so sánh mô hình gốc vs bản nén INT8 (dung lượng, tốc độ, độ chính xác) để phản biện trước Hội đồng. | Buổi bảo vệ |

---

### 🎨 MEMBER 3: UI/UX & OFFLINE MAPS SPECIALIST
> **Trách nhiệm chính:** Thiết kế hệ thống Figma chuẩn ngoài trời, Tối ưu giao diện bản đồ flutter_map, Vẽ biểu đồ trắc diện độ cao fl_chart, Thiết kế Slide & Poster.

| Tuần | Giai đoạn | Chi tiết công việc cụ thể | File/Mô-đun phụ trách |
| :---: | :--- | :--- | :--- |
| **Tuần 1** | Wireframe & Figma Prototype | - Thiết kế hoàn chỉnh Prototype trên Figma cho 5 màn hình chính theo chuẩn Material 3 High Contrast, nút bấm lớn tối thiểu 48x48dp. | Figma Project Link |
| **Tuần 2** | Tối ưu Giao diện Bản đồ & La bàn | - Cải thiện `navigation_page.dart`: Nút căn giữa toạ độ GPS, thanh công cụ chọn lớp bản đồ.<br>- Tích hợp Widget la bàn số xoay theo góc cảm biến máy (`compass_widget.dart`). | `lib/features/navigation/presentation/pages/navigation_page.dart`<br>`lib/features/navigation/presentation/widgets/` |
| **Tuần 3** | Quản lý Mốc Waypoint trên bản đồ | - Xây dựng Popup tạo Waypoint: Nhập tên điểm, chọn icon (💧 Nguồn nước, ⛺ Cắm trại, ⚠️ Nguy hiểm) và chụp ảnh đính kèm toạ độ.<br>- Tuỳ biến Marker hiển thị sinh động trên bản đồ. | `lib/features/navigation/presentation/widgets/waypoint_dialog.dart` |
| **Tuần 4** | Vẽ biểu đồ Độ cao (Altitude Profile) | - Nâng cấp `trail_page.dart` bằng thư viện `fl_chart`: Vẽ đường cong độ cao theo chiều dài cung đường.<br>- Hiển thị thẻ tóm tắt: Độ cao cực đại (Max Elevation), dốc trung bình, tổng leo dốc (Elevation Gain). | `lib/features/trail/presentation/pages/trail_page.dart` |
| **Tuần 5** | Màn hình SOS & Animation Sơ cứu | - Thiết kế giao diện SOS với nút bấm giữ 3 giây có vòng tròn đếm ngược đập nhịp.<br>- Thêm hình ảnh/hoạt ảnh minh hoạ từng bước xử lý vết thương trong `first_aid_detail_page.dart`. | `lib/features/first_aid/presentation/pages/first_aid_detail_page.dart` |
| **Tuần 6** | Đánh bóng Giao diện & Poster VKU | - Tinh chỉnh Dark Mode chuẩn OLED, thêm Shimmer loading skeleton.<br>- Thiết kế Slide thuyết trình chuyên nghiệp và Poster A0 chuẩn nhận diện VKU. | Poster & Slide Assets |
| **Tuần 7** | Trình chiếu & Demo Sản phẩm | - Phụ trách cầm máy thật thao tác trực tiếp kịch bản Demo mượt mà trong buổi thuyết trình trước Hội đồng. | Buổi bảo vệ |

---

## PHẦN 3: QUY TRÌNH PHỐI HỢP GIT & LÀM VIỆC NHÓM

1. **Kho mã nguồn chung:** `https://github.com/pdthang125/Trekking`
2. **Quy tắc phân nhánh (GitFlow):**
   * `main`: Nhánh chạy ổn định, chỉ Leader mới được merge vào nhánh này.
   * `develop`: Nhánh tích hợp chính của cả nhóm.
   * Mỗi thành viên tạo nhánh tính năng từ `develop`:
     * Member 1: `feature/architecture-drift-wiring`
     * Member 2: `feature/ai-model-training`
     * Member 3: `feature/maps-altitude-ui`
3. **Quy trình đẩy code:**
   ```bash
   # Bước 1: Lấy code mới nhất từ develop
   git checkout develop
   git pull origin develop

   # Bước 2: Tạo nhánh tính năng của mình
   git checkout -b feature/ten-tinh-nang

   # Bước 3: Làm việc, commit theo chuẩn Conventional Commits
   git commit -m "feat(module): mo ta ngan gon chuc nang"

   # Bước 4: Đẩy lên GitHub và tạo Pull Request vào develop
   git push origin feature/ten-tinh-nang
   ```
4. **Họp nhóm định kỳ:** Tối Chủ Nhật hàng tuần tổng kết tiến độ và đồng bộ mã nguồn vào nhánh `develop`.

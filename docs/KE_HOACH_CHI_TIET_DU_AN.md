# 🏔️ TrekGuard AI — Kế Hoạch Dự Án & Chi Tiết Kiến Trúc Toàn Diện
> **Đề tài Capstone:** Hệ thống hỗ trợ Trekking tích hợp AI On-Device sơ cứu khẩn cấp và định vị bản đồ ngoại tuyến  
> **Đơn vị:** Khoa Khoa học Máy tính — Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU)  
> **Giảng viên hướng dẫn:** TS. Nguyễn Thanh Tuấn  
> **Mã nguồn GitHub:** [https://github.com/pdthang125/Trekking](https://github.com/pdthang125/Trekking)  
> **Thời lượng:** 13 Tuần (Tuần 1 — Tuần 13)

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

## PHẦN 2: BẢNG PHÂN CHIA CÔNG VIỆC CHI TIẾT 3 THÀNH VIÊN (TUẦN 2 — TUẦN 13)

### 👑 MEMBER 1: LEADER / FULL-STACK MOBILE ARCHITECT (Bạn)
> **Trách nhiệm chính:** Kiến trúc hệ thống, BLoC State Management, Cơ sở dữ liệu Drift SQLite, Tích hợp TFLite vào Mobile, Điều phối và Kiểm thử.

| Tuần | Giai đoạn | Chi tiết công việc cụ thể | File/Mô-đun phụ trách |
| :---: | :--- | :--- | :--- |
| **Tuần 2** | Code Generation & Wiring | - Chạy `build_runner` sinh code Drift DB (`app_database.g.dart`) & DI (`injection_container.config.dart`).<br>- Hoàn thiện kết nối giữa BLoC và Repositories.<br>- Tạo Supabase project và lấy URL / Anon Key đưa vào biến môi trường. | `lib/core/di/`<br>`lib/core/database/`<br>`.env` |
| **Tuần 3** | TFLite Engine Integration | - Cấu hình `tflite_flutter` trên cả Android & iOS.<br>- Viết `TfliteService` nạp model `.tflite` từ assets và chạy suy luận (Inference) offline.<br>- Kết nối kết quả phân loại từ TFLite vào `FirstAidBloc`. | `lib/features/first_aid/data/datasources/first_aid_ai_service.dart` |
| **Tuần 4** | Offline Tile Storage | - Xây dựng cơ chế tải và cache gạch bản đồ (Map Tiles) từ OpenStreetMap vào bộ nhớ điện thoại (`flutter_map_cache`).<br>- Xử lý quản lý dung lượng cache (giới hạn tối đa 500MB). | `lib/features/navigation/data/datasources/tile_cache_manager.dart` |
| **Tuần 5** | Background GPS Engine | - Tối ưu hoá Background Service ghi toạ độ GPS khi tắt màn hình bằng `flutter_foreground_task`.<br>- Tối ưu mức tiêu thụ pin khi ghi toạ độ liên tục nhiều giờ. | `lib/features/navigation/data/datasources/gps_service.dart` |
| **Tuần 6** | Real-time Sync & PostGIS | - Kiểm thử cơ chế `SyncService` khi bật/tắt mạng giả lập.<br>- Đồng bộ toạ độ lên bảng `track_points` của Supabase bằng PostGIS SQL format. | `lib/core/network/sync_service.dart` |
| **Tuần 7** | Gemini Online Fallback | - Tích hợp `google_generative_ai` SDK vào `AiAssistantPage`.<br>- Xây dựng System Prompt chuyên sâu về sinh tồn, thời tiết dã ngoại. | `lib/features/ai_assistant/` |
| **Tuần 8** | Integration & Code Review | - Hợp nhất (Merge) các nhánh của Member 2 (Model AI) và Member 3 (UI Maps).<br>- Giải quyết xung đột mã nguồn (merge conflicts) trên nhánh `develop`. | Toàn bộ dự án |
| **Tuần 9** | Unit & Widget Testing | - Viết Unit Test cho tất cả BLoC (First Aid, Navigation, Auth).<br>- Đạt độ bao phủ kiểm thử (Test Coverage) tối thiểu 70%. | `test/` |
| **Tuần 10** | Battery & Memory Profiling | - Dùng Flutter DevTools phân tích rò rỉ bộ nhớ (Memory Leaks).<br>- Tối ưu FPS màn hình bản đồ không bị giật lag khi có hàng nghìn điểm GPS. | Profiling reports |
| **Tuần 11** | End-to-End Field Test | - Test thực tế ứng dụng trong điều kiện ngoại tuyến hoàn toàn (Airplane Mode).<br>- Kiểm tra tính chính xác của GPS và tính năng đọc giọng nói SOS. | Release Test Matrix |
| **Tuần 12** | Release Build & Fastlane | - Đóng gói APK Release / App Bundle có chữ ký số (Keystore).<br>- Hoàn thiện tài liệu kiến trúc kỹ thuật (Software Architecture Document). | `fastlane/`<br>`docs/` |
| **Tuần 13** | Capstone Defense | - Chuẩn bị Slide thuyết trình bảo vệ trước Hội đồng VKU.<br>- Quay video Demo các kịch bản thực tế (Mất sóng, ngã chấn thương, cần cứu hộ). | Presentation & Demo |

---

### 🧠 MEMBER 2: AI ON-DEVICE & BACKEND SPECIALIST
> **Trách nhiệm chính:** Thu thập và làm sạch Dataset sơ cứu, Huấn luyện mô hình Intent NLP, Tối ưu & Lượng tử hóa TFLite, Quản trị Cloud Backend Supabase.

| Tuần | Giai đoạn | Chi tiết công việc cụ thể | File/Mô-đun phụ trách |
| :---: | :--- | :--- | :--- |
| **Tuần 2** | Thu thập dữ liệu Sơ cứu | - Thu thập 200+ mẫu câu miêu tả triệu chứng trekking (tiếng Việt & tiếng Anh): hạ thân nhiệt, say độ cao, rắn cắn, côn trùng độc, sốc nhiệt, trật khớp...<br>- Gán nhãn Intent và Entity theo chuẩn định dạng JSON. | `assets/data/first_aid_dataset.json`<br>`docs/ai_pipeline/` |
| **Tuần 3** | Huấn luyện mô hình NLP | - Chạy file `pipeline_guide.py` huấn luyện mô hình phân loại intent.<br>- Thử nghiệm với các kiến trúc: MobileBERT, DistilBERT hoặc Bi-LSTM/TextCNN.<br>- Đạt độ chính xác Accuracy ≥ 85% trên tập kiểm thử (Test Set). | `docs/ai_pipeline/train_model.py` |
| **Tuần 4** | Lượng tử hoá INT8 & Export | - Chuyển đổi mô hình PyTorch/TensorFlow sang TensorFlow Lite (`.tflite`).<br>- Áp dụng kỹ thuật INT8 Quantization để dung lượng file đạt < 25MB.<br>- Xuất file nhãn phân loại (`labels.txt`) và từ điển Tokenizer (`vocab.txt`). | `assets/models/first_aid_model.tflite`<br>`assets/models/labels.txt` |
| **Tuần 5** | Triển khai Supabase PostGIS | - Đăng ký tài khoản Supabase Cloud.<br>- Chạy file `docs/supabase/schema.sql` tạo các bảng và kích hoạt extension `postgis`.<br>- Thiết lập chính sách bảo mật dữ liệu Row Level Security (RLS). | Supabase Dashboard<br>`docs/supabase/` |
| **Tuần 6** | Open-Elevation & Weather API | - Nghiên cứu và viết hàm lấy dữ liệu độ cao từ Open-Elevation API / OpenTopography.<br>- Tích hợp OpenWeatherMap API lấy dữ liệu thời tiết dự báo trước chuyến đi. | Backend / Service layer |
| **Tuần 7** | Voice STT & TTS Optimization | - Thử nghiệm mô hình Vosk offline hoặc tinh chỉnh cấu hình `speech_to_text` tiếng Việt.<br>- Cấu hình giọng đọc tiếng Việt mượt mà cho `flutter_tts`. | AI Audio Pipeline |
| **Tuần 8** | Chuyển giao Model cho Mobile | - Bàn giao file model `.tflite` và cấu trúc Input/Output Tensors cho Member 1 nạp vào Flutter.<br>- Hỗ trợ Member 1 gỡ lỗi Tensor Mismatch (nếu có). | `assets/models/` |
| **Tuần 9** | Mở rộng Seed Data | - Mở rộng cẩm nang từ 4 bệnh lên 15+ bệnh lý dã ngoại chuyên sâu.<br>- Viết quy trình sơ cứu chi tiết theo chuẩn Hội Chữ Thập Đỏ quốc tế. | `assets/data/first_aid_guides.json` |
| **Tuần 10** | Đo lường hiệu năng AI | - Đo đạc thời gian suy luận (Inference Latency) trên thiết bị Android thật (yêu cầu < 150ms).<br>- Đánh giá mức độ hao pin khi chạy suy luận liên tục. | AI Benchmark Report |
| **Tuần 11** | Backend Security & Stress Test | - Kiểm tra bảo mật API keys.<br>- Kiểm tra khả năng chịu tải của database Supabase khi nhận hàng loạt toạ độ GPS gửi lên. | Security Audit |
| **Tuần 12** | Báo cáo chuyên đề AI | - Viết chương báo cáo: "Kiến trúc mô hình On-Device AI và kỹ thuật lượng tử hoá".<br>- Lập biểu đồ so sánh độ chính xác và dung lượng giữa mô hình gốc và bản quantize. | Báo cáo Capstone |
| **Tuần 13** | Hỗ trợ Bảo vệ Capstone | - Phụ trách trả lời các câu hỏi của Hội đồng về khía cạnh AI, mô hình học máy và cơ sở dữ liệu. | Buổi bảo vệ |

---

### 🎨 MEMBER 3: UI/UX & OFFLINE MAPS SPECIALIST
> **Trách nhiệm chính:** Thiết kế giao diện Figma chuẩn ngoài trời, Tối ưu bản đồ flutter_map, Vẽ đồ thị trắc diện độ cao fl_chart, Trải nghiệm người dùng dã ngoại.

| Tuần | Giai đoạn | Chi tiết công việc cụ thể | File/Mô-đun phụ trách |
| :---: | :--- | :--- | :--- |
| **Tuần 2** | Thiết kế Wireframe & Figma | - Thiết kế hoàn chỉnh Prototype trên Figma cho 5 màn hình chính.<br>- Tuân thủ Material 3 High Contrast, kích thước nút bấm lớn (tối thiểu 48x48dp) để dễ bấm khi đeo găng tay trekking. | Figma Project Link |
| **Tuần 3** | Tối ưu Giao diện Navigation | - Cải thiện `navigation_page.dart`: Thiết kế thanh công cụ điều khiển bản đồ, nút căn giữa toạ độ (Center GPS), chọn loại bản đồ (Vệ tinh, Địa hình, Tiêu chuẩn). | `lib/features/navigation/presentation/pages/navigation_page.dart` |
| **Tuần 4** | Thiết kế La Bàn (Compass) | - Tích hợp la bàn số động (Digital Compass HUD) xoay theo hướng di chuyển người dùng dựa vào cảm biến từ kế của điện thoại (`flutter_compass`). | `lib/features/navigation/presentation/widgets/compass_widget.dart` |
| **Tuần 5** | Quản lý Waypoint trên bản đồ | - Xây dựng Dialog tạo Waypoint: Nhập tên điểm mốc, chọn icon (Nguồn nước 💧, Cắm trại ⛺, Nguy hiểm ⚠️), chụp ảnh đính kèm toạ độ. | `lib/features/navigation/presentation/widgets/waypoint_dialog.dart` |
| **Tuần 6** | Vẽ biểu đồ Độ cao (Altitude Chart) | - Nâng cấp `trail_page.dart`: Dùng `fl_chart` hiển thị đường cong trắc diện độ cao theo quãng đường.<br>- Hiển thị điểm cao nhất (Max Peak), điểm thấp nhất, độ dốc trung bình. | `lib/features/trail/presentation/pages/trail_page.dart` |
| **Tuần 7** | Giao diện Tải Bản đồ Offline | - Thiết kế màn hình "Quản lý bản đồ ngoại tuyến": Cho phép người dùng chọn vùng địa lý (bounding box) và bấm tải gạch bản đồ.<br>- Hiển thị thanh tiến trình tải (Progress Bar) và dung lượng file đã tải. | `lib/features/navigation/presentation/pages/offline_map_manager_page.dart` |
| **Tuần 8** | Giao diện Chi tiết Sơ cứu | - Thiết kế hoạt ảnh (Animations) cho từng bước sơ cứu trong `first_aid_detail_page.dart`.<br>- Thêm bộ đếm thời gian hồi sức tim phổi CPR (Metronome âm thanh 100-120 nhịp/phút). | `lib/features/first_aid/presentation/pages/first_aid_detail_page.dart` |
| **Tuần 9** | Đánh bóng UI & Dark Mode | - Tinh chỉnh chế độ nền tối siêu tiết kiệm pin (True Black OLED theme).<br>- Thêm hiệu ứng Shimmer Loading skeleton cho các danh sách tải dữ liệu. | `lib/core/theme/` |
| **Tuần 10** | Trải nghiệm SOS khẩn cấp | - Thiết kế màn hình SOS trực quan: Bấm giữ 3 giây để kích hoạt đèn Flash phát mã Morse cứu hộ (SOS `... --- ...`) và còi hú báo động âm lượng lớn. | `lib/core/pages/home_page.dart`<br>`lib/features/sos/` |
| **Tuần 11** | Kiểm thử Khả năng tương thích | - Kiểm tra hiển thị trên nhiều kích cỡ màn hình khác nhau (Android cỡ nhỏ, màn hình tràn viền, máy tính bảng).<br>- Tối ưu phông chữ hiển thị rõ ràng dưới ánh sáng mặt trời gay gắt. | UI Responsiveness Report |
| **Tuần 12** | Thiết kế Poster & Tài liệu | - Thiết kế Poster giới thiệu đồ án Capstone chuẩn nhận diện VKU.<br>- Chuẩn bị ảnh chụp màn hình đẹp mắt (Mockups) cho tài liệu báo cáo. | Poster & Slide Assets |
| **Tuần 13** | Hỗ trợ Demo Sản phẩm | - Phụ trách điều khiển ứng dụng trực tiếp (Live Demo) mượt mà trong quá trình nhóm bảo vệ trước Hội đồng. | Buổi bảo vệ |

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

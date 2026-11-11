# 📋 MEMBER 2 — Nhật Ký Công Việc Backend & Supabase PostGIS

> **Người thực hiện:** Member 2 — AI & Backend Specialist  
> **Dự án:** TrekGuard AI — Capstone VKU  
> **Cập nhật lần cuối:** 2026-11-10  

---

## ✅ NHỮNG GÌ ĐÃ HOÀN THÀNH

### 1. 🗄️ Supabase PostGIS Setup — `docs/supabase/`

#### `schema.sql` (đã có sẵn — giữ nguyên)
Các bảng cốt lõi đã được thiết lập từ trước:
- `profiles` — Hồ sơ người dùng, trigger tự tạo khi đăng ký
- `trips` — Chuyến đi trekking
- `track_points` — Điểm GPS với `GEOGRAPHY(POINT, 4326)` + GIST index
- `waypoints` — Điểm đánh dấu với PostGIS
- `first_aid_guides` — Cẩm nang sơ cứu (public read, admin write)
- RLS (Row Level Security) cho tất cả bảng

#### `schema_v2.sql` (**MỚI**)
Mở rộng thêm:
- **`sos_events`** — Lưu sự kiện SOS khẩn cấp + PostGIS location + trạng thái (active/resolved/false_alarm)
- **`elevation_cache`** — Cache dữ liệu độ cao từ API (giảm số lần gọi API)
- **Mở rộng `waypoints`**: thêm `waypoint_type` (water_source/campsite/danger/shelter...), `icon_emoji`, `photo_url`
- **Mở rộng `trips`**: thêm `elevation_gain`, `elevation_loss`, `avg_speed_kmh`, `status`
- **3 PostGIS RPC Functions**:
  - `calculate_trip_distance(trip_id)` — Tính khoảng cách bằng `ST_Distance` PostGIS
  - `get_trip_bounds(trip_id)` — Lấy bounding box địa lý của chuyến đi
  - `find_nearest_waypoints(lat, lng, radius, limit)` — Tìm waypoint gần nhất bằng `ST_DWithin`
- **Thêm triggers `updated_at`** cho `profiles` và `waypoints`

> **Cách chạy:** Supabase Dashboard → SQL Editor → chạy `schema.sql` trước, rồi `schema_v2.sql`

---

### 2. 🧭 Navigation Backend — `lib/features/navigation/`

#### Datasources mới:
| File | Mô tả |
|------|-------|
| `trip_local_datasource.dart` | CRUD Trip trên Drift SQLite: tạo, lấy, cập nhật, kết thúc, xoá mềm, đếm track points/waypoints |
| `trip_remote_datasource.dart` | Tải Trip lên Supabase, gọi PostGIS RPC functions (`calculate_trip_distance`, `get_trip_bounds`, `find_nearest_waypoints`) |
| `elevation_service.dart` | Tính ElevationStats (gain/loss/max/min/avg), cache elevation vào Supabase; **chừa chỗ** `_fetchFromElevationApi()` để gắn Open-Elevation API |

#### Domain mới:
| File | Mô tả |
|------|-------|
| `trip_repository.dart` | Hợp đồng repository cho Trip management |
| `trip_usecases.dart` | 7 use cases: Create, GetAll, GetActive, End, Delete, GetSummary, Sync |

#### Repository mới:
| File | Mô tả |
|------|-------|
| `trip_repository_impl.dart` | Offline-First: local trước, sync lên cloud khi có mạng |

#### Fix:
- `navigation_local_datasource.dart` — Sửa kiểu `List<int>` → `List<String>` cho `getUnsyncedTrackPointIds()` và `markTrackPointsSynced()` (UUID là text, không phải int)

#### Cập nhật entities:
- `navigation_entities.dart` — Mở rộng `TripEntity` thêm các helper: `isActive`, `duration`, `avgSpeedKmh`, `copyWith()`; thêm class `TripSummary`

---

### 3. 🆘 SOS Backend — `lib/features/sos/` (**MỚI hoàn toàn**)

| File | Mô tả |
|------|-------|
| `domain/entities/sos_entities.dart` | Entity `SosEvent` với trạng thái enum `SosStatus` |
| `domain/repositories/sos_repository.dart` | Hợp đồng repository |
| `domain/usecases/sos_usecases.dart` | 3 use cases: Create, GetHistory, Sync |
| `data/datasources/sos_local_datasource.dart` | CRUD SosEvent trên Drift SQLite |
| `data/datasources/sos_remote_datasource.dart` | Upload SOS lên Supabase PostGIS (kèm vị trí địa lý `POINT(lng lat)`) |
| `data/repositories/sos_repository_impl.dart` | **Ưu tiên cao**: cố gắng đẩy lên cloud ngay khi tạo SOS, nếu không có mạng thì queue để sync sau |

---

### 4. 🔐 Auth Backend — `lib/features/auth/` (**MỚI hoàn toàn**)

| File | Mô tả |
|------|-------|
| `domain/entities/auth_entities.dart` | Entity `UserProfile` |
| `domain/repositories/auth_repository.dart` | Hợp đồng repository |
| `data/repositories/auth_repository_impl.dart` | Cài đặt với Supabase Auth: login, register, logout, updateProfile trên bảng `profiles` |

> **Lưu ý:** `AuthBlocHandler` đã tồn tại ở presentation layer và dùng `SupabaseClient` trực tiếp — file này cung cấp thêm lớp repository chuẩn Clean Architecture.

---

### 5. 🔄 SyncService nâng cấp — `lib/core/network/sync_service.dart`

Thay thế hoàn toàn file cũ bằng phiên bản đầy đủ:
- **Thứ tự ưu tiên đồng bộ**: SOS → Trips → Track Points → Waypoints → First Aid seed
- **Guard `_isSyncing`** tránh chạy song song
- Ghi log chi tiết từng bước
- Xử lý lỗi từng module độc lập (1 module lỗi không dừng các module khác)
- Cập nhật constructor nhận thêm `TripLocalDatasource`, `TripRemoteDatasource`, `SosLocalDatasource`, `SosRemoteDatasource`

---

### 6. 💉 Dependency Injection — `lib/core/di/injection_container.dart`

Cập nhật:
- Đăng ký `Connectivity` singleton (dependency của `NetworkInfo`)
- Xử lý Supabase chưa khởi tạo (Offline mode) an toàn hơn

---

### 7. 📚 First Aid Data — `assets/data/first_aid_guides.json`

Mở rộng từ **4 bệnh lý → 15 bệnh lý** chuyên sâu y tế dã ngoại:

| # | ID | Tên tiếng Việt | Độ nguy hiểm |
|---|-----|----------------|--------------|
| 1 | `snake-bite-001` | Rắn Cắn | 🔴 danger |
| 2 | `sprained-ankle-001` | Trẹo Mắt Cá Chân | 🟡 warning |
| 3 | `heat-exhaustion-001` | Kiệt Sức Do Nóng | 🟡 warning |
| 4 | `hypothermia-001` | Hạ Thân Nhiệt | 🔴 danger |
| 5 | `altitude-sickness-001` | Say Độ Cao (AMS/HACE/HAPE) | 🔴 danger |
| 6 | `dehydration-001` | Mất Nước Nặng | 🟡 warning |
| 7 | `blunt-trauma-001` | Gãy Xương / Chấn Thương | 🔴 danger |
| 8 | `wound-bleeding-001` | Chảy Máu Nặng / Vết Thương Hở | 🔴 danger |
| 9 | `bee-sting-001` | Ong Đốt | 🟡 warning |
| 10 | `anaphylaxis-001` | Sốc Phản Vệ | 🔴 danger |
| 11 | `drowning-001` | Đuối Nước | 🔴 danger |
| 12 | `food-poisoning-001` | Ngộ Độc Thực Phẩm | 🟡 warning |
| 13 | `burn-001` | Bỏng | 🟡 warning |
| 14 | `lightning-strike-001` | Sét Đánh | 🔴 danger |
| 15 | `eye-injury-001` | Chấn Thương Mắt | 🟡 warning |
| 16 | `heat-stroke-001` | Sốc Nhiệt (Nặng) | 🔴 danger |

Mỗi bệnh lý có đầy đủ: `steps[]`, `doNots[]`, `doNotsVi[]`, `whenToEvacuate`, `tags[]` (từ khoá tiếng Việt + tiếng Anh)

---

### 8. 🤖 Chatbot AI Hybrid Routing Engine — `lib/features/ai_assistant/` (**MỚI**)

Hiện thực hoá chính xác luồng rẽ nhánh thông minh theo sơ đồ kiến trúc:

```
[Người dùng nhập triệu chứng / Câu hỏi]
                 │
        ┌────────┴────────┐
        ▼                 ▼
 [Có kết nối Mạng?]   [Mất kết nối Mạng]
        │                 │
   ┌────┴────┐            │
   ▼         ▼            │
[Mạng nhanh] [Timeout/Yếu]│
   │         │            │
   ▼         └─────┬──────┘
(Gemini Cloud)     ▼
   │         (Local Model Slot - Đã chừa chỗ)
   └───────────────┬──────┘
                   ▼
               [Kết quả]
```

- **Cloud API (`ai_remote_datasource.dart`)**: Tích hợp Google Gemini (`gemini-1.5-flash`) với timeout 5 giây. Nếu mạng yếu / timeout hoặc không có API key thì kích hoạt fallback ngay mà không làm đơ giao diện.
- **Local Model Slot (`ai_local_datasource.dart`)**: Đã đánh dấu comment `TODO (Member 2)` rõ ràng để bạn cắm model tự huấn luyện vào. Trong thời gian chưa nhúng model, hệ thống tự động fallback qua tra cứu 16 bệnh lý dã ngoại từ SQLite để ứng dụng chạy mượt 100%.
- **Decision Dispatcher (`ai_assistant_repository_impl.dart`)**: Kiểm tra `NetworkInfo.isConnected` và xử lý toàn bộ logic rẽ nhánh.
- **UI Badge**: Mỗi bong bóng phản hồi hiển thị rõ nguồn gốc `Gemini Cloud` (icon đám mây xanh) hoặc `Local Model (On-Device)` (icon chip vi xử lý cam) để người dùng phân biệt.


---

## 📁 DANH SÁCH FILE ĐÃ TẠO / SỬA ĐỔI

```
docs/
  supabase/
    schema_v2.sql                           ← MỚI

lib/
  core/
    di/
      injection_container.dart              ← CẬP NHẬT
    network/
      sync_service.dart                     ← CẬP NHẬT (viết lại hoàn toàn)
  
  features/
    auth/
      domain/
        entities/auth_entities.dart         ← MỚI
        repositories/auth_repository.dart   ← MỚI
      data/
        repositories/
          auth_repository_impl.dart         ← MỚI

    navigation/
      domain/
        entities/navigation_entities.dart   ← CẬP NHẬT (mở rộng TripEntity)
        repositories/trip_repository.dart   ← MỚI
        usecases/trip_usecases.dart         ← MỚI
      data/
        datasources/
          navigation_local_datasource.dart  ← FIX (UUID type)
          trip_local_datasource.dart        ← MỚI
          trip_remote_datasource.dart       ← MỚI
          elevation_service.dart            ← MỚI
        repositories/
          trip_repository_impl.dart         ← MỚI

    sos/
      domain/
        entities/sos_entities.dart          ← MỚI
        repositories/sos_repository.dart    ← MỚI
        usecases/sos_usecases.dart          ← MỚI
      data/
        datasources/
          sos_local_datasource.dart         ← MỚI
          sos_remote_datasource.dart        ← MỚI
        repositories/
          sos_repository_impl.dart          ← MỚI

assets/
  data/
    first_aid_guides.json                   ← CẬP NHẬT (4 → 16 bệnh lý)
```

---

## ⏳ VIỆC CÒN LẠI (Member 2)

### Tuần 5–6
- [ ] **Benchmark SyncService** bằng cách tạo 1000+ track points giả, đo thời gian upload Supabase
- [ ] **Stress test**: kiểm tra Supabase khi nhận đồng loạt track points
- [ ] **Viết chương báo cáo** về kiến trúc backend Offline-First + PostGIS

### Tuần 7
- [ ] **Chuẩn bị bảng số liệu** cho Hội đồng

---

## 🔧 VIỆC CỦA MEMBER 1 (cần phối hợp)

Sau khi Member 2 hoàn thành, **Member 1 cần**:
1. Chạy `dart run build_runner build --delete-conflicting-outputs` để sinh lại `injection_container.config.dart`
2. Đăng ký các repository/datasource mới vào DI container nếu build_runner không tự phát hiện
3. Tích hợp `TripLocalDatasource` và `TripRemoteDatasource` vào `SyncService` constructor

---

## 🗒️ GHI CHÚ KỸ THUẬT

### PostGIS POINT format
```dart
// Luôn dùng: POINT(longitude latitude) — longitude trước, latitude sau
'location': 'POINT(${point.longitude} ${point.latitude})'

// Đọc lại:
'ST_X(location::geometry) as lng'   // longitude
'ST_Y(location::geometry) as lat'   // latitude
```

### RLS Policy — Supabase
Mọi thao tác từ Flutter client cần user đã đăng nhập (`auth.uid() != null`).  
Ngoại lệ: `first_aid_guides` — public read, không cần auth.

### Offline-First Flow
```
Người dùng thao tác
        ↓
  Lưu vào Drift SQLite (synced = false)
        ↓
  Có mạng? → SyncService.syncAll()
        ↓
  Upload lên Supabase
        ↓
  Đánh dấu synced = true
```


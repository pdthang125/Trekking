## 📋 Danh sách việc Member 2 (AI & Backend)

### Tuần 1–2 — Setup & Research
- [ ] Clone repo: `git clone https://github.com/pdthang125/Trekking.git`
- [ ] Cài Python: `pip install torch transformers datasets scikit-learn tensorflow`
- [ ] Đọc: `docs/ai_pipeline/pipeline_guide.py`
- [ ] Thu thập dataset (target 200+ samples/loại):
  - [ ] Rắn cắn (snake bite)
  - [ ] Trẹo khớp (sprain)
  - [ ] Kiệt sức nhiệt (heat exhaustion)  
  - [ ] Hạ thân nhiệt (hypothermia)
  - [ ] Gãy xương (fracture)
  - [ ] Bỏng (burn)
  - [ ] Sốt cao (high fever)
  - [ ] Dị ứng / sốc phản vệ (anaphylaxis)
- [ ] Tạo CSV dataset theo format: `symptom_text,condition_id,severity`

### Tuần 3–4 — Model Training
- [ ] Fine-tune MobileBERT trên Google Colab (free GPU)
- [ ] Đánh giá: accuracy ≥ 80%, F1-score ≥ 0.75
- [ ] Export → INT8 quantize → `.tflite`
- [ ] Copy model vào: `assets/models/first_aid_model.tflite`
- [ ] Implement `TfliteInferenceDatasource` trong `lib/features/first_aid/data/datasources/`
- [ ] Thay thế `searchBySymptoms()` bằng TFLite inference

### Tuần 5–6 — FastAPI Backend
- [ ] Tạo `backend/` folder tại root project
- [ ] Implement FastAPI endpoints:
  - `POST /predict` — online AI fallback
  - `GET /guides` — sync guides
  - `GET /health` — health check
- [ ] Deploy: Railway.app hoặc Render.com (free tier)

### Branch convention
```bash
git checkout develop
git checkout -b feature/tflite-model
# code...
git commit -m "feat(ai): add TFLite inference datasource"
git push origin feature/tflite-model
# Tạo PR → develop
```

---

## 📋 Danh sách việc Member 3 (UI/UX & Maps)

### Tuần 1–2 — Design & Setup
- [ ] Clone repo: `git clone https://github.com/pdthang125/Trekking.git`
- [ ] Cài Flutter: copy từ `C:\flutter` hoặc tải mới
- [ ] `flutter pub get` trong thư mục project
- [ ] Tạo Figma project — design system từ `app_theme.dart`:
  ```
  Primary:  #2ECC71
  Danger:   #E74C3C  
  Warning:  #F39C12
  Info:     #3498DB
  Dark bg:  #0F1320
  Card:     #242A38
  Font:     Outfit (Google Fonts)
  ```
- [ ] Wireframe 5 màn hình (xem code hiện tại làm tham chiếu)
- [ ] Share Figma link → paste vào README.md

### Tuần 3–4 — Maps & GPS UI
- [ ] Offline tile caching: nghiên cứu `flutter_map` + MBTiles
- [ ] Implement real GPS tracking trong `navigation_page.dart`
  - Kết nối `NavigationBloc` với `StartTrackingUseCase`
  - Hiển thị polyline track real-time
- [ ] Waypoint dialog (add/edit/delete)
- [ ] Compass overlay trên map
- [ ] Download map tiles UI (progress indicator)

### Tuần 5–6 — Trail & Altitude
- [ ] Kết nối `trail_page.dart` với real GPS data từ Drift
- [ ] Open-Elevation API call để lấy elevation data
- [ ] Distance calculation display (Haversine formula)
- [ ] Trip summary card

### Tuần 7 — Polish
- [ ] Dark Mode kiểm tra trên tất cả màn hình
- [ ] Loading skeletons (shimmer) cho danh sách
- [ ] Error states UI
- [ ] Onboarding screens (nếu có thời gian)

### Branch convention
```bash
git checkout develop
git checkout -b feature/offline-maps
# design...
git commit -m "feat(maps): implement offline tile caching"
git push origin feature/offline-maps
```

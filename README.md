# 🏔️ TrekGuard AI

> **Hệ thống hỗ trợ Trekking tích hợp AI On-Device sơ cứu khẩn cấp và định vị bản đồ ngoại tuyến**  
> Đồ án Capstone — VKU · Học phần: Phát triển ứng dụng di động đa nền tảng

[![CI/CD](https://github.com/your-org/trekguard_ai/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/trekguard_ai/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.24-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## ✨ Tính năng chính

| Tính năng | Mô tả | Online/Offline |
|-----------|-------|----------------|
| 🏥 **AI Sơ cứu On-Device** | Chẩn đoán triệu chứng & hướng dẫn sơ cứu (TFLite) | ✅ **100% Offline** |
| 🗺️ **Bản đồ offline** | OpenStreetMap tile caching + GPS tracking | ✅ **100% Offline** |
| 📈 **Đồ thị độ cao** | Altitude Profile từ GPS tracklog | ✅ **100% Offline** |
| 🤖 **AI Chat (Gemini)** | Tư vấn lập kế hoạch, thời tiết, sinh tồn | ⚡ Online |
| 🎙️ **Speech-to-Text** | Nhập triệu chứng bằng giọng nói | ✅ Offline |
| 🔊 **Text-to-Speech** | Đọc hướng dẫn sơ cứu bằng giọng nói | ✅ Offline |

---

## 🛠️ Tech Stack

```
Mobile:       Flutter 3.24 + Dart 3
Architecture: Clean Architecture 3 lớp + BLoC
Database:     Drift (SQLite) — Offline First
Cloud:        Supabase (PostgreSQL + PostGIS + RLS)
AI On-Device: TensorFlow Lite (tflite_flutter)
AI Online:    Google Gemini API
Maps:         flutter_map + OpenStreetMap
CI/CD:        Fastlane + GitHub Actions
```

---

## 🚀 Cài đặt & Chạy

### Yêu cầu
- Flutter SDK ≥ 3.22.0
- Dart SDK ≥ 3.3.0
- Android SDK (API 21+) / Xcode 15+

### Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/trekguard_ai.git
cd trekguard_ai

# 2. Install dependencies
flutter pub get

# 3. Run code generation
dart run build_runner build --delete-conflicting-outputs

# 4. Run (with environment variables)
flutter run \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

### Supabase Setup
1. Tạo project tại [supabase.com](https://supabase.com)
2. Chạy SQL schema: `docs/supabase/schema.sql`
3. Enable PostGIS extension trong Dashboard

---

## 📁 Cấu trúc Project

```
lib/
├── core/               # Shared: error, DI, theme, router, database
├── features/
│   ├── first_aid/      # AI Sơ cứu (Domain → Data → Presentation)
│   ├── navigation/     # Bản đồ GPS
│   ├── trail/          # Lộ trình & Altitude Profile
│   ├── ai_assistant/   # Gemini API Chat
│   └── auth/           # Supabase Auth
└── main.dart
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# With coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## 🔄 CI/CD với Fastlane

```bash
# Full CI pipeline
bundle exec fastlane android ci

# Build release APK only
bundle exec fastlane android build_release

# Run tests only
bundle exec fastlane android test
```

### GitHub Secrets cần thiết
| Secret | Mô tả |
|--------|-------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous key |
| `GEMINI_API_KEY` | Google AI Gemini API key |
| `KEYSTORE_BASE64` | Android keystore (base64 encoded) |
| `KEY_STORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

---

## 👥 Nhóm

| Vai trò | Phụ trách |
|---------|-----------|
| Leader / Full-Stack Mobile | Architecture, BLoC, CI/CD |
| AI & Backend Engineer | FastAPI, TFLite model pipeline |
| UI/UX & Maps Engineer | Figma, flutter_map, Altitude Chart |

**GVHD:** TS. Nguyễn Thanh Tuấn — VKU

---

## 📄 License

MIT License — VKU Capstone Project 2025–2026

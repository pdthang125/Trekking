#!/usr/bin/env python3
"""
TrekGuard AI — AI Pipeline Documentation
Member 2 phụ trách từ Tuần 3–4
"""

# ══════════════════════════════════════════════════════════════
# BƯỚC 1: Cài đặt môi trường Python (Member 2 chạy lần đầu)
# ══════════════════════════════════════════════════════════════
# pip install torch transformers datasets scikit-learn
# pip install tensorflow onnx tf2onnx
# pip install fastapi uvicorn sqlalchemy

# ══════════════════════════════════════════════════════════════
# BƯỚC 2: Cấu trúc dataset (CSV format)
# ══════════════════════════════════════════════════════════════
# symptom_text,condition_id,condition_name,severity
# "rắn cắn, sưng đỏ, đau nhói",snake-bite-001,Rắn Cắn,danger
# "trẹo chân, đau mắt cá, không đứng được",sprain-001,Trẹo Mắt Cá,warning
# "chóng mặt, buồn nôn, nóng người",heat-001,Kiệt Sức Do Nóng,warning

DATASET_SCHEMA = {
    "columns": ["symptom_text", "condition_id", "condition_name", "severity"],
    "severity_labels": {"danger": 2, "warning": 1, "safe": 0},
    "target_samples_per_class": 200,  # minimum for training
}

# ══════════════════════════════════════════════════════════════
# BƯỚC 3: Model Architecture Options
# ══════════════════════════════════════════════════════════════
MODEL_OPTIONS = [
    {
        "name": "MobileBERT",
        "size_mb": 25,
        "inference_ms": 80,
        "recommended": True,
        "notes": "Best balance size/accuracy for on-device NLP"
    },
    {
        "name": "DistilBERT (multilingual)",
        "size_mb": 134,
        "inference_ms": 200,
        "recommended": False,
        "notes": "Better Vietnamese support but larger size"
    },
    {
        "name": "TinyBERT",
        "size_mb": 15,
        "inference_ms": 40,
        "recommended": False,
        "notes": "Fastest but lower accuracy"
    }
]

# ══════════════════════════════════════════════════════════════
# BƯỚC 4: Training Pipeline (pseudo-code template)
# ══════════════════════════════════════════════════════════════
TRAINING_PIPELINE = """
1. Load dataset from CSV
2. Tokenize Vietnamese text (PhoBERT tokenizer recommended)
3. Split: 80% train / 10% val / 10% test
4. Fine-tune MobileBERT for sequence classification
5. Evaluate: accuracy, F1-score per class
6. If accuracy < 80%: collect more data or adjust hyperparams

Hyperparameters:
  - learning_rate: 2e-5
  - batch_size: 32
  - epochs: 10
  - max_seq_length: 128
  - warmup_steps: 100
"""

# ══════════════════════════════════════════════════════════════
# BƯỚC 5: Quantization & Export
# ══════════════════════════════════════════════════════════════
EXPORT_STEPS = """
Option A — TFLite:
  1. Convert PyTorch → ONNX: torch.onnx.export(model, ...)
  2. Convert ONNX → TFLite: tf2onnx + TFLite converter
  3. Apply INT8 quantization: reduce size ~4x
  4. Save to: assets/models/first_aid_model.tflite

Option B — ONNX (simpler):
  1. Export PyTorch → ONNX directly
  2. Use onnxruntime on device
  3. Save to: assets/models/first_aid_model.onnx

Target metrics after quantization:
  - Model size: < 50MB
  - Inference time: < 2 seconds on mid-range phone
  - Accuracy drop from quantization: < 3%
"""

# ══════════════════════════════════════════════════════════════
# BƯỚC 6: FastAPI Backend (for model serving & data pipeline)
# ══════════════════════════════════════════════════════════════
FASTAPI_ENDPOINTS = {
    "POST /predict": "Predict first-aid guide from symptom text (online fallback)",
    "GET /guides": "Get all first-aid guides",
    "POST /guides/sync": "Sync new guides from Supabase",
    "GET /health": "Health check",
}

if __name__ == "__main__":
    print("📖 TrekGuard AI Pipeline Documentation")
    print("Member 2: Đọc file này và implement từng bước")
    print(f"Models: {[m['name'] for m in MODEL_OPTIONS]}")
    print(f"Recommended: MobileBERT — {MODEL_OPTIONS[0]['size_mb']}MB")

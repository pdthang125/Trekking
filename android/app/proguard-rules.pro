# Proguard / R8 rules for TrekGuard AI

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Flutter & Plugins
-dontwarn com.csdcorp.speech_to_text.**
-dontwarn io.flutter.plugins.**


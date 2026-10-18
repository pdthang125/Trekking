/// Environment configuration
/// 
/// In production, use --dart-define or a .env loader.
/// Never commit real keys to git.
class Env {
  Env._();

  // ─── Supabase ─────────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  // ─── Gemini API ───────────────────────────────────────────────────
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY',
  );

  // ─── FastAPI Backend ──────────────────────────────────────────────
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // ─── Feature Flags ────────────────────────────────────────────────
  static const bool enableOfflineMode = true;
  static const bool enableGeminiOnline = true;
  static const bool enableSpeech = true;
}

-- ============================================================
-- TrekGuard AI — Supabase PostgreSQL Schema (V1, đã đồng bộ)
-- Chạy file này TRƯỚC, sau đó chạy schema_v2.sql
-- Có thể chạy lại nhiều lần (idempotent)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Hàm dùng chung ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─── Profiles ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ─── Trips ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  notes TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  total_distance_km FLOAT DEFAULT 0,
  max_altitude FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);

-- ─── Track Points (PostGIS) ──────────────────────────────────

CREATE TABLE IF NOT EXISTS track_points (
  id BIGSERIAL PRIMARY KEY,
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  altitude FLOAT,
  accuracy FLOAT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_track_points_location
  ON track_points USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_track_points_trip_id
  ON track_points(trip_id, recorded_at);

-- ─── Waypoints (PostGIS) ─────────────────────────────────────
-- updated_at + deleted_at có sẵn từ V1 để V2 (trigger, soft delete) hoạt động

CREATE TABLE IF NOT EXISTS waypoints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  note TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  altitude FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Nếu bảng waypoints đã tồn tại từ trước thì vẫn bổ sung cột thiếu
ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_waypoints_location
  ON waypoints USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_waypoints_trip_id ON waypoints(trip_id);

-- ─── First Aid Guides ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS first_aid_guides (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  condition_name TEXT NOT NULL,
  condition_name_vi TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('safe', 'warning', 'danger')),
  description TEXT NOT NULL,
  description_vi TEXT NOT NULL,
  steps_json JSONB NOT NULL DEFAULT '[]',
  do_nots_json JSONB NOT NULL DEFAULT '[]',
  tags JSONB NOT NULL DEFAULT '[]',
  when_to_evacuate TEXT,
  version INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_first_aid_guides_fts
  ON first_aid_guides USING GIN(to_tsvector('simple', condition_name_vi || ' ' || description_vi));

-- ─── Row-Level Security ──────────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE track_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE waypoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE first_aid_guides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "trips_all_own" ON trips;
CREATE POLICY "trips_all_own" ON trips
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "track_points_through_trip" ON track_points;
CREATE POLICY "track_points_through_trip" ON track_points
  FOR ALL
  USING (EXISTS (SELECT 1 FROM trips WHERE trips.id = track_points.trip_id AND trips.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM trips WHERE trips.id = track_points.trip_id AND trips.user_id = auth.uid()));

DROP POLICY IF EXISTS "waypoints_all_own" ON waypoints;
CREATE POLICY "waypoints_all_own" ON waypoints
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Public read; ghi dữ liệu chỉ qua service_role (bypass RLS)
DROP POLICY IF EXISTS "first_aid_guides_public_read" ON first_aid_guides;
CREATE POLICY "first_aid_guides_public_read" ON first_aid_guides
  FOR SELECT USING (true);

-- ─── Triggers updated_at ─────────────────────────────────────

CREATE OR REPLACE TRIGGER profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER trips_updated_at BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER waypoints_updated_at BEFORE UPDATE ON waypoints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE OR REPLACE TRIGGER first_aid_guides_updated_at BEFORE UPDATE ON first_aid_guides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── Views ───────────────────────────────────────────────────
-- Dùng subquery để đếm đúng (tránh nhân bội do join 2 bảng con)
-- security_invoker: view tuân theo RLS của người gọi (Postgres 15+, Supabase hỗ trợ)

DROP VIEW IF EXISTS trip_summaries;

CREATE VIEW trip_summaries
WITH (security_invoker = true) AS
SELECT
  t.id,
  t.user_id,
  t.name,
  t.started_at,
  t.ended_at,
  t.total_distance_km,
  t.max_altitude,
  (SELECT COUNT(*) FROM waypoints w
     WHERE w.trip_id = t.id AND w.deleted_at IS NULL) AS waypoint_count,
  (SELECT COUNT(*) FROM track_points tp
     WHERE tp.trip_id = t.id) AS track_point_count
FROM trips t;
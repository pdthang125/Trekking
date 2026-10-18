-- ============================================================
-- TrekGuard AI — Supabase PostgreSQL Schema
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Profiles ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- ─── Track Points (PostGIS) ───────────────────────────────────

CREATE TABLE IF NOT EXISTS track_points (
  id BIGSERIAL PRIMARY KEY,
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  altitude FLOAT,
  accuracy FLOAT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial index for fast geo queries
CREATE INDEX IF NOT EXISTS idx_track_points_location
  ON track_points USING GIST(location);

CREATE INDEX IF NOT EXISTS idx_track_points_trip_id
  ON track_points(trip_id);

-- ─── Waypoints (PostGIS) ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS waypoints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  note TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  altitude FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_waypoints_location
  ON waypoints USING GIST(location);

-- ─── First Aid Guides (Cloud backup) ─────────────────────────

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

-- Full-text search index on Vietnamese content
CREATE INDEX IF NOT EXISTS idx_first_aid_guides_fts
  ON first_aid_guides USING GIN(to_tsvector('simple', condition_name_vi || ' ' || description_vi));

-- ─── Row-Level Security (RLS) ─────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE track_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE waypoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE first_aid_guides ENABLE ROW LEVEL SECURITY;

-- Profiles: users see/update only their own
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Trips: users own their trips
CREATE POLICY "trips_all_own" ON trips
  FOR ALL USING (auth.uid() = user_id);

-- Track Points: accessible through trip ownership
CREATE POLICY "track_points_through_trip" ON track_points
  FOR ALL USING (
    EXISTS (SELECT 1 FROM trips WHERE trips.id = track_points.trip_id AND trips.user_id = auth.uid())
  );

-- Waypoints: user owns their waypoints
CREATE POLICY "waypoints_all_own" ON waypoints
  FOR ALL USING (auth.uid() = user_id);

-- First Aid Guides: public read, admin write
CREATE POLICY "first_aid_guides_public_read" ON first_aid_guides
  FOR SELECT USING (true);

-- ─── Helper Views ─────────────────────────────────────────────

-- Trip summary with distance calculation
CREATE OR REPLACE VIEW trip_summaries AS
SELECT
  t.id,
  t.user_id,
  t.name,
  t.started_at,
  t.ended_at,
  t.total_distance_km,
  t.max_altitude,
  COUNT(DISTINCT w.id) AS waypoint_count,
  COUNT(tp.id) AS track_point_count
FROM trips t
LEFT JOIN waypoints w ON w.trip_id = t.id
LEFT JOIN track_points tp ON tp.trip_id = t.id
GROUP BY t.id;

-- ─── Updated_at trigger ───────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trips_updated_at BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

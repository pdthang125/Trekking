-- ============================================================
-- TrekGuard AI — Supabase PostgreSQL Schema V2 (đã sửa lỗi + đồng bộ)
-- Member 2: Mở rộng PostGIS + Elevation + SOS Events
-- Chạy SAU schema.sql. Có thể chạy lại nhiều lần (idempotent).
-- ============================================================

-- ─── SOS Events ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sos_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326),
  location_time TIMESTAMPTZ,
  message TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm')),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- FIX lỗi 42703: nếu sos_events đã tồn tại với cấu trúc cũ thì bổ sung cột thiếu
-- TRƯỚC khi tạo index.
ALTER TABLE sos_events ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326);
ALTER TABLE sos_events ADD COLUMN IF NOT EXISTS location_time TIMESTAMPTZ;
ALTER TABLE sos_events ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE sos_events ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE sos_events ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
ALTER TABLE sos_events ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Nếu bảng cũ lưu latitude/longitude rời, chuyển sang cột location
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'sos_events' AND column_name = 'latitude')
     AND EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name = 'sos_events' AND column_name = 'longitude')
  THEN
    UPDATE sos_events
    SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    WHERE location IS NULL AND latitude IS NOT NULL AND longitude IS NOT NULL;
  END IF;
END $$;

-- Đảm bảo ràng buộc status có mặt (không lỗi nếu đã có)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'sos_events_status_check') THEN
    ALTER TABLE sos_events
      ADD CONSTRAINT sos_events_status_check
      CHECK (status IN ('active', 'resolved', 'false_alarm')) NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sos_events_location
  ON sos_events USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_sos_events_user
  ON sos_events(user_id);

ALTER TABLE sos_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sos_events_own" ON sos_events;
CREATE POLICY "sos_events_own" ON sos_events
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ─── Elevation Cache ─────────────────────────────────────────
-- Bảng cache dùng chung, ghi qua service_role; bật RLS + cho phép đọc

CREATE TABLE IF NOT EXISTS elevation_cache (
  id BIGSERIAL PRIMARY KEY,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  elevation FLOAT NOT NULL,
  source TEXT DEFAULT 'open-elevation',
  fetched_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(latitude, longitude)
);
-- (UNIQUE đã tự tạo index trên (latitude, longitude) nên không cần index thêm)

ALTER TABLE elevation_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "elevation_cache_read" ON elevation_cache;
CREATE POLICY "elevation_cache_read" ON elevation_cache
  FOR SELECT USING (true);

-- ─── Waypoint bổ sung ────────────────────────────────────────

ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS
  waypoint_type TEXT DEFAULT 'generic'
  CHECK (waypoint_type IN (
    'generic', 'water_source', 'campsite', 'danger',
    'shelter', 'viewpoint', 'medical', 'food'
  ));

ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS icon_emoji TEXT DEFAULT '📍';
ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Đồng bộ với V1 (an toàn nếu V1 cũ chưa có)
ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE waypoints ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_waypoints_type ON waypoints(waypoint_type);

-- ─── Trip Statistics ─────────────────────────────────────────

ALTER TABLE trips ADD COLUMN IF NOT EXISTS elevation_gain FLOAT DEFAULT 0;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS elevation_loss FLOAT DEFAULT 0;
ALTER TABLE trips ADD COLUMN IF NOT EXISTS avg_speed_kmh FLOAT DEFAULT 0;

ALTER TABLE trips ADD COLUMN IF NOT EXISTS
  status TEXT DEFAULT 'active'
  CHECK (status IN ('active', 'paused', 'completed'));

-- ─── PostGIS RPC Functions ───────────────────────────────────

-- Tổng quãng đường (km) giữa các track point liên tiếp (dùng LAG, 1 lần quét)
CREATE OR REPLACE FUNCTION calculate_trip_distance(p_trip_id UUID)
RETURNS FLOAT AS $$
  SELECT COALESCE(SUM(seg) / 1000.0, 0)::FLOAT
  FROM (
    SELECT ST_Distance(
             location,
             LAG(location) OVER (ORDER BY recorded_at, id)
           ) AS seg
    FROM track_points
    WHERE trip_id = p_trip_id
  ) s
  WHERE seg IS NOT NULL;
$$ LANGUAGE sql STABLE;

-- Bounding box của một chuyến đi
CREATE OR REPLACE FUNCTION get_trip_bounds(p_trip_id UUID)
RETURNS TABLE(
  min_lat FLOAT,
  max_lat FLOAT,
  min_lng FLOAT,
  max_lng FLOAT
) AS $$
  SELECT
    MIN(ST_Y(location::geometry)),
    MAX(ST_Y(location::geometry)),
    MIN(ST_X(location::geometry)),
    MAX(ST_X(location::geometry))
  FROM track_points
  WHERE trip_id = p_trip_id;
$$ LANGUAGE sql STABLE;

-- Tìm waypoint gần nhất (bỏ qua waypoint đã xoá mềm)
-- Chạy với quyền người gọi => RLS tự lọc theo user
CREATE OR REPLACE FUNCTION find_nearest_waypoints(
  p_lat FLOAT,
  p_lng FLOAT,
  p_radius_meters FLOAT DEFAULT 5000,
  p_limit INT DEFAULT 10
)
RETURNS TABLE(
  id UUID,
  name TEXT,
  note TEXT,
  waypoint_type TEXT,
  distance_meters FLOAT,
  latitude FLOAT,
  longitude FLOAT,
  altitude FLOAT
) AS $$
  SELECT
    w.id,
    w.name,
    w.note,
    w.waypoint_type,
    ST_Distance(
      w.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    )::FLOAT AS distance_meters,
    ST_Y(w.location::geometry)::FLOAT AS latitude,
    ST_X(w.location::geometry)::FLOAT AS longitude,
    w.altitude
  FROM waypoints w
  WHERE ST_DWithin(
          w.location,
          ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
          p_radius_meters
        )
    AND w.deleted_at IS NULL
  ORDER BY distance_meters
  LIMIT p_limit;
$$ LANGUAGE sql STABLE;

-- ─── Updated_at triggers ─────────────────────────────────────
-- (update_updated_at() đã được định nghĩa trong schema.sql)

CREATE OR REPLACE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER waypoints_updated_at
  BEFORE UPDATE ON waypoints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── View trip_summaries: thêm các cột thống kê mới ──────────

-- DROP + CREATE (không dùng CREATE OR REPLACE vì thêm cột vào giữa view sẽ lỗi 42P16)
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
  t.elevation_gain,
  t.elevation_loss,
  t.avg_speed_kmh,
  t.status,
  (SELECT COUNT(*) FROM waypoints w
     WHERE w.trip_id = t.id AND w.deleted_at IS NULL) AS waypoint_count,
  (SELECT COUNT(*) FROM track_points tp
     WHERE tp.trip_id = t.id) AS track_point_count
FROM trips t;
-- ============================================
-- 数据迁移指南SQL脚本
-- 版本: v1.0
-- 说明: 提供数据迁移的SQL示例，需要根据实际情况调整
-- 注意: 执行前请确保已备份数据库
-- ============================================

-- ============================================
-- 1. 批次数据初始化
-- ============================================

-- 为每个pond创建默认批次（示例）
-- 注意：需要根据实际情况调整
INSERT INTO batches (species, pool_id, location, start_date, notes)
SELECT 
  'Litopenaeus vannamei' AS species,
  CAST(id AS CHAR) AS pool_id,  -- 将ponds.id转换为VARCHAR
  location,
  DATE(created_at) AS start_date,
  CONCAT('默认批次 - ', name) AS notes
FROM ponds
WHERE NOT EXISTS (
  SELECT 1 FROM batches WHERE batches.pool_id = CAST(ponds.id AS CHAR)
);

-- ============================================
-- 2. sensor_readings数据迁移
-- ============================================

-- 更新ts_utc字段（从recorded_at转换）
UPDATE sensor_readings 
SET ts_utc = CAST(recorded_at AS DATETIME(3))
WHERE ts_utc IS NULL AND recorded_at IS NOT NULL;

-- 更新ts_local字段（从ts_utc转换到日本时区）
UPDATE sensor_readings 
SET ts_local = CONVERT_TZ(ts_utc, 'UTC', 'Asia/Tokyo')
WHERE ts_local IS NULL AND ts_utc IS NOT NULL;

-- 更新metric和unit字段（通过JOIN获取）
-- 注意：需要根据实际的sensor_types表结构调整
UPDATE sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.id
INNER JOIN sensor_types st ON s.sensor_type_id = st.id
SET 
  sr.metric = st.type_name,
  sr.unit = st.unit
WHERE sr.metric IS NULL;

-- 更新pool_id字段（通过sensor关联pond获取）
UPDATE sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.id
SET sr.pool_id = CAST(s.pond_id AS CHAR)
WHERE sr.pool_id IS NULL;

-- 更新batch_id字段（关联到默认批次）
-- 注意：需要根据实际情况调整关联逻辑
UPDATE sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.id
INNER JOIN batches b ON b.pool_id = CAST(s.pond_id AS CHAR)
SET sr.batch_id = b.batch_id
WHERE sr.batch_id IS NULL
LIMIT 1;  -- 如果有多个批次，需要更精确的匹配逻辑

-- ============================================
-- 3. camera_images数据迁移
-- ============================================

-- 更新storage_uri字段（从image_url复制）
UPDATE camera_images 
SET storage_uri = image_url
WHERE storage_uri IS NULL AND image_url IS NOT NULL;

-- 更新width_px和height_px字段（从width和height复制）
UPDATE camera_images 
SET 
  width_px = width,
  height_px = height
WHERE (width_px IS NULL OR height_px IS NULL) AND (width IS NOT NULL OR height IS NOT NULL);

-- 更新ts_utc字段（从timestamp BIGINT毫秒转换）
UPDATE camera_images 
SET ts_utc = FROM_UNIXTIME(timestamp / 1000)
WHERE ts_utc IS NULL AND timestamp IS NOT NULL;

-- 更新ts_local字段（从ts_utc转换到日本时区）
UPDATE camera_images 
SET ts_local = CONVERT_TZ(ts_utc, 'UTC', 'Asia/Tokyo')
WHERE ts_local IS NULL AND ts_utc IS NOT NULL;

-- 更新pool_id字段（通过camera关联获取）
-- 注意：需要根据实际情况调整，可能需要通过devices表关联
-- UPDATE camera_images ci
-- INNER JOIN devices d ON ci.camera_id = d.id
-- SET ci.pool_id = CAST(d.pond_id AS CHAR)
-- WHERE ci.pool_id IS NULL;

-- 更新batch_id字段（关联到默认批次）
-- 注意：需要根据实际情况调整关联逻辑
-- UPDATE camera_images ci
-- INNER JOIN batches b ON b.pool_id = ci.pool_id
-- SET ci.batch_id = b.batch_id
-- WHERE ci.batch_id IS NULL;

-- ============================================
-- 4. shrimp_stats数据迁移
-- ============================================

-- 更新count字段（从total_live复制）
UPDATE shrimp_stats 
SET count = total_live
WHERE count IS NULL AND total_live IS NOT NULL;

-- 更新avg_length_mm字段（从size_mean_cm转换，cm × 10 = mm）
UPDATE shrimp_stats 
SET avg_length_mm = size_mean_cm * 10
WHERE avg_length_mm IS NULL AND size_mean_cm IS NOT NULL;

-- 更新est_weight_g_avg字段（从weight_mean_g复制）
UPDATE shrimp_stats 
SET est_weight_g_avg = weight_mean_g
WHERE est_weight_g_avg IS NULL AND weight_mean_g IS NOT NULL;

-- 更新confidence_avg字段（从conf转换，精度调整）
UPDATE shrimp_stats 
SET confidence_avg = CAST(conf AS DECIMAL(5,4))
WHERE confidence_avg IS NULL AND conf IS NOT NULL;

-- 更新ts_utc字段（从created_at_source转换）
UPDATE shrimp_stats 
SET ts_utc = CAST(created_at_source AS DATETIME(3))
WHERE ts_utc IS NULL AND created_at_source IS NOT NULL;

-- 更新ts_local字段（从ts_utc转换到日本时区）
UPDATE shrimp_stats 
SET ts_local = CONVERT_TZ(ts_utc, 'UTC', 'Asia/Tokyo')
WHERE ts_local IS NULL AND ts_utc IS NOT NULL;

-- 更新frame_id字段（通过时间戳匹配camera_images）
-- 注意：这是一个示例，需要根据实际情况调整匹配逻辑
-- UPDATE shrimp_stats ss
-- INNER JOIN camera_images ci ON 
--   ABS(UNIX_TIMESTAMP(ss.created_at_source) * 1000 - ci.timestamp) < 5000  -- 5秒内的匹配
-- SET ss.frame_id = ci.id
-- WHERE ss.frame_id IS NULL
-- LIMIT 1;  -- 如果有多个匹配，需要更精确的逻辑

-- ============================================
-- 5. 添加外键约束（在数据迁移完成后）
-- ============================================

-- 注意：以下外键约束需要在数据迁移完成且数据完整性验证通过后执行

-- sensor_readings表外键
-- ALTER TABLE sensor_readings 
-- ADD CONSTRAINT fk_sr_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id);

-- camera_images表外键
-- ALTER TABLE camera_images 
-- ADD CONSTRAINT fk_if_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id);

-- shrimp_stats表外键
-- ALTER TABLE shrimp_stats 
-- ADD CONSTRAINT fk_id_frame FOREIGN KEY (frame_id) REFERENCES camera_images(id);

-- ============================================
-- 6. 数据验证查询
-- ============================================

-- 检查批次数据
-- SELECT COUNT(*) AS batch_count FROM batches;
-- SELECT pool_id, COUNT(*) AS batch_count FROM batches GROUP BY pool_id;

-- 检查sensor_readings数据迁移
-- SELECT 
--   COUNT(*) AS total,
--   COUNT(batch_id) AS has_batch_id,
--   COUNT(pool_id) AS has_pool_id,
--   COUNT(ts_utc) AS has_ts_utc,
--   COUNT(ts_local) AS has_ts_local,
--   COUNT(metric) AS has_metric,
--   COUNT(unit) AS has_unit
-- FROM sensor_readings;

-- 检查camera_images数据迁移
-- SELECT 
--   COUNT(*) AS total,
--   COUNT(batch_id) AS has_batch_id,
--   COUNT(pool_id) AS has_pool_id,
--   COUNT(ts_utc) AS has_ts_utc,
--   COUNT(ts_local) AS has_ts_local,
--   COUNT(storage_uri) AS has_storage_uri
-- FROM camera_images;

-- 检查shrimp_stats数据迁移
-- SELECT 
--   COUNT(*) AS total,
--   COUNT(frame_id) AS has_frame_id,
--   COUNT(ts_utc) AS has_ts_utc,
--   COUNT(count) AS has_count,
--   COUNT(avg_length_mm) AS has_avg_length_mm,
--   COUNT(est_weight_g_avg) AS has_est_weight_g_avg
-- FROM shrimp_stats;


-- ============================================
-- 智能扩展现有表字段ALTER语句（只添加缺失字段）
-- 版本: v1.1
-- 说明: 检查字段是否存在，只添加缺失的字段
-- ============================================

USE cognitive;

-- ============================================
-- 1. sensor_readings表扩展
-- ============================================

-- 添加quality_flag字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'sensor_readings' AND COLUMN_NAME = 'quality_flag');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE sensor_readings ADD COLUMN quality_flag ENUM(''ok'',''missing'',''anomaly'') NOT NULL DEFAULT ''ok'' COMMENT ''质量标记'' AFTER unit;', 
    'SELECT ''quality_flag字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加checksum字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'sensor_readings' AND COLUMN_NAME = 'checksum');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE sensor_readings ADD COLUMN checksum VARCHAR(64) NULL COMMENT ''完整性校验'' AFTER quality_flag;', 
    'SELECT ''checksum字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加created_at字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'sensor_readings' AND COLUMN_NAME = 'created_at');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE sensor_readings ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''创建时间'' AFTER checksum;', 
    'SELECT ''created_at字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加updated_at字段（如果不存在）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'sensor_readings' AND COLUMN_NAME = 'updated_at');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE sensor_readings ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'' AFTER created_at;', 
    'SELECT ''updated_at字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引（如果不存在）
SET @idx_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'sensor_readings' AND INDEX_NAME = 'idx_sr_batch_metric_ts');
SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX idx_sr_batch_metric_ts ON sensor_readings (batch_id, metric, ts_utc);', 
    'SELECT ''索引idx_sr_batch_metric_ts已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 2. camera_images表扩展
-- ============================================

-- 添加batch_id字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'batch_id');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN batch_id BIGINT UNSIGNED NULL COMMENT ''批次ID（FK）'' AFTER camera_id;', 
    'SELECT ''batch_id字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加pool_id字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'pool_id');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN pool_id VARCHAR(64) NULL COMMENT ''池号/分区（冗余）'' AFTER batch_id;', 
    'SELECT ''pool_id字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加ts_utc字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'ts_utc');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN ts_utc DATETIME(3) NULL COMMENT ''UTC时间戳'' AFTER timestamp;', 
    'SELECT ''ts_utc字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加ts_local字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'ts_local');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN ts_local DATETIME(3) NULL COMMENT ''本地时间戳（日本时区）'' AFTER ts_utc;', 
    'SELECT ''ts_local字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加storage_uri字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'storage_uri');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN storage_uri VARCHAR(512) NULL COMMENT ''对象存储路径/URI'' AFTER image_url;', 
    'SELECT ''storage_uri字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加width_px字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'width_px');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN width_px INT NULL COMMENT ''宽度像素'' AFTER width;', 
    'SELECT ''width_px字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加height_px字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'height_px');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN height_px INT NULL COMMENT ''高度像素'' AFTER height;', 
    'SELECT ''height_px字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加codec字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'codec');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN codec VARCHAR(32) NULL COMMENT ''编解码（视频）'' AFTER format;', 
    'SELECT ''codec字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加quality_flag字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'quality_flag');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN quality_flag ENUM(''ok'',''missing'',''anomaly'') NOT NULL DEFAULT ''ok'' COMMENT ''质量标记'' AFTER codec;', 
    'SELECT ''quality_flag字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加checksum字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND COLUMN_NAME = 'checksum');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE camera_images ADD COLUMN checksum VARCHAR(64) NULL COMMENT ''完整性校验'' AFTER quality_flag;', 
    'SELECT ''checksum字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引
SET @idx_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'camera_images' AND INDEX_NAME = 'idx_if_batch_ts');
SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX idx_if_batch_ts ON camera_images (batch_id, ts_utc);', 
    'SELECT ''索引idx_if_batch_ts已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 3. shrimp_stats表扩展
-- ============================================

-- 添加frame_id字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'frame_id');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN frame_id BIGINT UNSIGNED NULL COMMENT ''图像帧ID（FK）'' AFTER id;', 
    'SELECT ''frame_id字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加ts_utc字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'ts_utc');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN ts_utc DATETIME(3) NULL COMMENT ''UTC时间戳（推理）'' AFTER frame_id;', 
    'SELECT ''ts_utc字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加count字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'count');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN count INT NULL COMMENT ''检测数量'' AFTER total_live;', 
    'SELECT ''count字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加avg_length_mm字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'avg_length_mm');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN avg_length_mm DECIMAL(12,3) NULL COMMENT ''平均长度（毫米）'' AFTER size_mean_cm;', 
    'SELECT ''avg_length_mm字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加avg_height_mm字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'avg_height_mm');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN avg_height_mm DECIMAL(12,3) NULL COMMENT ''平均高度（毫米）'' AFTER avg_length_mm;', 
    'SELECT ''avg_height_mm字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加est_weight_g_avg字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'est_weight_g_avg');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN est_weight_g_avg DECIMAL(12,3) NULL COMMENT ''平均估算体重（克）'' AFTER weight_mean_g;', 
    'SELECT ''est_weight_g_avg字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加feed_present字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'feed_present');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN feed_present TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否存在饲料（布尔）'' AFTER est_weight_g_avg;', 
    'SELECT ''feed_present字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加shrimp_shell_present字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'shrimp_shell_present');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN shrimp_shell_present TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否存在虾皮（布尔）'' AFTER feed_present;', 
    'SELECT ''shrimp_shell_present字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加model_name字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'model_name');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN model_name VARCHAR(128) NULL COMMENT ''模型名称'' AFTER shrimp_shell_present;', 
    'SELECT ''model_name字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加model_version字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'model_version');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN model_version VARCHAR(64) NULL COMMENT ''模型版本'' AFTER model_name;', 
    'SELECT ''model_version字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加confidence_avg字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'confidence_avg');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN confidence_avg DECIMAL(5,4) NULL COMMENT ''平均置信度'' AFTER conf;', 
    'SELECT ''confidence_avg字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加notes字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND COLUMN_NAME = 'notes');
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE shrimp_stats ADD COLUMN notes TEXT NULL COMMENT ''备注'' AFTER confidence_avg;', 
    'SELECT ''notes字段已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加索引
SET @idx_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND INDEX_NAME = 'idx_id_frame');
SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX idx_id_frame ON shrimp_stats (frame_id);', 
    'SELECT ''索引idx_id_frame已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND INDEX_NAME = 'idx_id_ts');
SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX idx_id_ts ON shrimp_stats (ts_utc);', 
    'SELECT ''索引idx_id_ts已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = 'cognitive' AND TABLE_NAME = 'shrimp_stats' AND INDEX_NAME = 'idx_id_modelver');
SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX idx_id_modelver ON shrimp_stats (model_name, model_version);', 
    'SELECT ''索引idx_id_modelver已存在'' AS message;');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '所有字段检查完成！' AS status;


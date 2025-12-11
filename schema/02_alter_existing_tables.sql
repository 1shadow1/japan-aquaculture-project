-- ============================================
-- 扩展现有表字段ALTER语句
-- 版本: v1.0
-- 说明: 为现有表添加计划中需要的字段
-- 注意: 
-- 1. 执行前请确保已备份数据库
-- 2. 所有新字段都设置为NULL或默认值，不影响现有数据
-- 3. 外键约束在数据迁移完成后再添加
-- ============================================

-- ============================================
-- 1. devices表扩展
-- ============================================

-- 添加type字段（设备类型枚举）
-- 注意：如果device_type_id已存在，可以通过JOIN获取类型，或直接添加此字段
ALTER TABLE devices 
ADD COLUMN type ENUM('sensor','camera','feeder') NULL COMMENT '设备类型' AFTER device_id;

-- 添加vendor字段（供应商）
-- 注意：如果manufacturer字段已存在且可用，可以不用添加此字段
ALTER TABLE devices 
ADD COLUMN vendor VARCHAR(128) NULL COMMENT '供应商' AFTER model;

-- 添加calibration_info字段（校准信息）
ALTER TABLE devices 
ADD COLUMN calibration_info TEXT NULL COMMENT '校准信息' AFTER vendor;

-- 添加索引（如果计划需要）
-- CREATE INDEX idx_devices_type_pool ON devices (type, pool_id);
-- 注意：现有表使用pond_id，计划表使用pool_id，需要确认映射关系

-- ============================================
-- 2. sensor_readings表扩展
-- ============================================

-- 添加batch_id字段（批次ID）
ALTER TABLE sensor_readings 
ADD COLUMN batch_id BIGINT UNSIGNED NULL COMMENT '批次ID（FK）' AFTER sensor_id;

-- 添加pool_id字段（池号/分区）
ALTER TABLE sensor_readings 
ADD COLUMN pool_id VARCHAR(64) NULL COMMENT '池号/分区（冗余便于查询）' AFTER batch_id;

-- 添加ts_utc字段（UTC时间戳，毫秒精度）
-- 注意：如果recorded_at字段可用，可以从此字段转换
ALTER TABLE sensor_readings 
ADD COLUMN ts_utc DATETIME(3) NULL COMMENT 'UTC时间戳（毫秒）' AFTER recorded_at;

-- 添加ts_local字段（本地时间戳，日本时区）
ALTER TABLE sensor_readings 
ADD COLUMN ts_local DATETIME(3) NULL COMMENT '本地时间戳（日本时区）' AFTER ts_utc;

-- 添加metric字段（指标名称）
-- 注意：需要通过JOIN sensors和sensor_types表获取数据
ALTER TABLE sensor_readings 
ADD COLUMN metric VARCHAR(32) NULL COMMENT '指标，如 do/ph/temp/salinity/conductivity 等' AFTER ts_local;

-- 添加unit字段（计量单位）
-- 注意：需要通过JOIN sensors和sensor_types表获取数据
ALTER TABLE sensor_readings 
ADD COLUMN unit VARCHAR(16) NULL COMMENT '计量单位' AFTER metric;

-- 添加quality_flag字段（质量标记）
ALTER TABLE sensor_readings 
ADD COLUMN quality_flag ENUM('ok','missing','anomaly') NOT NULL DEFAULT 'ok' COMMENT '质量标记' AFTER unit;

-- 添加checksum字段（完整性校验）
ALTER TABLE sensor_readings 
ADD COLUMN checksum VARCHAR(64) NULL COMMENT '完整性校验' AFTER quality_flag;

-- 添加created_at字段
ALTER TABLE sensor_readings 
ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' AFTER checksum;

-- 添加updated_at字段
ALTER TABLE sensor_readings 
ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER created_at;

-- 添加索引
CREATE INDEX idx_sr_batch_metric_ts ON sensor_readings (batch_id, metric, ts_utc);

-- 注意：外键约束在数据迁移完成后再添加
-- ALTER TABLE sensor_readings 
-- ADD CONSTRAINT fk_sr_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id);

-- ============================================
-- 3. camera_images表扩展（对应image_frames）
-- ============================================

-- 添加batch_id字段（批次ID）
ALTER TABLE camera_images 
ADD COLUMN batch_id BIGINT UNSIGNED NULL COMMENT '批次ID（FK）' AFTER camera_id;

-- 添加pool_id字段（池号/分区）
ALTER TABLE camera_images 
ADD COLUMN pool_id VARCHAR(64) NULL COMMENT '池号/分区（冗余）' AFTER batch_id;

-- 添加ts_utc字段（UTC时间戳）
-- 注意：需要从timestamp（BIGINT毫秒）转换
ALTER TABLE camera_images 
ADD COLUMN ts_utc DATETIME(3) NULL COMMENT 'UTC时间戳' AFTER timestamp;

-- 添加ts_local字段（本地时间戳，日本时区）
ALTER TABLE camera_images 
ADD COLUMN ts_local DATETIME(3) NULL COMMENT '本地时间戳（日本时区）' AFTER ts_utc;

-- 添加storage_uri字段（对象存储路径）
-- 注意：如果image_url字段可用，可以从此字段复制数据
ALTER TABLE camera_images 
ADD COLUMN storage_uri VARCHAR(512) NULL COMMENT '对象存储路径/URI' AFTER image_url;

-- 添加width_px字段（宽度像素）
-- 注意：如果width字段可用，可以从此字段复制数据
ALTER TABLE camera_images 
ADD COLUMN width_px INT NULL COMMENT '宽度像素' AFTER width;

-- 添加height_px字段（高度像素）
-- 注意：如果height字段可用，可以从此字段复制数据
ALTER TABLE camera_images 
ADD COLUMN height_px INT NULL COMMENT '高度像素' AFTER height;

-- 添加codec字段（视频编解码）
ALTER TABLE camera_images 
ADD COLUMN codec VARCHAR(32) NULL COMMENT '编解码（视频）' AFTER format;

-- 添加quality_flag字段（质量标记）
ALTER TABLE camera_images 
ADD COLUMN quality_flag ENUM('ok','missing','anomaly') NOT NULL DEFAULT 'ok' COMMENT '质量标记' AFTER codec;

-- 添加checksum字段（完整性校验）
ALTER TABLE camera_images 
ADD COLUMN checksum VARCHAR(64) NULL COMMENT '完整性校验' AFTER quality_flag;

-- 添加索引
CREATE INDEX idx_if_batch_ts ON camera_images (batch_id, ts_utc);

-- 注意：外键约束在数据迁移完成后再添加
-- ALTER TABLE camera_images 
-- ADD CONSTRAINT fk_if_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id);

-- ============================================
-- 4. shrimp_stats表扩展（对应image_detections）
-- ============================================

-- 添加frame_id字段（图像帧ID，关键字段）
-- 注意：需要建立与camera_images或image_frames的关联
ALTER TABLE shrimp_stats 
ADD COLUMN frame_id BIGINT UNSIGNED NULL COMMENT '图像帧ID（FK）' AFTER id;

-- 添加ts_utc字段（UTC时间戳）
ALTER TABLE shrimp_stats 
ADD COLUMN ts_utc DATETIME(3) NULL COMMENT 'UTC时间戳（推理）' AFTER frame_id;

-- 添加count字段（检测数量）
-- 注意：可以从total_live字段复制数据
ALTER TABLE shrimp_stats 
ADD COLUMN count INT NULL COMMENT '检测数量' AFTER total_live;

-- 添加avg_length_mm字段（平均长度，毫米）
-- 注意：需要从size_mean_cm转换（cm × 10 = mm）
ALTER TABLE shrimp_stats 
ADD COLUMN avg_length_mm DECIMAL(12,3) NULL COMMENT '平均长度（毫米）' AFTER size_mean_cm;

-- 添加avg_height_mm字段（平均高度，毫米）
ALTER TABLE shrimp_stats 
ADD COLUMN avg_height_mm DECIMAL(12,3) NULL COMMENT '平均高度（毫米）' AFTER avg_length_mm;

-- 添加est_weight_g_avg字段（平均估算体重，克）
-- 注意：可以从weight_mean_g字段复制数据
ALTER TABLE shrimp_stats 
ADD COLUMN est_weight_g_avg DECIMAL(12,3) NULL COMMENT '平均估算体重（克）' AFTER weight_mean_g;

-- 添加feed_present字段（是否存在饲料）
ALTER TABLE shrimp_stats 
ADD COLUMN feed_present TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否存在饲料（布尔）' AFTER est_weight_g_avg;

-- 添加shrimp_shell_present字段（是否存在虾皮）
ALTER TABLE shrimp_stats 
ADD COLUMN shrimp_shell_present TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否存在虾皮（布尔）' AFTER feed_present;

-- 添加model_name字段（模型名称）
ALTER TABLE shrimp_stats 
ADD COLUMN model_name VARCHAR(128) NULL COMMENT '模型名称' AFTER shrimp_shell_present;

-- 添加model_version字段（模型版本）
ALTER TABLE shrimp_stats 
ADD COLUMN model_version VARCHAR(64) NULL COMMENT '模型版本' AFTER model_name;

-- 添加confidence_avg字段（平均置信度）
-- 注意：需要从conf字段转换（精度调整）
ALTER TABLE shrimp_stats 
ADD COLUMN confidence_avg DECIMAL(5,4) NULL COMMENT '平均置信度' AFTER conf;

-- 添加notes字段（备注）
ALTER TABLE shrimp_stats 
ADD COLUMN notes TEXT NULL COMMENT '备注' AFTER confidence_avg;

-- 添加索引
CREATE INDEX idx_id_frame ON shrimp_stats (frame_id);
CREATE INDEX idx_id_ts ON shrimp_stats (ts_utc);
CREATE INDEX idx_id_modelver ON shrimp_stats (model_name, model_version);

-- 注意：外键约束在数据迁移完成后再添加
-- ALTER TABLE shrimp_stats 
-- ADD CONSTRAINT fk_id_frame FOREIGN KEY (frame_id) REFERENCES camera_images(id);
-- 或者如果使用image_frames表：
-- ALTER TABLE shrimp_stats 
-- ADD CONSTRAINT fk_id_frame FOREIGN KEY (frame_id) REFERENCES image_frames(id);

-- ============================================
-- 验证语句
-- ============================================
-- 检查新添加的字段
-- DESCRIBE devices;
-- DESCRIBE sensor_readings;
-- DESCRIBE camera_images;
-- DESCRIBE shrimp_stats;


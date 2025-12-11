-- ============================================
-- 日本陆上养殖数据处理系统 - MySQL DDL
-- 版本: v1.0
-- 数据库: aquaculture
-- 字符集: utf8mb4
-- 引擎: InnoDB
-- ============================================

-- 数据库与全局设置
CREATE DATABASE IF NOT EXISTS aquaculture
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE aquaculture;

-- 1) 批次信息
CREATE TABLE IF NOT EXISTS batches (
  batch_id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '批次ID（主键）',
  species            VARCHAR(64) NOT NULL DEFAULT 'Litopenaeus vannamei' COMMENT '物种（默认南美白对虾学名）',
  pool_id            VARCHAR(64) NOT NULL COMMENT '池号/分区标识',
  location           VARCHAR(128) NULL COMMENT '场地/车间位置',
  seed_origin        VARCHAR(128) NULL COMMENT '苗种来源',
  stocking_density   DECIMAL(10,2) NULL COMMENT '放养密度（尾/㎡或尾/m³）',
  start_date         DATE NOT NULL COMMENT '开始日期',
  end_date           DATE NULL COMMENT '结束日期（可空）',
  notes              TEXT NULL COMMENT '备注',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) COMMENT='养殖批次信息';

CREATE INDEX idx_batches_pool_dates ON batches (pool_id, start_date, end_date);

-- 2) 设备清单
CREATE TABLE IF NOT EXISTS devices (
  device_id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '设备ID（主键）',
  type               ENUM('sensor','camera','feeder') NOT NULL COMMENT '设备类型',
  model              VARCHAR(128) NULL COMMENT '设备型号',
  install_location   VARCHAR(128) NULL COMMENT '安装位置',
  pool_id            VARCHAR(64) NULL COMMENT '池号/分区（如适用）',
  status             ENUM('active','inactive','maintenance','fault') NOT NULL DEFAULT 'active' COMMENT '设备状态',
  vendor             VARCHAR(128) NULL COMMENT '供应商',
  calibration_info   TEXT NULL COMMENT '校准信息',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) COMMENT='设备（传感器/摄像头/喂食机）清单';

CREATE INDEX idx_devices_type_pool ON devices (type, pool_id);

-- 3) 传感器读数（窄表）
CREATE TABLE IF NOT EXISTS sensor_readings (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  device_id          BIGINT UNSIGNED NOT NULL COMMENT '设备ID（FK）',
  batch_id           BIGINT UNSIGNED NULL COMMENT '批次ID（FK）',
  pool_id            VARCHAR(64) NULL COMMENT '池号/分区（冗余便于查询）',
  ts_utc             DATETIME(3) NOT NULL COMMENT 'UTC时间戳（毫秒）',
  ts_local           DATETIME(3) NULL COMMENT '本地时间戳（日本时区）',
  metric             VARCHAR(32) NOT NULL COMMENT '指标，如 do/ph/temp/salinity/conductivity 等',
  value              DOUBLE NOT NULL COMMENT '数值',
  unit               VARCHAR(16) NULL COMMENT '计量单位',
  quality_flag       ENUM('ok','missing','anomaly') NOT NULL DEFAULT 'ok' COMMENT '质量标记',
  checksum           VARCHAR(64) NULL COMMENT '完整性校验',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  CONSTRAINT fk_sr_device FOREIGN KEY (device_id) REFERENCES devices(device_id),
  CONSTRAINT fk_sr_batch  FOREIGN KEY (batch_id)  REFERENCES batches(batch_id)
) COMMENT='传感器读数（窄表设计，metric+value）';

CREATE INDEX idx_sr_device_ts ON sensor_readings (device_id, ts_utc);
CREATE INDEX idx_sr_batch_metric_ts ON sensor_readings (batch_id, metric, ts_utc);

-- 4) 喂食机记录
CREATE TABLE IF NOT EXISTS feeders_logs (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  feeder_id          BIGINT UNSIGNED NOT NULL COMMENT '喂食机设备ID（FK）',
  batch_id           BIGINT UNSIGNED NULL COMMENT '批次ID（FK）',
  pool_id            VARCHAR(64) NULL COMMENT '池号/分区（冗余）',
  ts_utc             DATETIME(3) NOT NULL COMMENT 'UTC时间戳',
  ts_local           DATETIME(3) NULL COMMENT '本地时间戳',
  feed_amount_g      DECIMAL(12,3) NULL COMMENT '投喂量（克）',
  run_time_s         INT NULL COMMENT '运行时长（秒）',
  status             ENUM('ok','warning','error') NOT NULL DEFAULT 'ok' COMMENT '状态',
  leftover_estimate_g DECIMAL(12,3) NULL COMMENT '剩余饵料估计（克）',
  notes              TEXT NULL COMMENT '备注',
  checksum           VARCHAR(64) NULL COMMENT '完整性校验',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  CONSTRAINT fk_fl_feeder FOREIGN KEY (feeder_id) REFERENCES devices(device_id),
  CONSTRAINT fk_fl_batch  FOREIGN KEY (batch_id)  REFERENCES batches(batch_id)
) COMMENT='喂食机运行记录';

CREATE INDEX idx_fl_feeder_ts ON feeders_logs (feeder_id, ts_utc);
CREATE INDEX idx_fl_batch_ts   ON feeders_logs (batch_id, ts_utc);

-- 5) 图像帧与元数据
CREATE TABLE IF NOT EXISTS image_frames (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  camera_id          BIGINT UNSIGNED NOT NULL COMMENT '摄像头设备ID（FK）',
  batch_id           BIGINT UNSIGNED NULL COMMENT '批次ID（FK）',
  pool_id            VARCHAR(64) NULL COMMENT '池号/分区（冗余）',
  ts_utc             DATETIME(3) NOT NULL COMMENT 'UTC时间戳',
  ts_local           DATETIME(3) NULL COMMENT '本地时间戳',
  storage_uri        VARCHAR(512) NOT NULL COMMENT '对象存储路径/URI',
  width_px           INT NULL COMMENT '宽度像素',
  height_px          INT NULL COMMENT '高度像素',
  format             VARCHAR(16) NULL COMMENT '格式（jpg/png/mp4）',
  codec              VARCHAR(32) NULL COMMENT '编解码（视频）',
  quality_flag       ENUM('ok','missing','anomaly') NOT NULL DEFAULT 'ok' COMMENT '质量标记',
  checksum           VARCHAR(64) NULL COMMENT '完整性校验',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  CONSTRAINT fk_if_camera FOREIGN KEY (camera_id) REFERENCES devices(device_id),
  CONSTRAINT fk_if_batch  FOREIGN KEY (batch_id)  REFERENCES batches(batch_id)
) COMMENT='图像帧与元数据';

CREATE INDEX idx_if_camera_ts ON image_frames (camera_id, ts_utc);
CREATE INDEX idx_if_batch_ts  ON image_frames (batch_id, ts_utc);

-- 6) 图像检测汇总结果
CREATE TABLE IF NOT EXISTS image_detections (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  frame_id           BIGINT UNSIGNED NOT NULL COMMENT '图像帧ID（FK）',
  ts_utc             DATETIME(3) NOT NULL COMMENT 'UTC时间戳（推理）',
  count              INT NOT NULL COMMENT '检测数量',
  avg_length_mm      DECIMAL(12,3) NULL COMMENT '平均长度（毫米）',
  avg_height_mm      DECIMAL(12,3) NULL COMMENT '平均高度（毫米）',
  est_weight_g_avg   DECIMAL(12,3) NULL COMMENT '平均估算体重（克）',
  feed_present       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否存在饲料（布尔）',
  shrimp_shell_present TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否存在虾皮（布尔）',
  model_name         VARCHAR(128) NULL COMMENT '模型名称',
  model_version      VARCHAR(64) NULL COMMENT '模型版本',
  confidence_avg     DECIMAL(5,4) NULL COMMENT '平均置信度',
  notes              TEXT NULL COMMENT '备注',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  CONSTRAINT fk_id_frame FOREIGN KEY (frame_id) REFERENCES image_frames(id)
) COMMENT='图像检测汇总（数量/尺寸/体重/饲料/虾皮）';

CREATE INDEX idx_id_frame    ON image_detections (frame_id);
CREATE INDEX idx_id_ts       ON image_detections (ts_utc);
CREATE INDEX idx_id_modelver ON image_detections (model_name, model_version);

-- 7) 操作日志
CREATE TABLE IF NOT EXISTS operations_logs (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  operator_id        VARCHAR(64) NOT NULL COMMENT '操作人',
  batch_id           BIGINT UNSIGNED NULL COMMENT '批次ID（FK）',
  pool_id            VARCHAR(64) NULL COMMENT '池号/分区',
  ts_utc             DATETIME(3) NOT NULL COMMENT 'UTC时间戳',
  ts_local           DATETIME(3) NULL COMMENT '本地时间戳',
  action_type        VARCHAR(64) NOT NULL COMMENT '操作类型（投料/水质调控/巡检/清洗等）',
  remarks            TEXT NULL COMMENT '备注',
  attachment_uri     VARCHAR(512) NULL COMMENT '附件URI',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  CONSTRAINT fk_ol_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id)
) COMMENT='人工操作日志';

CREATE INDEX idx_ol_operator_ts ON operations_logs (operator_id, ts_utc);
CREATE INDEX idx_ol_batch_ts    ON operations_logs (batch_id, ts_utc);

-- 8) 养殖手册文档
CREATE TABLE IF NOT EXISTS manuals_docs (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  doc_uri            VARCHAR(512) NOT NULL COMMENT '文档URI',
  version            VARCHAR(64) NULL COMMENT '版本',
  source             VARCHAR(64) NULL COMMENT '来源',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  notes              TEXT NULL COMMENT '备注'
) COMMENT='养殖手册/文档索引';

CREATE INDEX idx_md_version ON manuals_docs (version);
CREATE INDEX idx_md_created ON manuals_docs (created_at);

-- 9) 往期养殖记录（结构化）
CREATE TABLE IF NOT EXISTS history_records (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  batch_id           BIGINT UNSIGNED NULL COMMENT '批次ID（FK）',
  metric_name        VARCHAR(64) NOT NULL COMMENT '指标名称',
  value              VARCHAR(128) NOT NULL COMMENT '值（文本存储）',
  unit               VARCHAR(16) NULL COMMENT '单位',
  ts_utc             DATETIME(3) NULL COMMENT 'UTC时间戳',
  ts_local           DATETIME(3) NULL COMMENT '本地时间戳',
  notes              TEXT NULL COMMENT '备注',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  CONSTRAINT fk_hr_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id)
) COMMENT='往期养殖记录（结构化）';

CREATE INDEX idx_hr_batch_metric_ts ON history_records (batch_id, metric_name, ts_utc);

-- ============================================
-- 示例校验语句（导入后可执行）
-- ============================================
-- SHOW TABLES;
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='aquaculture';
-- SELECT table_name, index_name, column_name FROM information_schema.statistics WHERE table_schema='aquaculture' ORDER BY table_name, index_name;






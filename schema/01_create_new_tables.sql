-- ============================================
-- 创建新表DDL脚本
-- 版本: v1.0
-- 说明: 根据数据处理计划创建缺失的表
-- 注意: 执行前请确保已备份数据库
-- ============================================

-- 1) 批次信息表
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

-- CREATE INDEX idx_batches_pool_dates ON batches (pool_id, start_date, end_date);
-- 注意：如果索引已存在，请手动执行或忽略此错误

-- 2) 喂食机记录表
CREATE TABLE IF NOT EXISTS feeders_logs (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  feeder_id          INT NOT NULL COMMENT '喂食机设备ID（FK，引用devices.id）',
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
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
  -- 注意：外键约束将在表创建后添加，因为devices表可能在不同数据库中
  -- CONSTRAINT fk_fl_feeder FOREIGN KEY (feeder_id) REFERENCES devices(id) ON DELETE CASCADE,
  -- CONSTRAINT fk_fl_batch  FOREIGN KEY (batch_id)  REFERENCES batches(batch_id) ON DELETE SET NULL
) COMMENT='喂食机运行记录';

-- CREATE INDEX idx_fl_feeder_ts ON feeders_logs (feeder_id, ts_utc);
-- CREATE INDEX idx_fl_batch_ts   ON feeders_logs (batch_id, ts_utc);
-- 注意：如果索引已存在，请手动执行或忽略此错误

-- 3) 操作日志表
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
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
  -- 注意：外键约束将在batches表创建后添加
  -- CONSTRAINT fk_ol_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id)
) COMMENT='人工操作日志';

-- CREATE INDEX idx_ol_operator_ts ON operations_logs (operator_id, ts_utc);
-- CREATE INDEX idx_ol_batch_ts    ON operations_logs (batch_id, ts_utc);
-- 注意：如果索引已存在，请手动执行或忽略此错误

-- 4) 养殖手册文档表
CREATE TABLE IF NOT EXISTS manuals_docs (
  id                 BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  doc_uri            VARCHAR(512) NOT NULL COMMENT '文档URI',
  version            VARCHAR(64) NULL COMMENT '版本',
  source             VARCHAR(64) NULL COMMENT '来源',
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  notes              TEXT NULL COMMENT '备注'
) COMMENT='养殖手册/文档索引';

-- CREATE INDEX idx_md_version ON manuals_docs (version);
-- CREATE INDEX idx_md_created ON manuals_docs (created_at);
-- 注意：如果索引已存在，请手动执行或忽略此错误

-- 5) 往期养殖记录表
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
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
  -- 注意：外键约束将在batches表创建后添加
  -- CONSTRAINT fk_hr_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id) ON DELETE SET NULL
) COMMENT='往期养殖记录（结构化）';

-- CREATE INDEX idx_hr_batch_metric_ts ON history_records (batch_id, metric_name, ts_utc);
-- 注意：如果索引已存在，请手动执行或忽略此错误

-- ============================================
-- 验证语句
-- ============================================
-- SELECT 'batches' AS table_name, COUNT(*) AS row_count FROM batches
-- UNION ALL
-- SELECT 'feeders_logs', COUNT(*) FROM feeders_logs
-- UNION ALL
-- SELECT 'operations_logs', COUNT(*) FROM operations_logs
-- UNION ALL
-- SELECT 'manuals_docs', COUNT(*) FROM manuals_docs
-- UNION ALL
-- SELECT 'history_records', COUNT(*) FROM history_records;


# 日本陆上养殖数据处理项目

## 项目简介

本项目用于管理日本地区陆上工厂化养殖的南美白对虾数据采集、处理、质量管理与验收全流程。

**版本：** v1.0  
**编制日期：** 2025.11.18  
**负责人/单位：** AI产业部

## 项目结构

```
japan-aquaculture-project/
├── README.md                           # 项目说明文档
├── docs/                               # 文档目录
│   ├── 01-数据源清单.md                 # 数据源清单文档
│   ├── 02-数据收集方式.md               # 数据收集方式文档
│   ├── 03-数据处理标准.md               # 数据处理标准文档
│   ├── 04-数据验收流程.md               # 数据验收流程文档
│   ├── 数据库表结构对比分析.md          # 数据库表结构对比分析报告
│   └── 《日本陆上养殖数据处理计划》.doc  # 原始Word文档
├── schema/                             # 数据库结构定义
│   ├── mysql_aquaculture_ddl.sql       # MySQL数据库DDL脚本（完整设计）
│   ├── 01_create_new_tables.sql        # 创建新表DDL脚本
│   ├── 02_alter_existing_tables.sql    # 扩展现有表ALTER语句
│   └── 03_data_migration_guide.sql     # 数据迁移指南SQL脚本
├── scripts/                            # 脚本目录
│   ├── init_database.sh                # 数据库初始化脚本
│   └── validate_schema.sh              # 数据库结构验证脚本
├── config/                             # 配置文件目录
│   └── database.conf.example           # 数据库配置示例
├── data/                               # 数据目录
│   ├── raw/                            # 原始数据
│   ├── processed/                      # 处理后的数据
│   └── annotations/                   # 标注数据
└── logs/                               # 日志目录
```

## 快速开始

### 1. 数据库初始化

```bash
# 使用脚本初始化（推荐）
./scripts/init_database.sh

# 或手动执行
mysql -u root -p < schema/mysql_aquaculture_ddl.sql
```

### 2. 验证数据库结构

```bash
./scripts/validate_schema.sh
```

### 3. 数据库迁移（如果已有现有数据库）

如果您的环境中已有现有数据库，需要执行迁移：

**方式一：使用自动化脚本（推荐）**

```bash
# 使用自动化脚本执行所有变更
./scripts/apply_schema_changes.sh
```

**方式二：手动执行SQL文件**

```bash
# 1. 创建新表
mysql -u root -p < schema/01_create_new_tables.sql

# 2. 扩展现有表
mysql -u root -p < schema/02_alter_existing_tables.sql

# 3. 数据迁移（需要根据实际情况调整）
mysql -u root -p < schema/03_data_migration_guide.sql
```

**方式三：通过Python脚本执行**

```bash
# 使用Python脚本执行SQL文件
python3 scripts/execute_sql_via_mcp.py schema/01_create_new_tables.sql -u root -d aquaculture
```

**注意：** 执行迁移前请务必备份数据库！

### 4. 查看文档

- **数据处理计划：** `docs/01-数据源清单.md`、`docs/02-数据收集方式.md`、`docs/03-数据处理标准.md`、`docs/04-数据验收流程.md`
- **数据库对比分析：** `docs/数据库表结构对比分析.md`

## 核心功能

### 数据分类

- **按类型**：文本数据、图像/视频数据
- **按来源**：自动标注、人工标注
- **按格式**：结构化（MySQL）、非结构化、半结构化（CSV/JSON/XML/YAML）
- **按频率**：高频变化、低频变化

### 数据源

1. **传感器数据**：水温、浊度、pH、溶解氧、水位、盐度、氨氮、亚硝酸盐、光照强度、室内温湿度
2. **图像目标监测数据**：检测数量、长度、高度、预估体重、饲料/虾皮存在标记
3. **喂食机数据**：喂食时间、喂食量、喂食次数、剩余饵料估计
4. **操作日志数据**：人工操作记录
5. **养殖手册文档**：操作流程、SOP
6. **养殖记录**：批次信息、苗种、放养密度、成活率等

### 数据库设计

数据库采用MySQL 8.0+，包含以下核心表：

- `batches` - 批次信息
- `devices` - 设备清单
- `sensor_readings` - 传感器读数（窄表设计）
- `feeders_logs` - 喂食机记录
- `image_frames` - 图像帧与元数据
- `image_detections` - 图像检测汇总结果
- `operations_logs` - 操作日志
- `manuals_docs` - 养殖手册文档
- `history_records` - 往期养殖记录

详细表结构请参考：`schema/mysql_aquaculture_ddl.sql`

## 数据处理流程

1. **原始数据接收**：完整性校验、格式校验
2. **清洗与标准化**：时间标准化、单位换算、缺失值处理、异常值处理
3. **转换与入库**：结构化入库、非结构化入对象存储
4. **图像数据处理**：算法推理、标注审核
5. **质量监控**：质量指标监控、问题处理

## 数据质量管理

### 核心质量指标

- 完整性（缺失比例）
- 一致性（字段与单位统一）
- 准确性（与标准或人工校验一致度）
- 及时性（延迟）
- 可追溯性（元数据完整度）

### 规则与阈值

- 溶氧 DO 范围：0–20 mg/L
- pH 范围：6.5–9.0
- 时间戳延迟：设备到入库≤5分钟（可配置）
- 图像检测：count≥0、confidence_avg≥0.6

## 开发规范

### 命名规范

- 数据库表名：小写+下划线（如：`sensor_readings`）
- 时间字段：统一使用 `ts_utc`（UTC时间）和 `ts_local`（本地时间）
- 文件命名：遵循文档中的命名规范

### 数据库规范

- 字符集：utf8mb4
- 引擎：InnoDB
- 时间精度：DATETIME(3)（毫秒级）
- 布尔类型：TINYINT(1)（0/1）

## 角色与职责

- **数据所有者（Owner）**：确定数据需求与质量目标
- **数据管理员（Steward）**：定义标准、维护目录与规则
- **审核员（Reviewer）**：执行人工验收与抽检
- **设备维护（Ops）**：设备与网络保障、故障排查
- **分析师/建模（Analyst/ML）**：消费数据、反馈质量需求

## 里程碑与排期

- **第1周**：确认数据源与指标清单，完善元数据与命名规范
- **第2–3周**：搭建采集与处理管道，制定质量与验收规则
- **第4周**：试运行与抽检验收，形成首版验收报告与审计流程
- **持续**：季度审计与优化

## 相关文档

### 数据处理计划
- [数据源清单](docs/01-数据源清单.md)
- [数据收集方式](docs/02-数据收集方式.md)
- [数据处理标准](docs/03-数据处理标准.md)
- [数据验收流程](docs/04-数据验收流程.md)

### 数据库相关
- [数据库DDL脚本（完整设计）](schema/mysql_aquaculture_ddl.sql)
- [数据库表结构对比分析](docs/数据库表结构对比分析.md)
- [创建新表脚本](schema/01_create_new_tables.sql)
- [扩展现有表脚本](schema/02_alter_existing_tables.sql)
- [数据迁移指南](schema/03_data_migration_guide.sql)

## 许可证

本项目由AI产业部所有。

## 联系方式

如有问题或建议，请联系项目负责人。

---

**最后更新：** 2025.11.18






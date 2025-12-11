# 快速执行指南

## 数据库结构变更执行

### 方式一：使用自动化脚本（推荐）

在交互式终端中运行：

```bash
cd /srv/japan-aquaculture-project
./scripts/apply_schema_changes.sh
```

脚本会：
1. 提示输入MySQL密码
2. 测试数据库连接
3. 创建新表（batches, feeders_logs, operations_logs, manuals_docs, history_records）
4. 扩展现有表（devices, sensor_readings, camera_images, shrimp_stats）
5. 可选执行数据迁移
6. 验证执行结果

### 方式二：通过环境变量传递密码

```bash
export MYSQL_PASSWORD="your_password"
cd /srv/japan-aquaculture-project
./scripts/apply_schema_changes.sh
```

### 方式三：手动执行SQL文件

```bash
# 1. 创建新表
mysql -u root -p aquaculture < schema/01_create_new_tables.sql

# 2. 扩展现有表
mysql -u root -p aquaculture < schema/02_alter_existing_tables.sql

# 3. 数据迁移（可选，需要根据实际情况调整）
mysql -u root -p aquaculture < schema/03_data_migration_guide.sql
```

### 方式四：使用Python脚本

```bash
cd /srv/japan-aquaculture-project
python3 scripts/execute_sql_via_mcp.py schema/01_create_new_tables.sql -u root -d aquaculture
```

## 执行前检查清单

- [ ] 已备份数据库
- [ ] MySQL服务正在运行
- [ ] 有MySQL root密码或相应权限
- [ ] 数据库 `aquaculture` 已创建（脚本会自动创建）

## 执行后验证

```bash
# 检查新表是否创建成功
mysql -u root -p -e "USE aquaculture; SHOW TABLES LIKE 'batches';"
mysql -u root -p -e "USE aquaculture; SHOW TABLES LIKE 'feeders_logs';"
mysql -u root -p -e "USE aquaculture; SHOW TABLES LIKE 'operations_logs';"
mysql -u root -p -e "USE aquaculture; SHOW TABLES LIKE 'manuals_docs';"
mysql -u root -p -e "USE aquaculture; SHOW TABLES LIKE 'history_records';"

# 检查现有表是否已扩展
mysql -u root -p -e "USE aquaculture; DESCRIBE sensor_readings;" | grep -E "(batch_id|pool_id|ts_utc|metric)"
mysql -u root -p -e "USE aquaculture; DESCRIBE camera_images;" | grep -E "(batch_id|pool_id|ts_utc|storage_uri)"
mysql -u root -p -e "USE aquaculture; DESCRIBE shrimp_stats;" | grep -E "(frame_id|count|avg_length_mm)"
```

## 常见问题

### 问题1：表已存在错误
如果看到 "Table already exists" 错误，这是正常的，因为使用了 `CREATE TABLE IF NOT EXISTS`。

### 问题2：字段已存在错误
如果看到 "Duplicate column name" 错误，说明字段已添加，可以忽略。

### 问题3：外键约束错误
如果看到外键约束错误，可能是因为：
- batches表还未创建
- 引用的表或字段不存在
- 数据迁移未完成

解决：按顺序执行SQL文件，确保先创建batches表。

## 需要帮助？

查看详细文档：
- [数据库表结构对比分析](docs/数据库表结构对比分析.md)
- [数据处理计划](docs/01-数据源清单.md)


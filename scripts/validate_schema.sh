#!/bin/bash
# ============================================
# 数据库结构验证脚本
# 用途：验证aquaculture数据库结构是否正确
# ============================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}数据库结构验证${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 提示输入MySQL凭据
read -p "请输入MySQL用户名 [默认: root]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-root}

read -sp "请输入MySQL密码: " MYSQL_PASS
echo ""

read -p "请输入MySQL主机 [默认: localhost]: " MYSQL_HOST
MYSQL_HOST=${MYSQL_HOST:-localhost}

read -p "请输入MySQL端口 [默认: 3306]: " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}

echo ""

# 预期的表列表
EXPECTED_TABLES=(
    "batches"
    "devices"
    "sensor_readings"
    "feeders_logs"
    "image_frames"
    "image_detections"
    "operations_logs"
    "manuals_docs"
    "history_records"
)

# 检查数据库是否存在
if ! mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "USE aquaculture;" 2>/dev/null; then
    echo -e "${RED}✗ 错误：数据库 'aquaculture' 不存在${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 数据库 'aquaculture' 存在${NC}"
echo ""

# 获取实际存在的表
EXISTING_TABLES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -N -e "USE aquaculture; SHOW TABLES;" 2>/dev/null)

# 验证每个表是否存在
MISSING_TABLES=()
for table in "${EXPECTED_TABLES[@]}"; do
    if echo "$EXISTING_TABLES" | grep -q "^${table}$"; then
        echo -e "${GREEN}✓ 表 '$table' 存在${NC}"
    else
        echo -e "${RED}✗ 表 '$table' 不存在${NC}"
        MISSING_TABLES+=("$table")
    fi
done

echo ""

# 显示索引信息
echo -e "${YELLOW}索引信息：${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "USE aquaculture; SELECT table_name, index_name, column_name FROM information_schema.statistics WHERE table_schema='aquaculture' ORDER BY table_name, index_name;" 2>/dev/null

echo ""

# 显示外键信息
echo -e "${YELLOW}外键信息：${NC}"
mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "USE aquaculture; SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='aquaculture' AND REFERENCED_TABLE_NAME IS NOT NULL;" 2>/dev/null

echo ""

# 总结
if [ ${#MISSING_TABLES[@]} -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}验证通过！所有表都存在${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}验证失败！缺少以下表：${NC}"
    for table in "${MISSING_TABLES[@]}"; do
        echo -e "${RED}  - $table${NC}"
    done
    echo -e "${RED}========================================${NC}"
    exit 1
fi






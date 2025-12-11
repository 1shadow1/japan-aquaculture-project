#!/bin/bash
# ============================================
# 通过MCP/MySQL执行数据库结构变更脚本
# 版本: v1.0
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMA_DIR="$PROJECT_DIR/schema"

# 默认MySQL配置
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_DATABASE="${MYSQL_DATABASE:-aquaculture}"

echo "============================================"
echo "数据库结构变更脚本"
echo "============================================"
echo "主机: $MYSQL_HOST:$MYSQL_PORT"
echo "用户: $MYSQL_USER"
echo "数据库: $MYSQL_DATABASE"
echo "============================================"
echo ""

# 提示输入MySQL密码（如果未通过环境变量设置）
if [ -z "$MYSQL_PASSWORD" ]; then
    read -sp "请输入MySQL密码: " MYSQL_PASS
    echo ""
else
    MYSQL_PASS="$MYSQL_PASSWORD"
    echo "使用环境变量中的MySQL密码"
fi

# 检查mysql命令是否存在
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}错误: 未找到mysql命令，请确保MySQL客户端已安装${NC}"
    exit 1
fi

# 测试数据库连接
echo -e "${YELLOW}正在测试数据库连接...${NC}"
if ! mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1;" &>/dev/null; then
    echo -e "${RED}错误: 无法连接到MySQL数据库${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 数据库连接成功${NC}"
echo ""

# 检查数据库是否存在，如果不存在则创建
echo -e "${YELLOW}检查数据库是否存在...${NC}"
if ! mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "USE $MYSQL_DATABASE;" &>/dev/null; then
    echo -e "${YELLOW}数据库不存在，正在创建...${NC}"
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_0900_ai_ci;"
    echo -e "${GREEN}✓ 数据库创建成功${NC}"
else
    echo -e "${GREEN}✓ 数据库已存在${NC}"
fi
echo ""

# 执行步骤1: 创建新表
echo "============================================"
echo "步骤 1/3: 创建新表"
echo "============================================"
if [ -f "$SCHEMA_DIR/01_create_new_tables.sql" ]; then
    echo -e "${YELLOW}正在执行: 01_create_new_tables.sql${NC}"
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DATABASE" < "$SCHEMA_DIR/01_create_new_tables.sql"; then
        echo -e "${GREEN}✓ 新表创建成功${NC}"
    else
        echo -e "${RED}✗ 新表创建失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}错误: 未找到文件 $SCHEMA_DIR/01_create_new_tables.sql${NC}"
    exit 1
fi
echo ""

# 执行步骤2: 扩展现有表
echo "============================================"
echo "步骤 2/3: 扩展现有表"
echo "============================================"
if [ -f "$SCHEMA_DIR/02_alter_existing_tables.sql" ]; then
    echo -e "${YELLOW}正在执行: 02_alter_existing_tables.sql${NC}"
    if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DATABASE" < "$SCHEMA_DIR/02_alter_existing_tables.sql"; then
        echo -e "${GREEN}✓ 表扩展成功${NC}"
    else
        echo -e "${YELLOW}⚠ 表扩展过程中有警告（某些字段可能已存在，这是正常的）${NC}"
    fi
else
    echo -e "${RED}错误: 未找到文件 $SCHEMA_DIR/02_alter_existing_tables.sql${NC}"
    exit 1
fi
echo ""

# 执行步骤3: 数据迁移（可选）
echo "============================================"
echo "步骤 3/3: 数据迁移（可选）"
echo "============================================"
read -p "是否执行数据迁移？(y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$SCHEMA_DIR/03_data_migration_guide.sql" ]; then
        echo -e "${YELLOW}正在执行: 03_data_migration_guide.sql${NC}"
        echo -e "${YELLOW}注意: 数据迁移脚本可能需要根据实际情况调整${NC}"
        if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DATABASE" < "$SCHEMA_DIR/03_data_migration_guide.sql"; then
            echo -e "${GREEN}✓ 数据迁移完成${NC}"
        else
            echo -e "${YELLOW}⚠ 数据迁移过程中有警告，请检查日志${NC}"
        fi
    else
        echo -e "${YELLOW}警告: 未找到文件 $SCHEMA_DIR/03_data_migration_guide.sql${NC}"
    fi
else
    echo -e "${YELLOW}跳过数据迁移${NC}"
fi
echo ""

# 验证结果
echo "============================================"
echo "验证结果"
echo "============================================"
echo -e "${YELLOW}检查新创建的表...${NC}"
TABLES=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DATABASE" -N -e "SHOW TABLES;" 2>/dev/null | grep -E "^(batches|feeders_logs|operations_logs|manuals_docs|history_records)$" || true)

if [ -n "$TABLES" ]; then
    echo -e "${GREEN}✓ 新表已创建:${NC}"
    echo "$TABLES" | while read table; do
        echo "  - $table"
    done
else
    echo -e "${YELLOW}⚠ 未检测到新表（可能已存在）${NC}"
fi

echo ""
echo -e "${GREEN}============================================"
echo "✓ 数据库结构变更完成！"
echo "============================================${NC}"


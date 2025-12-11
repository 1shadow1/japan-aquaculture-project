#!/bin/bash
# ============================================
# 数据库初始化脚本
# 用途：初始化aquaculture数据库
# ============================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DDL_FILE="$PROJECT_DIR/schema/mysql_aquaculture_ddl.sql"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}日本陆上养殖数据处理系统 - 数据库初始化${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查DDL文件是否存在
if [ ! -f "$DDL_FILE" ]; then
    echo -e "${RED}错误：找不到DDL文件: $DDL_FILE${NC}"
    exit 1
fi

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
echo -e "${YELLOW}正在初始化数据库...${NC}"

# 执行DDL脚本
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" < "$DDL_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ 数据库初始化成功！${NC}"
    echo ""
    
    # 验证表是否创建成功
    echo -e "${YELLOW}正在验证数据库结构...${NC}"
    TABLE_COUNT=$(mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='aquaculture';" 2>/dev/null)
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ 数据库验证成功！共创建 $TABLE_COUNT 个表${NC}"
        echo ""
        echo -e "${GREEN}数据库表列表：${NC}"
        mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "USE aquaculture; SHOW TABLES;" 2>/dev/null
    else
        echo -e "${RED}警告：未检测到表，请检查DDL脚本${NC}"
    fi
else
    echo -e "${RED}✗ 数据库初始化失败！请检查错误信息${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}初始化完成！${NC}"
echo -e "${GREEN}========================================${NC}"






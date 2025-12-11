#!/bin/bash
# ============================================
# 查看数据库信息脚本
# ============================================

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}数据库信息查看${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 提示输入MySQL凭据
read -p "请输入MySQL用户名 [默认: root]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-root}

read -sp "请输入MySQL密码 [直接回车跳过]: " MYSQL_PASS
echo ""

read -p "请输入MySQL主机 [默认: localhost]: " MYSQL_HOST
MYSQL_HOST=${MYSQL_HOST:-localhost}

read -p "请输入MySQL端口 [默认: 3306]: " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}

echo ""

# 构建MySQL命令
if [ -z "$MYSQL_PASS" ]; then
    MYSQL_CMD="mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER"
else
    MYSQL_CMD="mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASS"
fi

# 检查连接
echo -e "${YELLOW}检查MySQL连接...${NC}"
if ! $MYSQL_CMD -e "SELECT 1;" 2>/dev/null; then
    echo -e "${RED}错误：无法连接到MySQL服务器${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MySQL连接成功${NC}"
echo ""

# 显示所有数据库
echo -e "${BLUE}=== 数据库列表 ===${NC}"
$MYSQL_CMD -e "SHOW DATABASES;" 2>/dev/null
echo ""

# 检查aquaculture数据库是否存在
if $MYSQL_CMD -e "USE aquaculture;" 2>/dev/null; then
    echo -e "${GREEN}✓ 数据库 'aquaculture' 存在${NC}"
    echo ""
    
    # 显示表列表
    echo -e "${BLUE}=== 表列表 ===${NC}"
    $MYSQL_CMD -e "USE aquaculture; SHOW TABLES;" 2>/dev/null
    echo ""
    
    # 显示表数量
    TABLE_COUNT=$($MYSQL_CMD -N -e "USE aquaculture; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='aquaculture';" 2>/dev/null)
    echo -e "${YELLOW}表数量: $TABLE_COUNT${NC}"
    echo ""
    
    # 显示每个表的记录数
    echo -e "${BLUE}=== 表记录数统计 ===${NC}"
    $MYSQL_CMD -e "USE aquaculture; 
    SELECT 
        table_name AS '表名',
        table_rows AS '记录数',
        ROUND(((data_length + index_length) / 1024 / 1024), 2) AS '大小(MB)'
    FROM information_schema.tables 
    WHERE table_schema='aquaculture' 
    ORDER BY table_name;" 2>/dev/null
    echo ""
    
    # 显示索引信息
    echo -e "${BLUE}=== 索引信息 ===${NC}"
    $MYSQL_CMD -e "USE aquaculture;
    SELECT 
        table_name AS '表名',
        index_name AS '索引名',
        GROUP_CONCAT(column_name ORDER BY seq_in_index) AS '列名'
    FROM information_schema.statistics 
    WHERE table_schema='aquaculture' 
    GROUP BY table_name, index_name
    ORDER BY table_name, index_name
    LIMIT 20;" 2>/dev/null
    echo ""
    
    # 显示外键信息
    echo -e "${BLUE}=== 外键信息 ===${NC}"
    $MYSQL_CMD -e "USE aquaculture;
    SELECT 
        TABLE_NAME AS '表名',
        CONSTRAINT_NAME AS '外键名',
        REFERENCED_TABLE_NAME AS '引用表',
        REFERENCED_COLUMN_NAME AS '引用列'
    FROM information_schema.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA='aquaculture' 
    AND REFERENCED_TABLE_NAME IS NOT NULL
    ORDER BY TABLE_NAME;" 2>/dev/null
    echo ""
    
else
    echo -e "${YELLOW}数据库 'aquaculture' 不存在${NC}"
    echo -e "${YELLOW}可以使用以下命令初始化数据库：${NC}"
    echo "  ./scripts/init_database.sh"
    echo ""
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}查看完成${NC}"
echo -e "${GREEN}========================================${NC}"


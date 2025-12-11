#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通过MCP执行SQL脚本
使用MySQL MCP服务器执行DDL和DML语句
"""

import sys
import os
import re

# 添加项目根目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def read_sql_file(file_path):
    """读取SQL文件并分割成单独的语句"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 移除注释和空行
    lines = []
    for line in content.split('\n'):
        line = line.strip()
        # 跳过空行和注释行
        if line and not line.startswith('--'):
            lines.append(line)
    
    # 按分号分割SQL语句
    sql_content = ' '.join(lines)
    # 分割SQL语句，但保留CREATE TABLE等多行语句
    statements = []
    current_statement = []
    
    for line in content.split('\n'):
        stripped = line.strip()
        if not stripped or stripped.startswith('--'):
            continue
        
        current_statement.append(line)
        
        # 如果行以分号结尾，说明语句结束
        if stripped.endswith(';'):
            statement = '\n'.join(current_statement)
            # 移除注释
            statement = re.sub(r'--.*$', '', statement, flags=re.MULTILINE)
            if statement.strip():
                statements.append(statement.strip())
            current_statement = []
    
    # 处理最后一个语句（如果没有分号）
    if current_statement:
        statement = '\n'.join(current_statement)
        statement = re.sub(r'--.*$', '', statement, flags=re.MULTILINE)
        if statement.strip():
            statements.append(statement.strip())
    
    return statements

def execute_sql_via_mysql_client(sql_file, host='localhost', port=3306, user='root', database=None):
    """
    通过mysql命令行客户端执行SQL文件
    这是最直接的方式，因为MCP资源主要用于读取数据
    """
    import subprocess
    
    # 构建mysql命令
    cmd = ['mysql', f'-h{host}', f'-P{port}', f'-u{user}', '-p']
    if database:
        cmd.append(database)
    
    print(f"正在执行SQL文件: {sql_file}")
    print(f"数据库: {database or '默认'}")
    print(f"主机: {host}:{port}")
    print("-" * 50)
    
    # 执行SQL文件
    try:
        result = subprocess.run(
            cmd,
            stdin=open(sql_file, 'r', encoding='utf-8'),
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode == 0:
            print("✓ SQL执行成功！")
            if result.stdout:
                print(result.stdout)
            return True
        else:
            print("✗ SQL执行失败！")
            if result.stderr:
                print("错误信息:")
                print(result.stderr)
            if result.stdout:
                print("输出信息:")
                print(result.stdout)
            return False
            
    except FileNotFoundError:
        print("错误: 未找到mysql命令，请确保MySQL客户端已安装")
        return False
    except Exception as e:
        print(f"错误: {str(e)}")
        return False

def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='通过MySQL执行SQL脚本')
    parser.add_argument('sql_file', help='SQL文件路径')
    parser.add_argument('-H', '--host', default='localhost', help='MySQL主机地址')
    parser.add_argument('-P', '--port', type=int, default=3306, help='MySQL端口')
    parser.add_argument('-u', '--user', default='root', help='MySQL用户名')
    parser.add_argument('-d', '--database', help='数据库名称')
    
    args = parser.parse_args()
    
    # 检查文件是否存在
    if not os.path.exists(args.sql_file):
        print(f"错误: 文件不存在: {args.sql_file}")
        sys.exit(1)
    
    # 执行SQL
    success = execute_sql_via_mysql_client(
        args.sql_file,
        host=args.host,
        port=args.port,
        user=args.user,
        database=args.database
    )
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()


#!/bin/bash

# 获取脚本的真实路径(解析符号链接)
# 在 macOS 和 Linux 上都能工作
get_real_script_path() {
    local source="${BASH_SOURCE[0]}"
    
    # 解析符号链接直到找到真实文件
    while [ -L "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        # 如果 readlink 返回相对路径,需要转换为绝对路径
        [[ $source != /* ]] && source="$dir/$source"
    done
    
    # 返回脚本所在的真实目录
    cd -P "$(dirname "$source")" && pwd
}

# 获取项目根目录(脚本真实所在的目录)
PROJECT_ROOT_DIR="$(get_real_script_path)"
echo "项目根目录: $PROJECT_ROOT_DIR"
# 检查目录是否存在
if [ ! -d "$PROJECT_ROOT_DIR" ]; then
    echo "错误: 项目目录不存在: $PROJECT_ROOT_DIR"
    exit 1
fi

# 切换到项目根目录
cd "$PROJECT_ROOT_DIR" || {
    echo "错误: 无法切换到目录: $PROJECT_ROOT_DIR"
    exit 1
}

# 检查虚拟环境是否存在
if [ ! -d ".venv" ]; then
    echo "错误: 虚拟环境 .venv 不存在"
    echo "请在项目目录($PROJECT_ROOT_DIR)中运行 'uv venv' 创建虚拟环境"
    exit 1
fi

# 激活虚拟环境并运行脚本
source .venv/bin/activate
uv run start_proxy.py
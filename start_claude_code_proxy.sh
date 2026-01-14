#!/bin/bash

# 显示帮助信息
show_help() {
    echo "用法: ccc [选项] [VAR=VALUE ...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo ""
    echo "环境变量覆盖:"
    echo "  可以通过 VAR=VALUE 格式覆盖 .env 中的变量"
    echo "  覆盖仅对当前服务有效，不会修改 .env 文件"
    echo ""
    echo "示例:"
    echo "  ccc                              # 使用 .env 默认配置启动"
    echo "  ccc MAX_TOKENS_LIMIT=1000000      # 覆盖 MAX_TOKENS_LIMIT"
    echo "  ccc PORT=9000 LOG_LEVEL=DEBUG    # 覆盖多个变量"
    echo ""
    echo "可覆盖的变量 (参考 .env 文件):"
    echo "  BIG_MODEL, MIDDLE_MODEL, SMALL_MODEL"
    echo "  HOST, PORT, LOG_LEVEL"
    echo "  REQUEST_TIMEOUT, MAX_RETRIES"
    echo "  MAX_TOKENS_LIMIT, MIN_TOKENS_LIMIT"
}

# 解析命令行参数
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                show_help
                exit 0
                ;;
            *=*)
                # 格式: VAR=VALUE，导出为环境变量
                export "$arg"
                echo "覆盖环境变量: $arg"
                ;;
            *)
                echo "警告: 忽略未知参数: $arg"
                ;;
        esac
    done
}

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

# 解析命令行参数（在获取项目路径之前，以便 -h 可以立即生效）
parse_args "$@"

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
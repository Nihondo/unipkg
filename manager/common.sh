#!/bin/bash

# 共通ユーティリティ関数
# 各パッケージマネージャモジュールから使用される共通機能を提供

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# カウントのみモードかどうかを判定
is_count_only() {
    [[ "${COUNT_ONLY:-}" == "true" ]]
}

# バージョン表示モードかどうかを判定
is_version_mode() {
    [[ "${WITH_VERSION:-}" == "true" ]]
}

# 新バージョン表示モードかどうかを判定
is_new_version_mode() {
    [[ "${NEW_VERSION:-}" == "true" ]]
}

# 色出力が有効かどうかを判定
is_color_enabled() {
    [[ "${NO_COLOR:-}" != "true" ]]
}

# エラーメッセージの表示
error_msg() {
    if is_color_enabled; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    else
        echo "[ERROR] $1" >&2
    fi
}

# 警告メッセージの表示
warn_msg() {
    if is_color_enabled; then
        echo -e "${YELLOW}[WARNING]${NC} $1" >&2
    else
        echo "[WARNING] $1" >&2
    fi
}

# 情報メッセージの表示
info_msg() {
    if is_color_enabled; then
        echo -e "${BLUE}[INFO]${NC} $1" >&2
    else
        echo "[INFO] $1" >&2
    fi
}

# 成功メッセージの表示
success_msg() {
    if is_color_enabled; then
        echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
    else
        echo "[SUCCESS] $1" >&2
    fi
}

# コマンドが利用可能かチェック
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# CSV形式で出力（Manager,Package,Version）
output_csv() {
    local manager="$1"
    local package="$2"
    local version="$3"
    
    if is_count_only; then
        return
    fi
    
    if is_version_mode || is_new_version_mode; then
        echo "$manager,$package,$version"
    else
        echo "$manager,$package,"
    fi
}

# パッケージ数をカウント
count_packages() {
    local manager="$1"
    local count="$2"
    
    if is_count_only; then
        echo "$manager,$count"
    fi
}

# 確認プロンプト
confirm_action() {
    local action="$1"
    local target="$2"
    
    if [[ "${FORCE:-}" == "true" ]]; then
        return 0
    fi
    
    echo -n "Are you sure you want to $action '$target'? (y/N): "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# DRY RUNモードの確認
is_dry_run() {
    [[ "${DRY_RUN:-}" == "true" ]]
}

# バージョン文字列のクリーンアップ
clean_version() {
    local version="$1"
    # 不要な文字を削除
    version=$(echo "$version" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    version=$(echo "$version" | sed 's/^v//')
    echo "$version"
}
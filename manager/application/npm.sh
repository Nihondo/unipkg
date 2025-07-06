#!/bin/bash

# NPM パッケージマネージャ
# Node.js用のパッケージマネージャのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
NPM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$NPM_SCRIPT_DIR/../common.sh"

# NPM用の最新バージョン取得
get_latest_version_npm() {
    local package="$1"
    npm show "$package" version 2>/dev/null || echo "N/A"
}

# NPMパッケージ一覧取得
get_npm_packages() {
    if ! command_exists npm; then
        warn_msg "npmが見つかりません"
        if is_count_only; then
            echo "npm,0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得（テキスト形式）
        packages=$(npm list -g --depth=0 2>/dev/null | \
                  grep -E "^[├└]" | \
                  sed 's/[├└─│ ]*//g' | \
                  grep -v "^$" | \
                  grep -v "(empty)" | \
                  sort)
    else
        # パッケージ名のみ取得
        packages=$(npm list -g --depth=0 --parseable 2>/dev/null | \
                  grep -v "^/opt/homebrew/lib$" | \
                  sed 's|.*/||' | \
                  grep -v "^$" | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        echo "npm,$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # パッケージ名@バージョン形式を分離（スコープ付きパッケージ対応）
                if [[ "$line" == *"@"* ]]; then
                    # 最後の@以降がバージョン
                    local package=$(echo "$line" | sed 's/@[^@]*$//')
                    local version=$(echo "$line" | sed 's/.*@//')
                    
                    if is_new_version_mode; then
                        # 最新バージョンを取得
                        local latest_version=$(get_latest_version_npm "$package")
                        local status="Latest"
                        if [[ -n "$latest_version" && "$latest_version" != "N/A" && "$latest_version" != "$version" ]]; then
                            status="Outdated"
                        fi
                        echo "npm,$package,$version,${latest_version:-N/A},$status"
                    else
                        output_csv "npm" "$package" "$version"
                    fi
                else
                    if is_new_version_mode; then
                        local latest_version=$(get_latest_version_npm "$line")
                        local status="Latest"
                        if [[ -n "$latest_version" && "$latest_version" != "N/A" ]]; then
                            status="Outdated"  # バージョンなしパッケージは基本的に更新可能
                        fi
                        echo "npm,$line,N/A,${latest_version:-N/A},$status"
                    else
                        output_csv "npm" "$line" "N/A"
                    fi
                fi
            else
                output_csv "npm" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_npm_info() {
    local package="$1"
    if ! command_exists npm; then
        error_msg "npmが見つかりません"
        return 1
    fi
    
    npm info "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_npm_package() {
    local package="$1"
    if ! command_exists npm; then
        error_msg "npmが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: npm uninstall -g $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if npm uninstall -g "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を削除しました"
        else
            error_msg "パッケージ '$package' の削除に失敗しました"
            return 1
        fi
    else
        info_msg "キャンセルされました"
    fi
}

# パッケージをアップデート
update_npm_package() {
    local package="$1"
    if ! command_exists npm; then
        error_msg "npmが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: npm update -g"
        else
            info_msg "DRY RUN: npm update -g $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if npm update -g 2>/dev/null; then
            success_msg "全パッケージを更新しました"
        else
            error_msg "パッケージの更新に失敗しました"
            return 1
        fi
    else
        # 特定のパッケージを更新
        if npm update -g "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を更新しました"
        else
            error_msg "パッケージ '$package' の更新に失敗しました"
            return 1
        fi
    fi
}
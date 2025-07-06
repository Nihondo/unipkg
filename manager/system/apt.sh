#!/bin/bash

# APT パッケージマネージャ
# Debian/Ubuntu系ディストリビューション用のパッケージマネージャサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
APT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$APT_SCRIPT_DIR/../common.sh"

# APTパッケージ一覧取得
get_apt_packages() {
    if ! command_exists apt; then
        warn_msg "APTが見つかりません"
        if is_count_only; then
            count_packages "apt" "0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(apt list --installed 2>/dev/null | \
                  grep -v "WARNING" | \
                  tail -n +2 | \
                  sort)
    else
        # パッケージ名のみ取得
        packages=$(apt list --installed 2>/dev/null | \
                  grep -v "WARNING" | \
                  tail -n +2 | \
                  awk -F'/' '{print $1}' | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        count_packages "apt" "$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # package/release,now version arch [status]形式を分離
                local package=$(echo "$line" | awk -F'/' '{print $1}')
                local version=$(echo "$line" | awk '{print $2}' | cut -d' ' -f1)
                output_csv "apt" "$package" "$version"
            else
                output_csv "apt" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_apt_info() {
    local package="$1"
    if ! command_exists apt; then
        error_msg "APTが見つかりません"
        return 1
    fi
    
    apt show "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_apt_package() {
    local package="$1"
    if ! command_exists apt; then
        error_msg "APTが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: sudo apt remove $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if sudo apt remove "$package" 2>/dev/null; then
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
update_apt_package() {
    local package="$1"
    if ! command_exists apt; then
        error_msg "APTが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: sudo apt update && sudo apt upgrade"
        else
            info_msg "DRY RUN: sudo apt update && sudo apt upgrade $package"
        fi
        return 0
    fi
    
    # まずパッケージリストを更新
    sudo apt update 2>/dev/null || {
        error_msg "パッケージリストの更新に失敗しました"
        return 1
    }
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if sudo apt upgrade 2>/dev/null; then
            success_msg "全パッケージを更新しました"
        else
            error_msg "パッケージの更新に失敗しました"
            return 1
        fi
    else
        # 特定のパッケージを更新
        if sudo apt upgrade "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を更新しました"
        else
            error_msg "パッケージ '$package' の更新に失敗しました"
            return 1
        fi
    fi
}
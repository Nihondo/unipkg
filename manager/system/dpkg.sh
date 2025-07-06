#!/bin/bash

# DPKG パッケージマネージャ
# Debian系ディストリビューション用の低レベルパッケージマネージャサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
DPKG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DPKG_SCRIPT_DIR/../common.sh"

# DPKGパッケージ一覧取得
get_dpkg_packages() {
    if ! command_exists dpkg; then
        warn_msg "DPKGが見つかりません"
        if is_count_only; then
            count_packages "dpkg" "0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(dpkg -l 2>/dev/null | \
                  grep "^ii" | \
                  sort)
    else
        # パッケージ名のみ取得
        packages=$(dpkg -l 2>/dev/null | \
                  grep "^ii" | \
                  awk '{print $2}' | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        count_packages "dpkg" "$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # ii package version arch description形式を分離
                local package=$(echo "$line" | awk '{print $2}')
                local version=$(echo "$line" | awk '{print $3}')
                output_csv "dpkg" "$package" "$version"
            else
                output_csv "dpkg" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_dpkg_info() {
    local package="$1"
    if ! command_exists dpkg; then
        error_msg "DPKGが見つかりません"
        return 1
    fi
    
    dpkg -s "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_dpkg_package() {
    local package="$1"
    if ! command_exists dpkg; then
        error_msg "DPKGが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: sudo dpkg --remove $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if sudo dpkg --remove "$package" 2>/dev/null; then
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
update_dpkg_package() {
    local package="$1"
    if ! command_exists dpkg; then
        error_msg "DPKGが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: DPKGは直接アップデートできません。APTを使用してください"
        else
            info_msg "DRY RUN: DPKGは直接アップデートできません。APTを使用してください"
        fi
        return 0
    fi
    
    # DPKGは低レベルのツールなので、直接アップデートはできない
    error_msg "DPKGは直接アップデートできません。APTを使用してください"
    return 1
}
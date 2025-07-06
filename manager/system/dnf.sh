#!/bin/bash

# DNF パッケージマネージャ
# Red Hat系ディストリビューション用のパッケージマネージャサポート（Fedora/RHEL 8+）

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
DNF_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DNF_SCRIPT_DIR/../common.sh"

# DNF用の更新情報を取得
get_dnf_updates_info() {
    if ! command_exists dnf; then
        return 1
    fi
    
    # 更新可能なパッケージの詳細情報を一括取得
    dnf list updates 2>/dev/null | grep -E "^[a-zA-Z]" | grep -v "Last metadata\|Available Upgrades" | while read -r line; do
        local package=$(echo "$line" | awk '{print $1}' | cut -d'.' -f1)
        local version_full=$(echo "$line" | awk '{print $2}')
        # バージョン形式の処理: 1:7.1.1.47-1.el9.remi -> 7.1.1.47-1.el9.remi（エポック値のみ除去）
        local latest_version
        if [[ "$version_full" == *":"* ]]; then
            latest_version=$(echo "$version_full" | cut -d':' -f2)
        else
            latest_version="$version_full"
        fi
        echo "$package,$latest_version"
    done
}

# DNFパッケージ一覧取得
get_dnf_packages() {
    if ! command_exists dnf; then
        warn_msg "DNFが見つかりません"
        if is_count_only; then
            count_packages "dnf" "0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(dnf list installed 2>/dev/null | \
                  tail -n +2 | \
                  sort | \
                  uniq)
    else
        # パッケージ名のみ取得
        packages=$(dnf list installed 2>/dev/null | \
                  tail -n +2 | \
                  awk '{print $1}' | \
                  sed 's/\.[^.]*$//' | \
                  sort | \
                  uniq)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        count_packages "dnf" "$count"
        return
    fi
    
    if is_new_version_mode; then
        # 更新情報を一括取得して高速化
        local updates_info=$(get_dnf_updates_info)
        
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                # package.arch version repo 形式を分離
                local package=$(echo "$line" | awk '{print $1}' | sed 's/\.[^.]*$//')
                local version_full=$(echo "$line" | awk '{print $2}')
                # バージョン形式の処理: 1:7.1.1.47-1.el9.remi -> 7.1.1.47-1.el9.remi（エポック値のみ除去）
                local current_version
                if [[ "$version_full" == *":"* ]]; then
                    current_version=$(echo "$version_full" | cut -d':' -f2)
                else
                    current_version="$version_full"
                fi
                
                # 更新情報から最新バージョンを検索
                local latest_version=$(echo "$updates_info" | grep "^$package," | cut -d',' -f2)
                local status="Latest"
                if [[ -z "$latest_version" ]]; then
                    # 更新がない場合は現在のバージョンが最新
                    latest_version="$current_version"
                else
                    status="Outdated"
                fi
                
                echo "dnf,$package,$current_version,$latest_version,$status"
            fi
        done
    elif is_version_mode; then
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                # package.arch version repo 形式を分離
                local package=$(echo "$line" | awk '{print $1}' | sed 's/\.[^.]*$//')
                local version_full=$(echo "$line" | awk '{print $2}')
                # バージョン形式の処理: 1:7.1.1.47-1.el9.remi -> 7.1.1.47-1.el9.remi（エポック値のみ除去）
                local version
                if [[ "$version_full" == *":"* ]]; then
                    version=$(echo "$version_full" | cut -d':' -f2)
                else
                    version="$version_full"
                fi
                output_csv "dnf" "$package" "$version"
            fi
        done
    else
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                output_csv "dnf" "$line" ""
            fi
        done
    fi
}

# パッケージ情報を取得
get_dnf_info() {
    local package="$1"
    if ! command_exists dnf; then
        error_msg "DNFが見つかりません"
        return 1
    fi
    
    dnf info "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_dnf_package() {
    local package="$1"
    if ! command_exists dnf; then
        error_msg "DNFが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: sudo dnf remove $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if sudo dnf remove "$package" 2>/dev/null; then
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
update_dnf_package() {
    local package="$1"
    if ! command_exists dnf; then
        error_msg "DNFが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: sudo dnf upgrade"
        else
            info_msg "DRY RUN: sudo dnf upgrade $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if sudo dnf upgrade 2>/dev/null; then
            success_msg "全パッケージを更新しました"
        else
            error_msg "パッケージの更新に失敗しました"
            return 1
        fi
    else
        # 特定のパッケージを更新
        if sudo dnf upgrade "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を更新しました"
        else
            error_msg "パッケージ '$package' の更新に失敗しました"
            return 1
        fi
    fi
}
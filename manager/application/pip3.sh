#!/bin/bash

# pip3 パッケージマネージャ
# Python Package Index (pip3) のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
PIP3_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PIP3_SCRIPT_DIR/../common.sh"

# pip3用の最新バージョン取得
get_latest_version_pip3() {
    local package="$1"
    pip3 show "$package" 2>/dev/null | grep "^Version:" | cut -d' ' -f2 || echo "N/A"
}

# pip3パッケージ一覧取得
get_pip3_packages() {
    if ! command_exists pip3; then
        warn_msg "pip3が見つかりません"
        if is_count_only; then
            echo "pip3,0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(pip3 list --format=freeze 2>/dev/null | \
                  grep -v "^$" | \
                  sort)
    else
        # パッケージ名のみ取得
        packages=$(pip3 list --format=freeze 2>/dev/null | \
                  cut -d'=' -f1 | \
                  grep -v "^$" | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        echo "pip3,$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # package==version形式を分離
                local package=$(echo "$line" | cut -d'=' -f1)
                local version=$(echo "$line" | cut -d'=' -f3)
                
                if is_new_version_mode; then
                    # 最新バージョンを取得
                    local latest_version=$(get_latest_version_pip3 "$package")
                    local status="Latest"
                    if [[ -n "$latest_version" && "$latest_version" != "N/A" && "$latest_version" != "$version" ]]; then
                        status="Outdated"
                    fi
                    echo "pip3,$package,$version,${latest_version:-N/A},$status"
                else
                    output_csv "pip3" "$package" "${version:-N/A}"
                fi
            else
                output_csv "pip3" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_pip3_info() {
    local package="$1"
    if ! command_exists pip3; then
        error_msg "pip3が見つかりません"
        return 1
    fi
    
    pip3 show "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_pip3_package() {
    local package="$1"
    if ! command_exists pip3; then
        error_msg "pip3が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: pip3 uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if echo "y" | pip3 uninstall "$package" 2>/dev/null; then
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
update_pip3_package() {
    local package="$1"
    if ! command_exists pip3; then
        error_msg "pip3が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: pip3 list --outdated --format=freeze | cut -d = -f 1 | xargs -n1 pip3 install -U"
        else
            info_msg "DRY RUN: pip3 install --upgrade $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if confirm_action "更新" "全pip3パッケージ"; then
            local outdated=$(pip3 list --outdated --format=freeze 2>/dev/null | cut -d = -f 1)
            if [[ -n "$outdated" ]]; then
                echo "$outdated" | while read -r pkg; do
                    if [[ -n "$pkg" ]]; then
                        pip3 install --upgrade "$pkg" 2>/dev/null && \
                        success_msg "pip3: $pkg を更新しました" || \
                        error_msg "pip3: $pkg の更新に失敗しました"
                    fi
                done
            else
                info_msg "pip3: 更新可能なパッケージはありません"
            fi
        else
            info_msg "キャンセルされました"
        fi
    else
        # 特定のパッケージを更新
        if confirm_action "更新" "$package"; then
            if pip3 install --upgrade "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を更新しました"
            else
                error_msg "パッケージ '$package' の更新に失敗しました"
                return 1
            fi
        else
            info_msg "キャンセルされました"
        fi
    fi
}
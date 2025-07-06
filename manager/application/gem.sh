#!/bin/bash

# gem パッケージマネージャ
# Ruby Gems のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
GEM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$GEM_SCRIPT_DIR/../common.sh"

# gem用の最新バージョン取得
get_latest_version_gem() {
    local package="$1"
    # gem list --remote --exact の出力例: "psych (5.2.6 ruby java, 3.1.0 x64-mingw32 x86-mingw32)"
    # 最初のバージョン（5.2.6）のみを取得し、プラットフォーム情報（ruby java）を除去
    gem list "$package" --remote --exact 2>/dev/null | head -1 | \
        sed 's/.*(//' | sed 's/)//' | cut -d',' -f1 | \
        awk '{print $1}' || echo "N/A"
}

# gemパッケージ一覧取得
get_gem_packages() {
    if ! command_exists gem; then
        warn_msg "gemが見つかりません"
        if is_count_only; then
            echo "gem,0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(gem list 2>/dev/null | \
                  grep -v "^$" | \
                  sort)
    else
        # パッケージ名のみ取得
        packages=$(gem list --no-versions 2>/dev/null | \
                  grep -v "^$" | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        echo "gem,$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # package (version)形式を分離
                local package=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | sed 's/.*(//' | sed 's/).*//' | sed 's/,.*$//' | sed 's/^default: //')
                
                if is_new_version_mode; then
                    # 最新バージョンを取得
                    local latest_version=$(get_latest_version_gem "$package")
                    local status="Latest"
                    if [[ -n "$latest_version" && "$latest_version" != "N/A" && "$latest_version" != "$version" ]]; then
                        status="Outdated"
                    fi
                    echo "gem,$package,$version,${latest_version:-N/A},$status"
                else
                    output_csv "gem" "$package" "${version:-N/A}"
                fi
            else
                output_csv "gem" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_gem_info() {
    local package="$1"
    if ! command_exists gem; then
        error_msg "gemが見つかりません"
        return 1
    fi
    
    gem info "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_gem_package() {
    local package="$1"
    if ! command_exists gem; then
        error_msg "gemが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: gem uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if gem uninstall "$package" 2>/dev/null; then
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
update_gem_package() {
    local package="$1"
    if ! command_exists gem; then
        error_msg "gemが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: gem update"
        else
            info_msg "DRY RUN: gem update $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if confirm_action "更新" "全gemパッケージ"; then
            if gem update 2>/dev/null; then
                success_msg "全gemパッケージを更新しました"
            else
                error_msg "gemパッケージの更新に失敗しました"
                return 1
            fi
        else
            info_msg "キャンセルされました"
        fi
    else
        # 特定のパッケージを更新
        if confirm_action "更新" "$package"; then
            if gem update "$package" 2>/dev/null; then
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
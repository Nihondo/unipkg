#!/bin/bash

# Homebrew パッケージマネージャ
# macOS用のパッケージマネージャのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
BREW_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BREW_SCRIPT_DIR/../common.sh"

# Homebrew用の更新情報を取得
get_brew_outdated_info() {
    local brew_cmd
    brew_cmd=$(command -v brew)
    # 更新可能なパッケージの詳細情報を一括取得
    # フォーマット: package (current) < latest
    "$brew_cmd" outdated --verbose 2>/dev/null | while read -r line; do
        local package=$(echo "$line" | cut -d' ' -f1)
        local current=$(echo "$line" | sed 's/.*(\([^)]*\)).*/\1/')
        local latest=$(echo "$line" | sed 's/.* < //')
        echo "$package,$current,$latest"
    done
}

# Homebrewパッケージ一覧取得
get_brew_packages() {
    if ! command_exists brew; then
        warn_msg "Homebrewが見つかりません"
        if is_count_only; then
            echo "brew,0"
        fi
        return
    fi

    # brewコマンドのフルパスを取得
    local brew_cmd
    brew_cmd=$(command -v brew)
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$("$brew_cmd" list --formula --versions 2>/dev/null | sort)
    else
        # パッケージ名のみ取得
        packages=$("$brew_cmd" list --formula 2>/dev/null | sort)
    fi

    # wc -lの結果は先頭にスペースが入ることがあるためtrで除去
    local count=$(echo "$packages" | wc -l | tr -d ' ')
    if is_count_only; then
        echo "brew,$count"
        return
    fi
    
    if is_new_version_mode; then
        # 更新情報を一括取得して高速化
        local outdated_info=$(get_brew_outdated_info)
        
        # CSV形式で出力
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                # パッケージ名とバージョンを分離
                local package=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | awk '{print $2}')
                
                # 更新情報から最新バージョンを検索
                local latest_version=$(echo "$outdated_info" | grep "^$package," | cut -d',' -f3)
                local status="Latest"
                if [[ -z "$latest_version" ]]; then
                    # 更新がない場合は現在のバージョンが最新
                    latest_version="$version"
                else
                    status="Outdated"
                fi
                
                echo "brew,$package,${version:-N/A},${latest_version:-N/A},$status"
            fi
        done
    elif is_version_mode; then
        # CSV形式で出力
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                # パッケージ名とバージョンを分離
                local package=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | awk '{print $2}')
                output_csv "brew" "$package" "${version:-N/A}"
            fi
        done
    else
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                output_csv "brew" "$line" ""
            fi
        done
    fi
}

# パッケージ情報を取得
get_brew_info() {
    local package="$1"
    if ! command_exists brew; then
        error_msg "Homebrewが見つかりません"
        return 1
    fi
    
    local brew_cmd
    brew_cmd=$(command -v brew)
    "$brew_cmd" info "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_brew_package() {
    local package="$1"
    if ! command_exists brew; then
        error_msg "Homebrewが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: brew uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        local brew_cmd
        brew_cmd=$(command -v brew)
        if "$brew_cmd" uninstall "$package" 2>/dev/null; then
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
update_brew_package() {
    local package="$1"
    if ! command_exists brew; then
        error_msg "Homebrewが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: brew upgrade"
        else
            info_msg "DRY RUN: brew upgrade $package"
        fi
        return 0
    fi
    
    local brew_cmd
    brew_cmd=$(command -v brew)
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if "$brew_cmd" upgrade 2>/dev/null; then
            success_msg "全パッケージを更新しました"
        else
            error_msg "パッケージの更新に失敗しました"
            return 1
        fi
    else
        # 特定のパッケージを更新
        if "$brew_cmd" upgrade "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を更新しました"
        else
            error_msg "パッケージ '$package' の更新に失敗しました"
            return 1
        fi
    fi
}
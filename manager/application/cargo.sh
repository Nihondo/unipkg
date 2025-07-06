#!/bin/bash

# cargo パッケージマネージャ
# Rust Cargo packages のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
CARGO_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CARGO_SCRIPT_DIR/../common.sh"

# cargo用の最新バージョン取得
get_latest_version_cargo() {
    local package="$1"
    cargo search "$package" --limit 1 2>/dev/null | head -1 | sed 's/.*= "//' | sed 's/".*//' || echo "N/A"
}

# cargoパッケージ一覧取得
get_cargo_packages() {
    if ! command_exists cargo; then
        warn_msg "cargoが見つかりません"
        if is_count_only; then
            echo "cargo,0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(cargo install --list 2>/dev/null | \
                  grep "v[0-9]" | \
                  sort)
    else
        # パッケージ名のみ取得
        packages=$(cargo install --list 2>/dev/null | \
                  grep -v ":" | \
                  awk '{print $1}' | \
                  grep -v "^$" | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        echo "cargo,$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # package v1.0.0:形式を分離
                local package=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | sed 's/.*v\([^:]*\):.*/\1/')
                
                if is_new_version_mode; then
                    # 最新バージョンを取得
                    local latest_version=$(get_latest_version_cargo "$package")
                    echo "cargo,$package,$version,${latest_version:-N/A}"
                else
                    output_csv "cargo" "$package" "${version:-N/A}"
                fi
            else
                output_csv "cargo" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_cargo_info() {
    local package="$1"
    if ! command_exists cargo; then
        error_msg "cargoが見つかりません"
        return 1
    fi
    
    # cargoには直接的な情報表示コマンドがないため、インストール済みリストから検索
    local installed=$(cargo install --list 2>/dev/null | grep "^$package ")
    if [[ -n "$installed" ]]; then
        echo "パッケージ: $package"
        echo "$installed"
        echo ""
        echo "詳細情報を取得するには 'cargo search $package' を実行してください"
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
}

# パッケージを削除
delete_cargo_package() {
    local package="$1"
    if ! command_exists cargo; then
        error_msg "cargoが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: cargo uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if cargo uninstall "$package" 2>/dev/null; then
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
update_cargo_package() {
    local package="$1"
    if ! command_exists cargo; then
        error_msg "cargoが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: cargo install --list | grep -E '^[a-z]' | awk '{print $1}' | xargs -I {} cargo install {}"
        else
            info_msg "DRY RUN: cargo install $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新（再インストール）
        warn_msg "cargo: 全パッケージの更新には個別の再インストールが必要です"
        if confirm_action "更新" "全cargoパッケージ"; then
            # インストール済みパッケージを取得して再インストール
            local installed_packages=$(cargo install --list 2>/dev/null | grep -E '^[a-z]' | awk '{print $1}')
            if [[ -n "$installed_packages" ]]; then
                echo "$installed_packages" | while read -r pkg; do
                    if [[ -n "$pkg" ]]; then
                        cargo install "$pkg" 2>/dev/null && \
                        success_msg "cargo: $pkg を更新しました" || \
                        error_msg "cargo: $pkg の更新に失敗しました"
                    fi
                done
            else
                info_msg "cargo: インストール済みパッケージはありません"
            fi
        else
            info_msg "キャンセルされました"
        fi
    else
        # 特定のパッケージを更新（再インストール）
        if confirm_action "更新" "$package"; then
            if cargo install "$package" 2>/dev/null; then
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
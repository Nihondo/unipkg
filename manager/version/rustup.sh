#!/bin/bash

# Rust toolchain installer (rustup)
# Rustツールチェーン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
RUSTUP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUSTUP_SCRIPT_DIR/../common.sh"

# rustupパッケージ一覧取得
get_rustup_packages() {
    if command_exists rustup; then
        local packages
        packages=$(rustup toolchain list 2>/dev/null | awk '{print $1}' | sort)
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "rustup" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Rustツールチェーン管理の場合
                    output_csv "rustup" "Rust" "$package"
                else
                    output_csv "rustup" "$package" ""
                fi
            fi
        done
    else
        warn_msg "rustupが見つかりません"
        if is_count_only; then
            count_packages "rustup" "0"
        fi
    fi
}

# パッケージ情報を取得
get_rustup_info() {
    local package="$1"
    if ! command_exists rustup; then
        error_msg "rustupが見つかりません"
        return 1
    fi
    
    # ツールチェーンが存在するか確認
    if ! rustup toolchain list 2>/dev/null | grep -q "^$package"; then
        error_msg "ツールチェーン '$package' が見つかりません"
        return 1
    fi
    
    echo "Rust ツールチェーン: $package"
    
    # ツールチェーンの詳細情報を取得
    local toolchain_info=$(rustup show 2>/dev/null | grep -A 10 "installed toolchains" | grep "$package")
    if [[ -n "$toolchain_info" ]]; then
        echo "詳細: $toolchain_info"
    fi
    
    # デフォルトツールチェーンかどうか確認
    local default_toolchain=$(rustup default 2>/dev/null | awk '{print $1}')
    if [[ "$default_toolchain" == "$package" ]]; then
        echo "状態: デフォルトツールチェーン"
    else
        echo "状態: インストール済み"
    fi
    
    # ツールチェーンのコンポーネントを表示
    echo "インストール済みコンポーネント:"
    rustup component list --toolchain "$package" --installed 2>/dev/null | sed 's/^/  /' || echo "  取得できませんでした"
    
    # Rustcのバージョン情報
    if rustup run "$package" rustc --version >/dev/null 2>&1; then
        echo "rustc バージョン: $(rustup run "$package" rustc --version 2>/dev/null)"
    fi
}

# パッケージを削除
delete_rustup_package() {
    local package="$1"
    if ! command_exists rustup; then
        error_msg "rustupが見つかりません"
        return 1
    fi
    
    # ツールチェーンが存在するか確認
    if ! rustup toolchain list 2>/dev/null | grep -q "^$package"; then
        error_msg "ツールチェーン '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: rustup toolchain uninstall $package"
        return 0
    fi
    
    # デフォルトツールチェーンの場合は警告
    local default_toolchain=$(rustup default 2>/dev/null | awk '{print $1}')
    if [[ "$default_toolchain" == "$package" ]]; then
        warn_msg "これはデフォルトツールチェーンです。削除すると他のツールチェーンがデフォルトになります。"
    fi
    
    if confirm_action "削除" "$package"; then
        if rustup toolchain uninstall "$package" 2>/dev/null; then
            success_msg "ツールチェーン '$package' を削除しました"
        else
            error_msg "ツールチェーン '$package' の削除に失敗しました"
            return 1
        fi
    else
        info_msg "キャンセルされました"
    fi
}

# パッケージをアップデート
update_rustup_package() {
    local package="$1"
    if ! command_exists rustup; then
        error_msg "rustupが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: rustup update"
        else
            info_msg "DRY RUN: rustup update $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全ツールチェーンを更新
        if rustup update 2>/dev/null; then
            success_msg "全ツールチェーンを更新しました"
        else
            error_msg "ツールチェーンの更新に失敗しました"
            return 1
        fi
    else
        # 特定のツールチェーンを更新
        if rustup update "$package" 2>/dev/null; then
            success_msg "ツールチェーン '$package' を更新しました"
        else
            error_msg "ツールチェーン '$package' の更新に失敗しました"
            return 1
        fi
    fi
}
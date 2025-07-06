#!/bin/bash

# Ruby Version Manager (rbenv)
# Rubyバージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
RBENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RBENV_SCRIPT_DIR/../common.sh"

# rbenvパッケージ一覧取得
get_rbenv_packages() {
    if command_exists rbenv || [[ -d "$HOME/.rbenv/versions" ]]; then
        local packages
        if command_exists rbenv; then
            packages=$(rbenv versions --bare 2>/dev/null | sort)
        else
            packages=$(ls "$HOME/.rbenv/versions" 2>/dev/null | sort)
        fi
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "rbenv" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Rubyバージョン管理の場合、パッケージ名としてRubyを、バージョンとして各バージョンを表示
                    output_csv "rbenv" "Ruby" "$package"
                else
                    output_csv "rbenv" "$package" ""
                fi
            fi
        done
    else
        warn_msg "rbenvが見つかりません"
        if is_count_only; then
            count_packages "rbenv" "0"
        fi
    fi
}

# パッケージ情報を取得
get_rbenv_info() {
    local package="$1"
    if ! command_exists rbenv && [[ ! -d "$HOME/.rbenv/versions" ]]; then
        error_msg "rbenvが見つかりません"
        return 1
    fi
    
    local version_path=""
    if [[ -d "$HOME/.rbenv/versions/$package" ]]; then
        version_path="$HOME/.rbenv/versions/$package"
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    echo "Ruby バージョン: $package"
    echo "インストール場所: $version_path"
    echo "実行可能ファイル: $version_path/bin/ruby"
    if [[ -f "$version_path/bin/ruby" ]]; then
        echo "バージョン情報: $("$version_path/bin/ruby" --version 2>/dev/null || echo "取得できませんでした")"
    fi
    
    # gemの情報も表示
    if [[ -f "$version_path/bin/gem" ]]; then
        local gem_count=$("$version_path/bin/gem" list --no-versions 2>/dev/null | wc -l | tr -d ' ')
        echo "インストール済みgem数: $gem_count"
    fi
}

# パッケージを削除
delete_rbenv_package() {
    local package="$1"
    if ! command_exists rbenv && [[ ! -d "$HOME/.rbenv/versions" ]]; then
        error_msg "rbenvが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.rbenv/versions/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: rbenv uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists rbenv; then
            # rbenvコマンドが利用可能な場合
            if rbenv uninstall -f "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接ディレクトリを削除
            if rm -rf "$HOME/.rbenv/versions/$package"; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        fi
    else
        info_msg "キャンセルされました"
    fi
}

# パッケージをアップデート
update_rbenv_package() {
    local package="$1"
    if ! command_exists rbenv && [[ ! -d "$HOME/.rbenv/versions" ]]; then
        error_msg "rbenvが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: rbenvで管理されているRubyバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: rbenvで管理されているRubyバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # rbenvではバージョンの更新ではなく、新しいバージョンのインストールが必要
    error_msg "rbenvで管理されているRubyバージョンの更新はサポートされていません"
    error_msg "新しいバージョンをインストールするには: rbenv install <version>"
    return 1
}
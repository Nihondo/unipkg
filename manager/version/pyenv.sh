#!/bin/bash

# Python Version Manager (pyenv)
# Pythonバージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
PYENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PYENV_SCRIPT_DIR/../common.sh"

# pyenvパッケージ一覧取得
get_pyenv_packages() {
    if command_exists pyenv || [[ -d "$HOME/.pyenv/versions" ]]; then
        local packages
        if command_exists pyenv; then
            packages=$(pyenv versions --bare 2>/dev/null | grep -v "system" | sort)
        else
            packages=$(ls "$HOME/.pyenv/versions" 2>/dev/null | sort)
        fi
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "pyenv" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Pythonバージョン管理の場合
                    output_csv "pyenv" "Python" "$package"
                else
                    output_csv "pyenv" "$package" ""
                fi
            fi
        done
    else
        warn_msg "pyenvが見つかりません"
        if is_count_only; then
            count_packages "pyenv" "0"
        fi
    fi
}

# パッケージ情報を取得
get_pyenv_info() {
    local package="$1"
    if ! command_exists pyenv && [[ ! -d "$HOME/.pyenv/versions" ]]; then
        error_msg "pyenvが見つかりません"
        return 1
    fi
    
    local version_path=""
    if [[ -d "$HOME/.pyenv/versions/$package" ]]; then
        version_path="$HOME/.pyenv/versions/$package"
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    echo "Python バージョン: $package"
    echo "インストール場所: $version_path"
    echo "実行可能ファイル: $version_path/bin/python"
    if [[ -f "$version_path/bin/python" ]]; then
        echo "バージョン情報: $("$version_path/bin/python" --version 2>/dev/null || echo "取得できませんでした")"
    fi
    
    # pipの情報も表示
    if [[ -f "$version_path/bin/pip" ]]; then
        local pip_count=$("$version_path/bin/pip" list --format=freeze 2>/dev/null | wc -l | tr -d ' ')
        echo "インストール済みパッケージ数: $pip_count"
    fi
}

# パッケージを削除
delete_pyenv_package() {
    local package="$1"
    if ! command_exists pyenv && [[ ! -d "$HOME/.pyenv/versions" ]]; then
        error_msg "pyenvが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.pyenv/versions/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: pyenv uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists pyenv; then
            # pyenvコマンドが利用可能な場合
            if pyenv uninstall -f "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接ディレクトリを削除
            if rm -rf "$HOME/.pyenv/versions/$package"; then
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
update_pyenv_package() {
    local package="$1"
    if ! command_exists pyenv && [[ ! -d "$HOME/.pyenv/versions" ]]; then
        error_msg "pyenvが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: pyenvで管理されているPythonバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: pyenvで管理されているPythonバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # pyenvではバージョンの更新ではなく、新しいバージョンのインストールが必要
    error_msg "pyenvで管理されているPythonバージョンの更新はサポートされていません"
    error_msg "新しいバージョンをインストールするには: pyenv install <version>"
    return 1
}
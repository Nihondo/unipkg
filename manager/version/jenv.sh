#!/bin/bash

# Java Version Manager (jenv)
# Javaバージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
JENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$JENV_SCRIPT_DIR/../common.sh"

# jenvパッケージ一覧取得
get_jenv_packages() {
    if command_exists jenv || [[ -d "$HOME/.jenv/versions" ]]; then
        local packages
        if command_exists jenv; then
            packages=$(jenv versions --bare 2>/dev/null | grep -v "system" | sort)
        else
            packages=$(ls "$HOME/.jenv/versions" 2>/dev/null | sort)
        fi
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "jenv" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Javaバージョン管理の場合
                    output_csv "jenv" "Java" "$package"
                else
                    output_csv "jenv" "$package" ""
                fi
            fi
        done
    else
        warn_msg "jenvが見つかりません"
        if is_count_only; then
            count_packages "jenv" "0"
        fi
    fi
}

# パッケージ情報を取得
get_jenv_info() {
    local package="$1"
    if ! command_exists jenv && [[ ! -d "$HOME/.jenv/versions" ]]; then
        error_msg "jenvが見つかりません"
        return 1
    fi
    
    local version_path=""
    if [[ -d "$HOME/.jenv/versions/$package" ]]; then
        version_path="$HOME/.jenv/versions/$package"
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    echo "Java バージョン: $package"
    echo "インストール場所: $version_path"
    echo "実行可能ファイル: $version_path/bin/java"
    if [[ -f "$version_path/bin/java" ]]; then
        echo "バージョン情報: $("$version_path/bin/java" -version 2>&1 | head -1 || echo "取得できませんでした")"
    fi
    
    # 現在使用中のバージョンを確認
    if command_exists jenv; then
        local current_version=$(jenv version-name 2>/dev/null)
        if [[ "$current_version" == "$package" ]]; then
            echo "状態: 現在使用中"
        else
            echo "状態: インストール済み"
        fi
    fi
    
    # JAVA_HOMEの情報
    if [[ -d "$version_path" ]]; then
        echo "JAVA_HOME: $version_path"
    fi
}

# パッケージを削除
delete_jenv_package() {
    local package="$1"
    if ! command_exists jenv && [[ ! -d "$HOME/.jenv/versions" ]]; then
        error_msg "jenvが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.jenv/versions/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: jenv remove $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists jenv; then
            # jenvコマンドが利用可能な場合
            if jenv remove "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接シンボリックリンクを削除（jenvは通常シンボリックリンクを使用）
            if rm -rf "$HOME/.jenv/versions/$package"; then
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
update_jenv_package() {
    local package="$1"
    if ! command_exists jenv && [[ ! -d "$HOME/.jenv/versions" ]]; then
        error_msg "jenvが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: jenvで管理されているJavaバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: jenvで管理されているJavaバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # jenvではバージョンの更新ではなく、新しいバージョンの追加が必要
    error_msg "jenvで管理されているJavaバージョンの更新はサポートされていません"
    error_msg "新しいバージョンを追加するには: jenv add <path-to-java-home>"
    return 1
}
#!/bin/bash

# Universal Version Manager (asdf)
# 汎用バージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
ASDF_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ASDF_SCRIPT_DIR/../common.sh"

# asdfパッケージ一覧取得
get_asdf_packages() {
    if command_exists asdf || [[ -d "$HOME/.asdf" ]]; then
        local packages=""
        if command_exists asdf; then
            # asdfでインストールされた全てのツールとバージョンを取得
            local tools=$(asdf plugin list 2>/dev/null)
            if [[ -n "$tools" ]]; then
                while read -r tool; do
                    if [[ -n "$tool" ]]; then
                        local versions=$(asdf list "$tool" 2>/dev/null | sed 's/^\s*//' | grep -v "^$")
                        while read -r version; do
                            if [[ -n "$version" ]]; then
                                packages="${packages}${tool}-${version}\n"
                            fi
                        done <<< "$versions"
                    fi
                done <<< "$tools"
            fi
        fi
        
        packages=$(echo -e "$packages" | grep -v "^$" | sort)
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "asdf" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # ツール名とバージョンを分離
                    local tool=$(echo "$package" | sed 's/-[^-]*$//')
                    local version=$(echo "$package" | sed 's/.*-//')
                    output_csv "asdf" "$tool" "$version"
                else
                    output_csv "asdf" "$package" ""
                fi
            fi
        done
    else
        warn_msg "asdfが見つかりません"
        if is_count_only; then
            count_packages "asdf" "0"
        fi
    fi
}

# パッケージ情報を取得
get_asdf_info() {
    local package="$1"
    if ! command_exists asdf; then
        error_msg "asdfが見つかりません"
        return 1
    fi
    
    # パッケージ名からツールとバージョンを分離
    if [[ "$package" =~ ^(.+)-([^-]+)$ ]]; then
        local tool="${BASH_REMATCH[1]}"
        local version="${BASH_REMATCH[2]}"
    else
        # バージョンが指定されていない場合、ツール名として扱う
        local tool="$package"
        local version=""
    fi
    
    echo "asdf ツール: $tool"
    if [[ -n "$version" ]]; then
        echo "バージョン: $version"
        
        # インストール場所を確認
        local install_path=$(asdf where "$tool" "$version" 2>/dev/null)
        if [[ -n "$install_path" ]]; then
            echo "インストール場所: $install_path"
        fi
        
        # 現在使用中のバージョンを確認
        local current_version=$(asdf current "$tool" 2>/dev/null | awk '{print $2}')
        if [[ "$current_version" == "$version" ]]; then
            echo "状態: 現在使用中"
        else
            echo "状態: インストール済み"
        fi
    else
        # ツールの情報とインストール済みバージョン一覧を表示
        echo "インストール済みバージョン:"
        asdf list "$tool" 2>/dev/null | sed 's/^/  /' || echo "  なし"
        
        local current_version=$(asdf current "$tool" 2>/dev/null | awk '{print $2}')
        if [[ -n "$current_version" ]]; then
            echo "現在使用中: $current_version"
        fi
    fi
}

# パッケージを削除
delete_asdf_package() {
    local package="$1"
    if ! command_exists asdf; then
        error_msg "asdfが見つかりません"
        return 1
    fi
    
    # パッケージ名からツールとバージョンを分離
    if [[ "$package" =~ ^(.+)-([^-]+)$ ]]; then
        local tool="${BASH_REMATCH[1]}"
        local version="${BASH_REMATCH[2]}"
    else
        error_msg "パッケージ形式が無効です。'tool-version' の形式で指定してください"
        return 1
    fi
    
    # バージョンがインストールされているか確認
    if ! asdf list "$tool" 2>/dev/null | grep -q "\\s*$version\\s*"; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: asdf uninstall $tool $version"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if asdf uninstall "$tool" "$version" 2>/dev/null; then
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
update_asdf_package() {
    local package="$1"
    if ! command_exists asdf; then
        error_msg "asdfが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: asdf plugin update --all"
        else
            # パッケージ名からツールを分離
            if [[ "$package" =~ ^(.+)-([^-]+)$ ]]; then
                local tool="${BASH_REMATCH[1]}"
                info_msg "DRY RUN: asdf plugin update $tool"
            else
                info_msg "DRY RUN: asdf plugin update $package"
            fi
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全プラグインを更新
        if asdf plugin update --all 2>/dev/null; then
            success_msg "全プラグインを更新しました"
        else
            error_msg "プラグインの更新に失敗しました"
            return 1
        fi
    else
        # 特定のツール/プラグインを更新
        if [[ "$package" =~ ^(.+)-([^-]+)$ ]]; then
            local tool="${BASH_REMATCH[1]}"
        else
            local tool="$package"
        fi
        
        if asdf plugin update "$tool" 2>/dev/null; then
            success_msg "プラグイン '$tool' を更新しました"
        else
            error_msg "プラグイン '$tool' の更新に失敗しました"
            return 1
        fi
    fi
}
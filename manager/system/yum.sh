#!/bin/bash

# YUM パッケージマネージャ
# Red Hat系ディストリビューション用のパッケージマネージャサポート（RHEL/CentOS）

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
YUM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$YUM_SCRIPT_DIR/../common.sh"

# YUMパッケージ一覧取得
get_yum_packages() {
    if ! command_exists yum; then
        warn_msg "YUMが見つかりません"
        if is_count_only; then
            count_packages "yum" "0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(yum list installed 2>/dev/null | \
                  tail -n +2 | \
                  sort | \
                  uniq)
    else
        # パッケージ名のみ取得
        packages=$(yum list installed 2>/dev/null | \
                  tail -n +2 | \
                  awk '{print $1}' | \
                  sed 's/\.[^.]*$//' | \
                  sort | \
                  uniq)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        count_packages "yum" "$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # package.arch version repo 形式を分離
                local package=$(echo "$line" | awk '{print $1}' | sed 's/\.[^.]*$//')
                local version=$(echo "$line" | awk '{print $2}')
                output_csv "yum" "$package" "$version"
            else
                output_csv "yum" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_yum_info() {
    local package="$1"
    if ! command_exists yum; then
        error_msg "YUMが見つかりません"
        return 1
    fi
    
    yum info "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_yum_package() {
    local package="$1"
    if ! command_exists yum; then
        error_msg "YUMが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: sudo yum remove $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if sudo yum remove "$package" 2>/dev/null; then
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
update_yum_package() {
    local package="$1"
    if ! command_exists yum; then
        error_msg "YUMが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: sudo yum update"
        else
            info_msg "DRY RUN: sudo yum update $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全パッケージを更新
        if sudo yum update 2>/dev/null; then
            success_msg "全パッケージを更新しました"
        else
            error_msg "パッケージの更新に失敗しました"
            return 1
        fi
    else
        # 特定のパッケージを更新
        if sudo yum update "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を更新しました"
        else
            error_msg "パッケージ '$package' の更新に失敗しました"
            return 1
        fi
    fi
}
#!/bin/bash

# CPAN パッケージマネージャ
# CPAN (Comprehensive Perl Archive Network) のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
CPAN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CPAN_SCRIPT_DIR/../common.sh"

# CPANパッケージ一覧取得（注意：設定が必要な場合があります）
get_cpan_packages() {
    warn_msg "CPAN一覧取得は設定が複雑なため、Perlモジュール一覧を代替として使用します"
    
    # perl.shを読み込み、perl関数を使用
    source "$(dirname "$0")/perl.sh"
    get_perl_packages
}

# パッケージ情報を取得
get_cpan_info() {
    local package="$1"
    if ! command_exists cpan; then
        error_msg "CPANクライアントが見つかりません"
        return 1
    fi
    
    # CPANモジュールの情報を取得
    cpan -D "$package" 2>/dev/null || {
        error_msg "モジュール '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_cpan_package() {
    local package="$1"
    if ! command_exists cpan; then
        error_msg "CPANクライアントが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: cpan -u $package (注意: CPANモジュールの削除は複雑です)"
        return 0
    fi
    
    warn_msg "CPANモジュールの削除は標準的な方法がありません"
    warn_msg "手動で削除するか、専用のツールを使用してください"
    return 1
}

# パッケージをアップデート
update_cpan_package() {
    local package="$1"
    if ! command_exists cpan; then
        error_msg "CPANクライアントが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: cpan -u (全モジュールの更新)"
        else
            info_msg "DRY RUN: cpan -u $package"
        fi
        return 0
    fi
    
    if [[ -z "$package" ]]; then
        # 全モジュールを更新
        if confirm_action "更新" "全CPANモジュール"; then
            if cpan -u 2>/dev/null; then
                success_msg "全CPANモジュールを更新しました"
            else
                error_msg "CPANモジュールの更新に失敗しました"
                return 1
            fi
        else
            info_msg "キャンセルされました"
        fi
    else
        # 特定のモジュールを更新
        if confirm_action "更新" "$package"; then
            if cpan -u "$package" 2>/dev/null; then
                success_msg "CPANモジュール '$package' を更新しました"
            else
                error_msg "CPANモジュール '$package' の更新に失敗しました"
                return 1
            fi
        else
            info_msg "キャンセルされました"
        fi
    fi
}
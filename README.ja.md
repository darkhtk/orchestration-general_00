# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

複数のClaude CLIエージェントがファイルベースの非同期通信でゲームを共同開発するオーケストレーションフレームワーク。

batファイル一つで全てセットアップされます。エージェントが自律的にタスクを取得し、機能を実装し、コードをレビューし、ボードを管理します — 全てマークダウンファイルを通じて調整されます。

## 動作フロー

```
orchestrate.bat  (ダブルクリック)
    |
    |-- 依存関係チェック (Git, Claude CLI)
    |-- ゲームプロジェクトフォルダ選択 (モダンダイアログ)
    |-- エンジン自動検出 (Unity / Godot / Unreal)
    |-- 対話型セットアップ:
    |       Gitリモートリポジトリ、コミットポリシー、開発方針、
    |       エージェントモード、レビュー強度、ドキュメントスキャン
    |-- プロジェクト設定 + エージェントプロンプト生成
    |-- エージェント実行 (各自別々のターミナル)
    v
  4つのエージェントが並列実行、orchestration/ を通じて通信
```

## エージェント

| エージェント | 役割 | 担当内容 |
|---------|------|--------|
| **Supervisor** (監督官) | オーケストレーター | アセット生成、コード品質監査、バグ修正、タスク管理 |
| **Developer** (開発者) | 実行者 | ゲームロジック実装、テスト作成、コミット |
| **Client** (顧客) | 検証者 | マルチペルソナQAレビュー、品質フィードバック |
| **Coordinator** (コミュニケーション管理者) | 管理者 | ボード同期、バックログ補充、企画書作成、エージェント監視 |

## 要件

| プログラム | 必須 | インストール |
|---------|------|------|
| Git for Windows | ○ | https://git-scm.com/download/win |
| Node.js 18+ | ○ | https://nodejs.org |
| Claude CLI | ○ | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | 推奨 | Windows 10/11 標準搭載 |

## クイックスタート

```bash
# 1. クローン
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. orchestrate.bat をダブルクリック
#    - ゲームプロジェクトフォルダを選択
#    - エンジン、ディレクトリ、既存ドキュメントを自動検出
#    - セットアップ質問 (方針、エージェントモードなど)
#    - エージェント実行

# またはコマンドラインから:
orchestrate.bat "C:\path\to\your\game"
```

## セットアップオプション

対話型セットアップで確認する項目:

| オプション | 選択肢 | デフォルト |
|------|--------|-------|
| **既存ドキュメント** | プロジェクトドキュメントをスキャンしてエージェントが初回ループで読み込み | Yes |
| **Git** | リポジトリ初期化、リモートURL設定 | 自動検出 |
| **コミット/プッシュポリシー** | task / review / batch / manual | task |
| **開発方針** | stabilize / feature / polish / content / custom | feature |
| **エージェントモード** | full (4つ) / lean (2つ) / solo (1つ) | full |
| **レビュー強度** | strict / standard / minimal | standard |

## 生成される構造

orchestrate.batをゲームプロジェクトで実行すると生成されるもの:

```
your-game-project/
  orchestration/
    project.config.md        # 全体設定 (エージェントが毎ループ読み込み)
    BOARD.md                 # カンバンボード (Backlog > In Progress > In Review > Done)
    BACKLOG_RESERVE.md       # 開発者が取得する予備タスクプール
    agents/                  # エージェント役割定義
    prompts/                 # エージェント実行プロンプト
    templates/               # ドキュメントテンプレート (タスク、レビュー、企画書など)
    tasks/                   # タスク仕様 (TASK-001.md, ...)
    reviews/                 # レビュー結果 (REVIEW-001-v1.md, ...)
    decisions/               # 監督官の判断記録
    discussions/             # エージェント間ディスカッション (非同期議論)
      concluded/             # 終了したディスカッション
    specs/                   # 機能企画書 (SPEC-R-001.md, ...)
    logs/                    # エージェント別ループログ
    .run_SUPERVISOR.sh       # エージェント実行スクリプト
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## ワークフロー

```
Backlog --> In Progress --> In Review --> Done
                ^               |
                '-- Rejected <--'
```

1. **Supervisor/Coordinator**がBACKLOG_RESERVEにタスクを登録
2. **Developer**が最上位のタスクを取得して実装
3. 実装完了後にIn Reviewへ移動
4. **Client**がマルチペルソナレビューを実施 (4名のレビュアーペルソナ)
5. APPROVE -> Done / NEEDS_WORK -> Rejected -> Developerが修正

## エージェントモード

### Full (4つ)
全エージェント有効。完全なレビューサイクル、ボード管理、アセット生成。

### Lean (2つ)
Developer + Supervisorのみ。専任レビュアー/管理者なし。Supervisorがレビューとボード同期を兼任。

### Solo (1つ)
Developer一つに全役割を統合。セルフレビュー、セルフボード管理。小規模プロジェクトや一人開発に最適。

## 続行実行

既に`orchestration/`があるプロジェクトでorchestrate.batを実行すると既存のセットアップを検出します:

```
  Existing orchestration detected!
  Mode: full    Direction: stabilize

  1) Resume      - エージェントのみ実行 (セットアップスキップ)
  2) Reconfigure - セットアップ再実行
  3) Cancel
```

## その他のツール

| ファイル | 機能 |
|------|--------|
| `add-feature.bat` | 自然言語で機能を説明 -> タスク + 企画書を自動生成 |
| `monitor.bat` | Unity/Godotエディタログ監視、ランタイムエラー検出時にバグタスクを自動生成 |

## コアメカニズム

### FREEZE
BOARD.md上部にFREEZE告知を追加 -> 全エージェント即時停止。削除すると再開。

### ディスカッション
エージェントが`discussions/`に非同期ディスカッションを開くことができます。設計判断、優先度変更、プロトコル改善に使用。全エージェントが自分のセクションに応答し、監督官が結論を出します。

### 自己進行
Developerが監督官を待たずにタスクを自動進行可能。QA/バランスタスクはレビューなしで完了。新システム追加タスクのみClientレビュー必須。

## 対応エンジン

| エンジン | 自動検出 | エラーログ | サンプル設定 |
|------|----------|----------|----------|
| Unity | `.meta` ファイル、`Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## ファイル構成

```
orchestrate.bat          # メインエントリーポイント (セットアップ + 実行)
add-feature.bat          # テキストで機能追加
monitor.bat              # ランタイムエラーモニタリング
pick-folder.ps1          # モダンフォルダ選択ダイアログ (IFileDialog COM)
auto-setup.sh            # エンジン検出、設定生成、対話型セットアップ
init.sh                  # ディレクトリ構造生成
launch.sh                # クロスプラットフォームエージェントランチャー
extract-features.sh      # コード分析 -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> タスク + 企画書
add-feature.sh           # 自然言語 -> タスク + 企画書
monitor.sh               # エディタログ監視 + エラーレポート
project.config.md        # 空の設定テンプレート
framework/
  agents/                # エージェント役割定義 (4つ)
  prompts/               # エージェントループプロンプト (4つ)
  templates/             # ドキュメントテンプレート (7つ)
sample-config/           # Unity/Godot設定例
```

## ライセンス

MIT

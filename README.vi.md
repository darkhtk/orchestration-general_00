# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

Nhiều agent Claude CLI cộng tác phát triển game thông qua giao tiếp bất đồng bộ dựa trên tệp.

Một tệp bat thiết lập mọi thứ. Các agent tự động nhận nhiệm vụ, triển khai tính năng, đánh giá code và quản lý bảng dự án — tất cả được điều phối thông qua các tệp markdown.

## Cách Hoạt Động

```
orchestrate.bat  (nhấp đúp)
    |
    |-- Kiểm tra phụ thuộc (Git, Claude CLI)
    |-- Chọn thư mục dự án game (hộp thoại hiện đại)
    |-- Tự động phát hiện engine (Unity / Godot / Unreal)
    |-- Thiết lập tương tác:
    |       Git remote, chính sách commit, hướng phát triển,
    |       chế độ agent, mức đánh giá, quét tài liệu
    |-- Tạo cấu hình dự án + prompt cho agent
    |-- Khởi chạy agent trong các terminal riêng biệt
    v
  4 agent chạy song song, giao tiếp qua orchestration/
```

## Các Agent

| Agent | Vai trò | Nhiệm vụ |
|-------|---------|-----------|
| **Supervisor** | Điều phối viên | Tạo tài nguyên, kiểm tra chất lượng code, sửa lỗi, quản lý nhiệm vụ |
| **Developer** | Xây dựng | Triển khai logic game, viết test, commit code |
| **Client** | Đánh giá viên | Đánh giá QA đa nhân cách, phản hồi chất lượng |
| **Coordinator** | Quản lý | Đồng bộ bảng, bổ sung backlog, viết đặc tả, giám sát agent |

## Yêu Cầu

| Chương trình | Bắt buộc | Cài đặt |
|--------------|----------|---------|
| Git for Windows | Có | https://git-scm.com/download/win |
| Node.js 18+ | Có | https://nodejs.org |
| Claude CLI | Có | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | Khuyến nghị | Được cài sẵn trên Windows 10/11 |

## Bắt Đầu Nhanh

```bash
# 1. Clone
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. Nhấp đúp orchestrate.bat
#    - Chọn thư mục dự án game của bạn
#    - Tự động phát hiện engine, thư mục, tài liệu hiện có
#    - Hỏi các câu hỏi thiết lập (hướng phát triển, chế độ agent, v.v.)
#    - Khởi chạy các agent

# Hoặc từ dòng lệnh:
orchestrate.bat "C:\path\to\your\game"
```

## Tùy Chọn Thiết Lập

Quá trình thiết lập tương tác sẽ hỏi:

| Tùy chọn | Lựa chọn | Mặc định |
|-----------|----------|----------|
| **Tài liệu hiện có** | Quét tài liệu dự án để agent đọc trong lần lặp đầu tiên | Có |
| **Git** | Khởi tạo repo, đặt remote URL | Tự động phát hiện |
| **Chính sách Commit/Push** | task / review / batch / manual | task |
| **Hướng phát triển** | stabilize / feature / polish / content / custom | feature |
| **Chế độ Agent** | full (4) / lean (2) / solo (1) | full |
| **Mức đánh giá** | strict / standard / minimal | standard |

## Các Tệp Được Tạo

Khi bạn chạy orchestrate.bat trên một dự án game, nó sẽ tạo:

```
your-game-project/
  orchestration/
    project.config.md        # Tất cả cài đặt (agent đọc mỗi lần lặp)
    BOARD.md                 # Bảng Kanban (Backlog > In Progress > In Review > Done)
    BACKLOG_RESERVE.md       # Kho nhiệm vụ để developer chọn
    agents/                  # Định nghĩa vai trò agent
    prompts/                 # Prompt khởi chạy agent
    templates/               # Mẫu tài liệu (nhiệm vụ, đánh giá, đặc tả, v.v.)
    tasks/                   # Đặc tả nhiệm vụ (TASK-001.md, ...)
    reviews/                 # Kết quả đánh giá (REVIEW-001-v1.md, ...)
    decisions/               # Quyết định của Supervisor
    discussions/             # Thảo luận giữa các agent (tranh luận bất đồng bộ)
      concluded/             # Các thảo luận đã kết thúc
    specs/                   # Đặc tả tính năng (SPEC-R-001.md, ...)
    logs/                    # Log mỗi lần lặp của agent
    .run_SUPERVISOR.sh       # Script chạy agent
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## Quy Trình Làm Việc

```
Backlog --> In Progress --> In Review --> Done
                ^               |
                '-- Rejected <--'
```

1. **Supervisor/Coordinator** tạo nhiệm vụ trong BACKLOG_RESERVE
2. **Developer** chọn nhiệm vụ ưu tiên cao nhất, triển khai
3. Developer chuyển nhiệm vụ sang In Review
4. **Client** thực hiện đánh giá đa nhân cách (4 nhân cách đánh giá viên)
5. APPROVE -> Done / NEEDS_WORK -> Rejected -> Developer sửa

## Chế Độ Agent

### Full (4 agent)
Tất cả agent hoạt động. Chu trình đánh giá đầy đủ, quản lý bảng, tạo tài nguyên.

### Lean (2 agent)
Chỉ Developer + Supervisor. Không có đánh giá viên hoặc coordinator riêng. Supervisor xử lý đánh giá và đồng bộ bảng.

### Solo (1 agent)
Một agent Developer duy nhất với tất cả vai trò gộp lại. Tự đánh giá, tự quản lý bảng. Phù hợp cho dự án nhỏ hoặc phát triển đơn lẻ.

## Tiếp Tục

Nếu bạn chạy orchestrate.bat trên một dự án đã có `orchestration/`, nó sẽ phát hiện thiết lập hiện có:

```
  Existing orchestration detected!
  Mode: full    Direction: stabilize

  1) Resume      - chỉ khởi chạy agent (bỏ qua thiết lập)
  2) Reconfigure - chạy lại thiết lập
  3) Cancel
```

## Công Cụ Khác

| Tệp | Chức năng |
|------|-----------|
| `add-feature.bat` | Mô tả tính năng bằng văn bản thuần -> tự động tạo nhiệm vụ + đặc tả |
| `monitor.bat` | Theo dõi log trình soạn thảo Unity/Godot để phát hiện lỗi runtime, tự động tạo nhiệm vụ sửa lỗi |

## Cơ Chế Chính

### FREEZE
Thêm thông báo FREEZE vào đầu BOARD.md -> tất cả agent dừng ngay lập tức. Xóa nó để tiếp tục.

### Thảo luận
Các agent có thể mở tranh luận bất đồng bộ trong `discussions/`. Dùng cho quyết định thiết kế, thay đổi ưu tiên, cải thiện quy trình. Tất cả agent phản hồi trong phần của mình, sau đó supervisor kết luận.

### Tự tiến triển
Developer có thể tự động tiến qua các nhiệm vụ mà không cần chờ supervisor. Các nhiệm vụ QA/cân bằng bỏ qua hoàn toàn đánh giá. Các nhiệm vụ hệ thống mới luôn yêu cầu Client đánh giá.

## Engine Được Hỗ Trợ

| Engine | Tự động phát hiện | Log lỗi | Cấu hình mẫu |
|--------|-------------------|----------|---------------|
| Unity | Tệp `.meta`, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## Tổng Quan Tệp

```
orchestrate.bat          # Điểm vào chính (thiết lập + khởi chạy)
add-feature.bat          # Thêm tính năng bằng mô tả văn bản
monitor.bat              # Giám sát lỗi runtime
pick-folder.ps1          # Hộp thoại chọn thư mục hiện đại (IFileDialog COM)
auto-setup.sh            # Phát hiện engine, tạo cấu hình, thiết lập tương tác
init.sh                  # Tạo cấu trúc thư mục
launch.sh                # Trình khởi chạy agent đa nền tảng
extract-features.sh      # Phân tích codebase -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> nhiệm vụ + đặc tả
add-feature.sh           # Ngôn ngữ tự nhiên -> nhiệm vụ + đặc tả
monitor.sh               # Theo dõi Editor.log + báo cáo lỗi
project.config.md        # Mẫu cấu hình trống
framework/
  agents/                # Định nghĩa vai trò agent (4 tệp)
  prompts/               # Prompt lặp agent (4 tệp)
  templates/             # Mẫu tài liệu (7 tệp)
sample-config/           # Cấu hình mẫu cho Unity/Godot
```

## Giấy Phép

MIT

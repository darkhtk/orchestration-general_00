# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

เอเจนต์ Claude CLI หลายตัวทำงานร่วมกันในการพัฒนาเกมผ่านการสื่อสารแบบอะซิงโครนัสด้วยไฟล์

ไฟล์ bat เพียงไฟล์เดียวตั้งค่าทุกอย่าง เอเจนต์จะรับงาน พัฒนาฟีเจอร์ รีวิวโค้ด และจัดการบอร์ดโปรเจกต์โดยอัตโนมัติ ทั้งหมดประสานงานผ่านไฟล์ markdown

## วิธีการทำงาน

```
orchestrate.bat  (ดับเบิลคลิก)
    |
    |-- ตรวจสอบ dependency (Git, Claude CLI)
    |-- เลือกโฟลเดอร์โปรเจกต์เกม (ไดอะล็อกแบบทันสมัย)
    |-- ตรวจจับเอนจินอัตโนมัติ (Unity / Godot / Unreal)
    |-- ตั้งค่าแบบโต้ตอบ:
    |       Git remote, นโยบาย commit, ทิศทางการพัฒนา,
    |       โหมดเอเจนต์, ระดับรีวิว, การสแกนเอกสาร
    |-- สร้างไฟล์ config โปรเจกต์ + พรอมต์เอเจนต์
    |-- เปิดเอเจนต์ในเทอร์มินัลแยก
    v
  4 เอเจนต์ทำงานพร้อมกัน สื่อสารผ่าน orchestration/
```

## เอเจนต์

| เอเจนต์ | บทบาท | หน้าที่ |
|-------|------|-------------|
| **Supervisor** | ผู้ประสานงาน | สร้างแอสเซท, ตรวจสอบคุณภาพโค้ด, แก้บัก, จัดการงาน |
| **Developer** | ผู้สร้าง | พัฒนาลอจิกเกม, เขียนเทสต์, คอมมิตโค้ด |
| **Client** | ผู้รีวิว | รีวิว QA แบบหลายบุคลิก, ข้อเสนอแนะด้านคุณภาพ |
| **Coordinator** | ผู้จัดการ | ซิงค์บอร์ด, เติมแบ็คล็อก, เขียนสเปค, ติดตามเอเจนต์ |

## ข้อกำหนด

| โปรแกรม | จำเป็น | ติดตั้ง |
|---------|----------|---------|
| Git for Windows | ใช่ | https://git-scm.com/download/win |
| Node.js 18+ | ใช่ | https://nodejs.org |
| Claude CLI | ใช่ | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | แนะนำ | ติดตั้งมาแล้วบน Windows 10/11 |

## เริ่มต้นอย่างรวดเร็ว

```bash
# 1. โคลน
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. ดับเบิลคลิก orchestrate.bat
#    - เลือกโฟลเดอร์โปรเจกต์เกม
#    - ตรวจจับเอนจิน ไดเรกทอรี เอกสารที่มีอยู่โดยอัตโนมัติ
#    - ถามคำถามตั้งค่า (ทิศทาง, โหมดเอเจนต์ ฯลฯ)
#    - เปิดเอเจนต์

# หรือจากบรรทัดคำสั่ง:
orchestrate.bat "C:\path\to\your\game"
```

## ตัวเลือกการตั้งค่า

การตั้งค่าแบบโต้ตอบจะถาม:

| ตัวเลือก | ตัวเลือกที่มี | ค่าเริ่มต้น |
|--------|---------|---------|
| **เอกสารที่มีอยู่** | สแกนเอกสารโปรเจกต์ให้เอเจนต์อ่านในลูปแรก | ใช่ |
| **Git** | เริ่มต้น repo, ตั้งค่า remote URL | ตรวจจับอัตโนมัติ |
| **นโยบาย Commit/Push** | task / review / batch / manual | task |
| **ทิศทางการพัฒนา** | stabilize / feature / polish / content / custom | feature |
| **โหมดเอเจนต์** | full (4) / lean (2) / solo (1) | full |
| **ระดับรีวิว** | strict / standard / minimal | standard |

## สิ่งที่ถูกสร้างขึ้น

เมื่อคุณรัน orchestrate.bat บนโปรเจกต์เกม จะสร้างสิ่งต่อไปนี้:

```
your-game-project/
  orchestration/
    project.config.md        # การตั้งค่าทั้งหมด (เอเจนต์อ่านทุกลูป)
    BOARD.md                 # บอร์ด Kanban (Backlog > In Progress > In Review > Done)
    BACKLOG_RESERVE.md       # กลุ่มงานสำหรับนักพัฒนาเลือกหยิบ
    agents/                  # นิยามบทบาทเอเจนต์
    prompts/                 # พรอมต์เปิดเอเจนต์
    templates/               # เทมเพลตเอกสาร (task, review, spec ฯลฯ)
    tasks/                   # สเปคงาน (TASK-001.md, ...)
    reviews/                 # ผลรีวิว (REVIEW-001-v1.md, ...)
    decisions/               # การตัดสินใจของ Supervisor
    discussions/             # การอภิปรายของเอเจนต์ (ถกเถียงแบบอะซิงโครนัส)
      concluded/             # การอภิปรายที่สรุปแล้ว
    specs/                   # สเปคฟีเจอร์ (SPEC-R-001.md, ...)
    logs/                    # ล็อกลูปของแต่ละเอเจนต์
    .run_SUPERVISOR.sh       # สคริปต์รันเอเจนต์
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## เวิร์กโฟลว์

```
Backlog --> In Progress --> In Review --> Done
                ^               |
                '-- Rejected <--'
```

1. **Supervisor/Coordinator** สร้างงานใน BACKLOG_RESERVE
2. **Developer** หยิบงานบนสุด แล้วพัฒนา
3. Developer ย้ายงานไป In Review
4. **Client** ทำการรีวิวแบบหลายบุคลิก (บุคลิกผู้รีวิว 4 แบบ)
5. APPROVE -> Done / NEEDS_WORK -> Rejected -> Developer แก้ไข

## โหมดเอเจนต์

### Full (4 เอเจนต์)
เอเจนต์ทุกตัวทำงาน วงจรรีวิวเต็มรูปแบบ จัดการบอร์ด สร้างแอสเซท

### Lean (2 เอเจนต์)
Developer + Supervisor เท่านั้น ไม่มีผู้รีวิวหรือผู้ประสานงานเฉพาะ Supervisor จัดการรีวิวและซิงค์บอร์ด

### Solo (1 เอเจนต์)
เอเจนต์ Developer ตัวเดียวรวมทุกบทบาท รีวิวตัวเอง จัดการบอร์ดเอง เหมาะสำหรับโปรเจกต์ขนาดเล็กหรือพัฒนาคนเดียว

## การกลับมาทำงานต่อ

หากคุณรัน orchestrate.bat บนโปรเจกต์ที่มี `orchestration/` อยู่แล้ว จะตรวจพบการตั้งค่าที่มีอยู่:

```
  Existing orchestration detected!
  Mode: full    Direction: stabilize

  1) Resume      - เปิดเอเจนต์เท่านั้น (ข้ามการตั้งค่า)
  2) Reconfigure - ตั้งค่าใหม่
  3) Cancel
```

## เครื่องมืออื่น ๆ

| ไฟล์ | หน้าที่ |
|------|-------------|
| `add-feature.bat` | อธิบายฟีเจอร์เป็นข้อความ -> สร้างงาน + สเปคอัตโนมัติ |
| `monitor.bat` | ดูล็อกของ Unity/Godot editor เพื่อตรวจจับข้อผิดพลาดขณะรัน สร้างงานบักอัตโนมัติ |

## กลไกสำคัญ

### FREEZE
เพิ่มประกาศ FREEZE ที่ด้านบนของ BOARD.md -> เอเจนต์ทุกตัวหยุดทันที ลบออกเพื่อให้ทำงานต่อ

### การอภิปราย
เอเจนต์สามารถเปิดการถกเถียงแบบอะซิงโครนัสใน `discussions/` ใช้สำหรับการตัดสินใจด้านการออกแบบ การเปลี่ยนลำดับความสำคัญ การปรับปรุงโปรโตคอล เอเจนต์ทุกตัวตอบในส่วนของตน จากนั้น Supervisor สรุป

### การดำเนินงานต่อเนื่องอัตโนมัติ
Developer สามารถเดินหน้าผ่านงานต่าง ๆ โดยอัตโนมัติโดยไม่ต้องรอ Supervisor งาน QA/balance ข้ามรีวิวทั้งหมด งานระบบใหม่ต้องผ่านการรีวิวจาก Client เสมอ

## เอนจินที่รองรับ

| เอนจิน | ตรวจจับอัตโนมัติ | ล็อกข้อผิดพลาด | ตัวอย่าง config |
|--------|------------|-----------|---------------|
| Unity | ไฟล์ `.meta`, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## ภาพรวมไฟล์

```
orchestrate.bat          # จุดเริ่มต้นหลัก (ตั้งค่า + เปิดเอเจนต์)
add-feature.bat          # เพิ่มฟีเจอร์ด้วยคำอธิบายข้อความ
monitor.bat              # ติดตามข้อผิดพลาดขณะรัน
pick-folder.ps1          # ไดอะล็อกเลือกโฟลเดอร์แบบทันสมัย (IFileDialog COM)
auto-setup.sh            # ตรวจจับเอนจิน, สร้าง config, ตั้งค่าแบบโต้ตอบ
init.sh                  # สร้างโครงสร้างไดเรกทอรี
launch.sh                # ตัวเปิดเอเจนต์ข้ามแพลตฟอร์ม
extract-features.sh      # วิเคราะห์โค้ดเบส -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> งาน + สเปค
add-feature.sh           # ภาษาธรรมชาติ -> งาน + สเปค
monitor.sh               # ดู Editor.log + รายงานข้อผิดพลาด
project.config.md        # เทมเพลต config ว่าง
framework/
  agents/                # นิยามบทบาทเอเจนต์ (4 ไฟล์)
  prompts/               # พรอมต์ลูปเอเจนต์ (4 ไฟล์)
  templates/             # เทมเพลตเอกสาร (7 ไฟล์)
sample-config/           # ตัวอย่าง config สำหรับ Unity/Godot
```

## สัญญาอนุญาต

MIT

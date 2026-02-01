# TempoFlow — 完整產品規格書

> Flutter 跨平台專業節拍器（Web / iOS / Android 共用）

## 一、產品定位

| 項目 | 說明 |
|------|------|
| 類型 | 專業樂器練習用節拍器（以鋼琴為核心） |
| 目標族群 | 鋼琴初學～中高階、音樂教師、長時間練習者 |
| 核心價值 | 節拍準（audio scheduling）、操作快（單手、舞台可視）、設定可保存/重用、Flutter 一套三端 |

## 二、功能矩陣與版本規劃

### MVP（必做）
- BPM 設定、拍號、強拍、細分節拍
- 聲音輸出（高精準音訊排程）
- 視覺節拍指示
- Preset 儲存/載入
- 大字舞台模式

### V1（加值）
- Tap Tempo
- 自動加速訓練（Tempo Trainer）
- 強弱拍模式（Accent Pattern）
- 練習計時器

### Pro（進階，未來）
- 節奏型 / Groove Pattern
- 練習記錄與統計
- 雲端同步（選配）

## 三、詳細功能規格

### 1. 節拍核心（Metronome Engine）
- **BPM 範圍**：20–300
- **調整方式**：
  - Slider（粗調）
  - +/- 按鈕（±1 BPM）
  - 直接輸入數字
- **即時生效**：BPM 更新不中斷播放

### 2. 拍號（Time Signature）
- 預設快選：2/4、3/4、4/4、6/8
- 結構：`beatsPerBar`（分子）+ `noteValue`（分母，先支援 4 和 8）
- 支援自訂分子：1–16

### 3. 強拍（Accent）
- 預設：第一拍強音
- 可關閉
- 強拍音量比例（例：強拍 1.0 / 普通拍 0.7）

### 4. 細分節拍（Subdivision）
- 選項：1（四分）、2（八分）、3（三連音）、4（十六分）
- 主拍 / 細分拍可用不同音色或音量
- 細分音量獨立控制

### 5. 音訊輸出
- **音色選擇**：Click、Woodblock、Beep
- **音量控制**：
  - Master volume（總音量）
  - Accent volume（強拍音量）
  - Subdivision volume（細分音量）
- **技術要求**：
  - Web：Web Audio API（AudioContext + look-ahead scheduler）
  - iOS/Android：原生 audio engine（plugin）
  - **不使用 Dart Timer 當節拍來源**

### 6. 視覺節拍
- 模式選項：
  - LED 點亮（燈號模式）
  - 全畫面閃爍
  - 節拍擺動（左右 / 圓形）
- **同步邏輯**：視覺 follow audio time（非反過來）

### 7. 震動模式（行動裝置）
- 主拍震動
- 可選：主拍 only / 每拍
- Web 預設停用

### 8. Preset 系統
- **可儲存內容**：BPM、拍號、細分、強拍設定、音色、視覺模式
- **功能**：新增 / 刪除 / 編輯
- **最近使用**：LRU 5–10 筆
- **儲存位置**：本機（shared_preferences / localStorage）
- **匯出/匯入**：JSON 格式

## 四、訓練與進階功能

### 9. Tap Tempo
- 連續點擊偵測 BPM
- 計算最近 N 次 tap 平均值
- 套用後可微調
- 超過 2 秒未觸擊自動重置

### 10. 自動加速訓練（Tempo Trainer）
- **參數**：
  - 起始 BPM
  - 目標 BPM
  - 加速間隔（N 小節 / N 秒）
  - 加速幅度（+X BPM）
- **模式**：單次 / 循環
- **結束提示音**（可關）

### 11. 強弱拍模式（Accent Pattern）
- 每拍權重設定（0.0–1.0）
- 預設模板：標準、行進、華爾滋

### 12. 練習計時器
- 設定練習時間
- 與節拍器同步啟停
- 完成提示

## 五、Pro 功能（未來版本）

### 13. 節奏型（Groove / Pattern）
- 內建：Straight、Swing、Rock、Jazz basic
- Pattern 編輯：16-step grid，每 step 設定音量/靜音
- 可儲存為 Preset

### 14. 練習記錄
- 每日練習時間
- 常用 BPM 區間
- 訓練完成率
- 匯出 CSV / JSON

### 15. 雲端同步（選配）
- 帳號登入
- 同步 presets / 訓練設定
- 離線可用

## 六、UI / UX 結構

### 頁面架構
| 頁面 | 說明 |
|------|------|
| 主節拍器頁 | BPM 控制、拍號、播放、視覺節拍 |
| Preset 管理頁 | Preset 列表、編輯、匯出入 |
| 訓練模式頁 | Tempo Trainer、練習計時器 |
| 設定頁 | 音色、音量、視覺模式、震動 |

### 舞台模式
- 大字 BPM 顯示
- 超大 Start / Stop 按鈕
- 高對比配色（深色底、亮色字）
- 螢幕常亮（Wake Lock）
- 橫向適配大螢幕

## 七、跨平台音訊設計方案

### 設計原則
**不使用 Dart Timer 作為節拍來源**。Dart Timer 受限於事件迴圈延遲（可達 16ms+），
無法滿足音樂級精度需求（< 1ms 誤差）。

### Web 平台 — Web Audio API
```
Dart ──(JS Interop)──> AudioContext.currentTime
                        ├─ look-ahead scheduler (25ms polling)
                        ├─ AudioBufferSourceNode.start(exactTime)
                        └─ scheduleAheadTime = 100ms
```
- `AudioContext.currentTime` 作為高精度時鐘源
- Look-ahead Scheduler：JS setTimeout 25ms 輪詢排程
- 音訊排程用 `AudioBufferSourceNode.start(exactTime)` 精確觸發
- 視覺同步：`requestAnimationFrame` 對齊 UI

### iOS 平台 — AVAudioEngine
```
Dart ──(MethodChannel)──> Swift AudioEngine
                           ├─ AVAudioEngine
                           ├─ AVAudioPlayerNode.scheduleBuffer(at:)
                           └─ 音訊線程精確排程
```

### Android 平台 — Oboe (NDK)
```
Dart ──(MethodChannel)──> Kotlin/C++ Bridge
                           ├─ Oboe (AAudio / OpenSL ES)
                           └─ 音訊回調線程寫入 PCM
```

### 架構圖
```
┌─────────────────────────────────────────────┐
│              Flutter UI Layer                │
│  ┌──────┐ ┌──────┐ ┌────────┐ ┌──────────┐ │
│  │ BPM  │ │拍號  │ │ Preset │ │  Stage   │ │
│  │Control│ │Picker│ │Manager │ │  Mode    │ │
│  └──┬───┘ └──┬───┘ └───┬────┘ └────┬─────┘ │
│     └────────┴─────────┴────────────┘       │
│            MetronomeState                    │
│       (Riverpod StateNotifier)               │
├─────────────────────────────────────────────┤
│          Audio Engine Interface               │
│        (abstract AudioEngine)                │
├─────────────┬──────────┬────────────────────┤
│ Web         │ iOS      │ Android            │
│ WebAudioAPI │AVAudio   │ Oboe (NDK)         │
│ (JS Interop)│Engine    │                    │
└─────────────┴──────────┴────────────────────┘
```

## 八、Flutter 專案架構

```
lib/
├── main.dart
├── app.dart
├── features/
│   ├── metronome/          # 核心節拍器功能
│   │   ├── metronome_screen.dart
│   │   ├── metronome_controller.dart
│   │   └── widgets/
│   │       ├── bpm_control.dart
│   │       ├── beat_indicator.dart
│   │       ├── time_signature_picker.dart
│   │       ├── subdivision_selector.dart
│   │       ├── accent_editor.dart
│   │       └── tap_tempo_button.dart
│   ├── presets/            # Preset 管理
│   │   ├── preset_screen.dart
│   │   └── preset_controller.dart
│   ├── trainer/            # 訓練模式
│   │   ├── trainer_screen.dart
│   │   ├── speed_trainer_controller.dart
│   │   └── widgets/
│   │       └── speed_trainer_panel.dart
│   ├── stage/              # 舞台模式
│   │   └── stage_mode_screen.dart
│   └── settings/           # 設定
│       ├── settings_screen.dart
│       └── sound_selector.dart
├── core/
│   ├── audio/
│   │   ├── audio_engine.dart           # 抽象介面
│   │   ├── web_audio_engine.dart       # Web 實作
│   │   └── native_audio_engine.dart    # iOS/Android 實作
│   ├── models/
│   │   ├── metronome_state.dart
│   │   ├── time_signature.dart
│   │   ├── accent_pattern.dart
│   │   ├── preset.dart
│   │   ├── sound_type.dart
│   │   ├── visual_mode.dart
│   │   └── speed_trainer_config.dart
│   ├── services/
│   │   ├── metronome_service.dart
│   │   ├── preset_service.dart
│   │   ├── tap_tempo_service.dart
│   │   └── speed_trainer_service.dart
│   └── providers/
│       └── providers.dart
├── shared/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── stage_theme.dart
│   └── widgets/
│       └── ...
web/
└── audio_engine.js          # Web Audio JS 橋接
assets/
└── sounds/
    ├── click.wav
    ├── click_accent.wav
    ├── woodblock.wav
    ├── woodblock_accent.wav
    ├── beep.wav
    └── beep_accent.wav
```

## 九、核心資料模型

```dart
class MetronomeState {
  final int bpm;
  final int beatsPerBar;
  final int noteValue;
  final int subdivision;
  final bool accentEnabled;
  final List<double> accentPattern; // 每拍權重 0.0–1.0
  final SoundType soundType;
  final double masterVolume;
  final double accentVolume;
  final double subdivisionVolume;
  final VisualMode visualMode;
  final bool vibrationEnabled;
  final bool isPlaying;
  final int currentBeat;
}
```

## 十、技術選型

| 層級 | 技術 |
|------|------|
| Framework | Flutter 3.x |
| 狀態管理 | Riverpod |
| Web 音訊 | Web Audio API (dart:js_interop) |
| iOS 音訊 | AVAudioEngine (Swift) |
| Android 音訊 | Oboe C++ (NDK) |
| 本地儲存 | shared_preferences + JSON |
| 螢幕常亮 | wakelock_plus |
| 音訊資源 | PCM WAV (44.1kHz / 16bit) |

## 十一、精度要求

| 指標 | 目標 |
|------|------|
| 節拍間隔誤差 | < 1ms（音訊線程級） |
| UI 視覺同步 | < 16ms（一幀內） |
| Tap Tempo 偵測 | < 5ms |
| BPM 切換延遲 | < 50ms（下一拍生效） |

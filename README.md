# WW2 Blitz — iOS

A port of the WW2 Blitz vertical scrolling shooter from Android to iOS.

## Requirements

- Xcode 15+
- iOS 16.0+
- Portrait orientation only

## Opening the Project

```bash
open ~/ios/github/ww2blitz/WW2Blitz.xcodeproj
```

Select a simulator or device, then **⌘R** to build and run.

## Architecture

| Android | iOS |
|---|---|
| `SurfaceView` + `Choreographer` | `SKScene` + `update(_:)` |
| `Canvas.drawBitmap` | `SKSpriteNode` |
| `SoundPool` / dual `MediaPlayer` | `AVAudioEngine` |
| `SharedPreferences` | `UserDefaults` |
| `MotionEvent` drag | `touchesBegan/Moved/Ended` |

## Project Structure

```
WW2Blitz/
├── Sources/           # 30 Swift source files
│   ├── GameScene.swift        # Main game loop + state machine
│   ├── PlayerShip.swift       # Touch-drag controls
│   ├── BossController.swift   # All 8 boss fight types
│   ├── StageDirector.swift    # All 8 stage wave scripts
│   └── ...
└── Resources/
    ├── Images/        # 54 sprite PNGs
    ├── Audio/         # 12 WAV files (BGM + SFX)
    ├── Fonts/         # arcade_font.ttf
    └── Stages/        # 8 stage background/boss asset folders
```

## Game Features

- 8-stage campaign with unique bosses (plane, tank, battleship, jungle fortress, canopy facility, orbit satellite, winter keep, coral atoll)
- 2 playable fighters: P-38 Lightning and F6F Hellcat
- 7 difficulty tiers (Monkey → Hardcore)
- Graze scoring, panic bombs, homing missiles, weapon power-ups
- Arcade-style high score leaderboard with 3-character initials
- Stage-clear bonus tally animation

## Source

Ported from `~/android/github/ww2blitz` (Kotlin/Android Canvas).

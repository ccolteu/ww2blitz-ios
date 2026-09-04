import UIKit
import SpriteKit
import CoreText

/// Android `assets/fonts/arcade_font.ttf` is Press Start 2P. iOS UIFont name is the PostScript name, not the filename.
enum ArcadeTypeface {
    static let postScriptName: String = {
        for candidate in ["PressStart2P", "Press Start 2P"] {
            if UIFont(name: candidate, size: 12) != nil { return candidate }
        }
        if let url = Bundle.main.url(forResource: "arcade_font", withExtension: "ttf", subdirectory: "Fonts") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            if let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
               let desc = descs.first,
               let name = CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute) as? String,
               UIFont(name: name, size: 12) != nil {
                return name
            }
        }
        return UIFont.boldSystemFont(ofSize: 12).fontName
    }()
}

/// Arcade overlay matching the Android GameView / UIController layout (y-down source coords).
final class UIController {
    struct Hits {
        var audio = CGRect.null
        var difficulty = CGRect.null
        var fighter = CGRect.null
        var diffRows = [CGRect](repeating: .null, count: 7)
        var diffBack = CGRect.null
        var shipLeft = CGRect.null
        var shipRight = CGRect.null
        var fighterBack = CGRect.null
        var settingsBack = CGRect.null
        var bgmDown = CGRect.null
        var bgmUp = CGRect.null
        var sfxDown = CGRect.null
        var sfxUp = CGRect.null
        var regLeft = CGRect.null
        var regRight = CGRect.null
        var regSet = CGRect.null
    }

    enum Attract { case title, demo, highScore }

    private(set) var hits = Hits()
    private weak var scene: SKScene?
    private weak var hudParent: SKNode?
    private var overlay: SKNode?
    private var screenW: CGFloat = 0
    private var screenH: CGFloat = 0
    /// Android canvas was ~1080×1920 px; iOS scene size is points.
    private var s: CGFloat = 1
    private var arcadeName: String = ArcadeTypeface.postScriptName

    private let white = UIColor.white
    private let gold = UIColor.yellow
    private let black = UIColor.black
    private let accentGold = UIColor(red: 0xB3/255, green: 0x54/255, blue: 0, alpha: 1)
    private let accentGray = UIColor(red: 0x3A/255, green: 0x3A/255, blue: 0x3A/255, alpha: 1)
    private let dim = UIColor(white: 0, alpha: 102/255)
    private let well = UIColor(white: 0, alpha: 0x99/255)
    private let idleStroke = UIColor(red: 0x6E/255, green: 0x6E/255, blue: 0x6E/255, alpha: 1)
    private let idleInner = UIColor(red: 0x3A/255, green: 0x3A/255, blue: 0x3A/255, alpha: 1)
    private let focusStroke = UIColor(red: 1, green: 0xD5/255, blue: 0x4A/255, alpha: 1)
    private let gageEmpty = UIColor(red: 0x5A/255, green: 0x5A/255, blue: 0x5A/255, alpha: 1)

    func setup(scene: SKScene, hudParent: SKNode? = nil) {
        self.scene = scene
        self.hudParent = hudParent
        arcadeName = ArcadeTypeface.postScriptName
        onSizeChanged(width: scene.size.width, height: scene.size.height)
    }

    func onSizeChanged(width: CGFloat, height: CGFloat) {
        screenW = width; screenH = height
        s = min(width / 1080, height / 1920)
        if s < 0.25 { s = 0.25 }
    }

    private func px(_ v: CGFloat) -> CGFloat { v * s }

    /// aspectFit shows the full 1080-wide canvas; aspectFill would crop the sides on a taller phone.
    private func hudXInset() -> CGFloat {
        guard scene?.scaleMode == .aspectFill else { return 0 }
        guard let view = scene?.view, view.bounds.height > 1, screenH > 1 else { return 0 }
        let viewAspect = view.bounds.width / view.bounds.height
        let sceneAspect = screenW / screenH
        if viewAspect + 0.001 < sceneAspect {
            let visibleW = screenH * viewAspect
            return max(0, (screenW - visibleW) * 0.5)
        }
        return 0
    }

    private func visibleLeft() -> CGFloat { hudXInset() }
    private func visibleRight() -> CGFloat { screenW - hudXInset() }
    private func visibleWidth() -> CGFloat { max(1, visibleRight() - visibleLeft()) }
    private func safeTextWidth() -> CGFloat { max(80, visibleWidth() - px(32)) }

    private func fittedSize(_ text: String, desired: CGFloat, maxWidth: CGFloat) -> CGFloat {
        var sz = desired
        while sz > 10 && measure(text, size: sz) > maxWidth { sz -= 1 }
        return sz
    }

    // MARK: - Frame render

    func render(
        state: GameState,
        attract: Attract,
        settingsOpen: Bool,
        difficulty: Int,
        fighterIndex: Int,
        lives: Int,
        hitsLeft: Int,
        maxHits: Int,
        bombs: Int,
        score: Int,
        gameOverT: Float,
        demoT: Float,
        flashT: Float,
        recapFrame: Int,
        recapPhase: Int,
        recapLives: Int,
        recapBombs: Int,
        recapGraze: Int,
        recapTotal: Int,
        stage: Int,
        briefing: SKTexture?,
        interstitialTimer: Float,
        creditsT: Float,
        pendingInitials: [Character],
        activeCharIndex: Int,
        currentChar: Character,
        highScores: HighScoreManager,
        version: String
    ) {
        guard let scene = scene else { return }
        overlay?.removeFromParent()
        let root = SKNode(); root.name = "arcadeUI"; root.zPosition = 200
        (hudParent ?? scene).addChild(root); overlay = root
        hits = Hits()

        switch state {
        case .interstitial:
            drawInterstitial(root, timer: interstitialTimer, stage: stage, briefing: briefing)
        case .difficultySelect:
            drawTitleBackdrop(root)
            dimScreen(root)
            drawDifficultySelect(root, selected: difficulty)
        case .characterSelect:
            drawTitleBackdrop(root)
            dimScreen(root)
            drawCharacterSelect(root, fighterIndex: fighterIndex, flashT: flashT)
        case .title:
            drawTitleBackdrop(root)
            if settingsOpen {
                dimScreen(root)
                drawSettings(root, flashT: flashT)
            } else if attract == .highScore {
                drawHighScores(root, highScores: highScores)
            } else {
                drawTitle(root, difficulty: difficulty, fighterIndex: fighterIndex, version: version)
            }
        case .registration:
            dimScreen(root)
            drawRegistration(root, pending: pendingInitials, active: activeCharIndex,
                             current: currentChar, flashT: flashT)
        case .campaignComplete:
            dimScreen(root)
            drawCredits(root, elapsed: creditsT)
        case .clear:
            drawHUD(root, lives: lives, hitsLeft: hitsLeft, maxHits: maxHits, bombs: bombs, score: score)
            drawStageClear(root, stage: stage, phase: recapPhase, lives: recapLives,
                           bombs: recapBombs, graze: recapGraze, total: recapTotal, frame: recapFrame)
        case .playing, .demo, .gameOver:
            drawHUD(root, lives: lives, hitsLeft: hitsLeft, maxHits: maxHits, bombs: bombs, score: score)
            if state == .demo && (Int(demoT * 2) % 2) == 0 {
                center(root, "DEMO", cx: screenW * 0.5, ay: screenH * 0.16, size: 42, color: gold)
            }
            if state == .gameOver && (Int(gameOverT * 2) % 2) == 0 {
                center(root, "GAME OVER", cx: screenW * 0.5, ay: screenH * 0.45, size: 42, color: gold)
            }
        }
    }

    func clearOverlay() {
        overlay?.removeFromParent()
        overlay = nil
    }

    // MARK: - Screens

    private func drawTitleBackdrop(_ root: SKNode) {
        let tex = GameArt.texture("Images/title_screen_backdrop", key: .none)
        let bmpW = max(tex.size().width, 1)
        let bmpH = max(tex.size().height, 1)
        let fill = max(screenW / bmpW, screenH / bmpH)
        let n = SKSpriteNode(texture: tex)
        n.size = CGSize(width: bmpW * fill, height: bmpH * fill)
        n.position = CGPoint(x: screenW * 0.5, y: screenH * 0.5)
        n.zPosition = -1
        n.name = "titleBackdrop"
        root.addChild(n)
    }

    private func drawTitle(_ root: SKNode, difficulty: Int, fighterIndex: Int, version: String) {
        let logo = SKSpriteNode(texture: GameArt.texture("Images/game_logo"))
        let maxH = screenH * 0.35 * 0.67 * 1.20
        let srcW = max(logo.size.width, 1)
        let srcH = max(logo.size.height, 1)
        var destH = maxH
        var destW = destH * (srcW / srcH)
        let maxW = visibleWidth() * 0.92 * 0.67 * 1.20
        if destW > maxW { destW = maxW; destH = destW * (srcH / srcW) }
        logo.size = CGSize(width: destW, height: destH)
        logo.position = CGPoint(x: screenW * 0.5, y: spriteY(androidTop: screenH * 0.06, height: destH))
        logo.zPosition = 1
        root.addChild(logo)

        let cx = screenW * 0.5
        let versionY = screenH - px(32)
        let creditY = versionY - px(28)
        let menuBottomAnchorY = creditY - px(130)
        let menuBlockStride = px(180)
        let tagSubPadding = px(64)
        let fighterMenuY = menuBottomAnchorY
        let fighterTagY = fighterMenuY + tagSubPadding
        let difficultyMenuY = fighterMenuY - menuBlockStride
        let difficultyTagY = difficultyMenuY + tagSubPadding
        let audioMenuY = difficultyMenuY - menuBlockStride
        let startPrompterY = audioMenuY - px(180)

        if (Int64(Date().timeIntervalSince1970 * 1000) / 600) % 2 == 0 {
            center(root, "1P START", cx: cx, ay: startPrompterY, size: 42, color: gold)
        }
        center(root, "[ AUDIO ]", cx: cx, ay: audioMenuY, size: 42, color: gold)
        hits.audio = goldHit(cx: cx, ay: audioMenuY, text: "[ AUDIO ]", extra: CGSize(width: px(120), height: px(60)))

        center(root, "[ DIFFICULTY ]", cx: cx, ay: difficultyMenuY, size: 42, color: gold)
        hits.difficulty = goldHit(cx: cx, ay: difficultyMenuY, text: "[ DIFFICULTY ]", extra: CGSize(width: px(120), height: px(60)))
        center(root, Difficulty(rawValue: difficulty)?.displayName ?? "NORMAL",
               cx: cx, ay: difficultyTagY, size: 32, color: white)

        center(root, "[ FIGHTER ]", cx: cx, ay: fighterMenuY, size: 42, color: gold)
        hits.fighter = goldHit(cx: cx, ay: fighterMenuY, text: "[ FIGHTER ]", extra: CGSize(width: px(120), height: px(60)))
        let tag = fighterIndex == 1 ? "TYPE-02: F6F HELLCAT" : "TYPE-01: P-38 LIGHTNING"
        center(root, tag, cx: cx, ay: fighterTagY, size: 32, color: white)

        center(root, "CREDIT 2026 Claudiu Colteu. All rights reserved.",
               cx: cx, ay: creditY, size: 20, color: white)
        center(root, "VER \(version)", cx: cx, ay: versionY, size: 20, color: white)
    }

    private func drawHighScores(_ root: SKNode, highScores: HighScoreManager) {
        let cx = screenW * 0.5
        center(root, "TOP SCORES", cx: cx, ay: screenH * 0.11, size: 48, color: gold)
        let rowStep = screenH * 0.065
        for i in 0..<HighScoreManager.SLOT_COUNT {
            var score = highScores.scoreAt(i)
            if score < 0 { score = 0 }
            if score > 99_999_999 { score = 99_999_999 }
            let line = "\(i + 1) \(pad8(score))  \(highScores.nameAt(i))  ST\(highScores.stageAt(i))"
            center(root, line, cx: cx, ay: screenH * 0.20 + CGFloat(i) * rowStep, size: 36, color: white)
        }
        if (Int64(Date().timeIntervalSince1970 * 1000) / 600) % 2 == 0 {
            center(root, "1P START", cx: cx, ay: screenH * 0.90, size: 42, color: gold)
        }
    }

    private func drawDifficultySelect(_ root: SKNode, selected: Int) {
        let cx = screenW * 0.5
        center(root, "SELECT DIFFICULTY", cx: cx, ay: screenH * 0.16, size: 42, color: gold)
        let top = screenH * 0.28
        let bottom = screenH * 0.76
        let step = (bottom - top) / 6
        let rowHalf = step * 0.42
        let hitLeft = visibleLeft() + visibleWidth() * 0.04
        let hitRight = visibleRight() - visibleWidth() * 0.04
        for i in 0..<7 {
            let lineY = top + CGFloat(i) * step
            hits.diffRows[i] = androidRect(hitLeft, lineY - rowHalf, hitRight, lineY + rowHalf)
            let name = Difficulty(rawValue: i + 1)?.displayName ?? ""
            let text = "\(i + 1). \(name)"
            let color = (i + 1) == selected ? gold : white
            center(root, text, cx: cx, ay: lineY, size: (i + 1) == selected ? 42 : 32, color: color)
        }
        let backY = screenH * 0.88
        center(root, "[ RETURN TO TITLE ]", cx: cx, ay: backY, size: 42, color: gold)
        hits.diffBack = goldHit(cx: cx, ay: backY, text: "[ RETURN TO TITLE ]", extra: .zero)
    }

    private func drawCharacterSelect(_ root: SKNode, fighterIndex: Int, flashT: Float) {
        let cx = screenW * 0.5
        let cy = screenH * 0.5
        center(root, "SELECT FIGHTER", cx: cx, ay: screenH * 0.14, size: 42, color: gold)

        let boxHeight = px(320)
        let textBlockHeight = px(340)
        let totalGroupHeight = boxHeight + textBlockHeight
        let boxTop = cy - totalGroupHeight * 0.5
        let boxBottom = boxTop + boxHeight
        let leftA = androidRect(screenW * 0.08, boxTop, screenW * 0.46, boxBottom)
        let rightA = androidRect(screenW * 0.54, boxTop, screenW * 0.92, boxBottom)
        hits.shipLeft = leftA
        hits.shipRight = rightA
        drawArcadeFrame(root, rect: leftA, focused: false)
        drawArcadeFrame(root, rect: rightA, focused: false)
        blitPreview(root, name: "Images/player_ship_4", box: leftA)
        blitPreview(root, name: "Images/player_b_4", box: rightA)
        let focusOn = (Int64(Date().timeIntervalSince1970 * 1000) / 400) % 2 == 0
        if focusOn {
            drawArcadeFrame(root, rect: fighterIndex == 1 ? rightA : leftA, focused: true)
        }

        let leftCX = leftA.midX
        let rightCX = rightA.midX
        let colW = leftA.width - px(8)
        let line1Y = boxBottom + px(110)
        let line2Y = line1Y + px(64)
        let line3Y = line2Y + px(72)
        center(root, "TYPE-01:", cx: leftCX, ay: line1Y, size: 32, color: gold, maxWidth: colW)
        center(root, "P-38 LIGHTNING", cx: leftCX, ay: line2Y, size: 32, color: gold, maxWidth: colW)
        center(root, "- FOCUS STORM -", cx: leftCX, ay: line3Y, size: 26, color: white, maxWidth: colW)
        center(root, "TYPE-02:", cx: rightCX, ay: line1Y, size: 32, color: gold, maxWidth: colW)
        center(root, "F6F HELLCAT", cx: rightCX, ay: line2Y, size: 32, color: gold, maxWidth: colW)
        center(root, "- LIGHTNING BLITZ -", cx: rightCX, ay: line3Y, size: 26, color: white, maxWidth: colW)

        let returnY = screenH * 0.88
        center(root, "[ RETURN TO TITLE ]", cx: cx, ay: returnY, size: 42, color: gold)
        hits.fighterBack = goldHit(cx: cx, ay: returnY, text: "[ RETURN TO TITLE ]", extra: CGSize(width: px(120), height: px(60)))
        _ = flashT
    }

    private func drawSettings(_ root: SKNode, flashT: Float) {
        let cx = screenW * 0.5
        center(root, "AUDIO SETTINGS", cx: cx, ay: screenH * 0.16, size: 42, color: gold)
        let mid = screenH * 0.52
        let bgm = SoundManager.instance.getBgmVolumeScale()
        center(root, "BGM \(Int(bgm * 100))%", cx: cx, ay: mid - screenH * 0.14, size: 52, color: white)
        let bgmHits = drawVolumeGage(root, cx: cx, baseline: mid - screenH * 0.06, fill: bgm, flashT: flashT)
        hits.bgmDown = bgmHits.0; hits.bgmUp = bgmHits.1
        let sfx = SoundManager.instance.getSfxVolumeScale()
        center(root, "SFX \(Int(sfx * 100))%", cx: cx, ay: mid + screenH * 0.06, size: 52, color: white)
        let sfxHits = drawVolumeGage(root, cx: cx, baseline: mid + screenH * 0.14, fill: sfx, flashT: flashT)
        hits.sfxDown = sfxHits.0; hits.sfxUp = sfxHits.1
        let backY = screenH * 0.88
        center(root, "[ RETURN TO TITLE ]", cx: cx, ay: backY, size: 42, color: gold)
        hits.settingsBack = goldHit(cx: cx, ay: backY, text: "[ RETURN TO TITLE ]", extra: .zero)
    }

    private func drawRegistration(_ root: SKNode, pending: [Character], active: Int,
                                  current: Character, flashT: Float) {
        let cx = screenW * 0.5
        hits.regLeft = androidRect(0, screenH * 0.25, screenW * 0.45, screenH * 0.65)
        hits.regRight = androidRect(screenW * 0.55, screenH * 0.25, screenW, screenH * 0.65)
        hits.regSet = androidRect(screenW * 0.10, screenH * 0.75, screenW * 0.90, screenH * 0.85)

        center(root, "REGISTRATION", cx: cx, ay: screenH * 0.18, size: 42, color: .red)
        center(root, "HI-SCORE ENTRY", cx: cx, ay: screenH * 0.24, size: 32, color: white)
        let charSpacing = px(110)
        let startX = cx - charSpacing
        let letterY = screenH * 0.46
        let blink = sin(Double(flashT) * 14) * 0.5 + 0.5
        let blinkA = CGFloat(80 + blink * 175) / 255
        for idx in 0..<3 {
            let slotX = startX + CGFloat(idx) * charSpacing
            let ch = idx == active ? current : pending[idx]
            if idx == active {
                center(root, "<", cx: slotX - px(54), ay: letterY, size: 72, color: white.withAlphaComponent(blinkA))
                center(root, ">", cx: slotX + px(54), ay: letterY, size: 72, color: white.withAlphaComponent(blinkA))
                center(root, String(ch), cx: slotX, ay: letterY, size: 72, color: gold.withAlphaComponent(blinkA))
            } else {
                center(root, String(ch), cx: slotX, ay: letterY, size: 72, color: gold)
            }
        }
        center(root, "[ PRESS ENTER TO LOCK INITIAL ]", cx: cx, ay: screenH * 0.78, size: 26, color: gold)
    }

    private func drawHUD(_ root: SKNode, lives: Int, hitsLeft: Int, maxHits: Int, bombs: Int, score: Int) {
        let inset = hudXInset()
        let bombWidth = px(80)
        let bombHeight = px(80)
        let lifeSize = px(72)
        let marginBottom = px(45)
        let bombStartY = screenH - marginBottom - bombHeight
        let lifeStartY = bombStartY + (bombHeight - lifeSize) * 0.5

        if lives > 0 {
            blitIcon(root, "Images/hud_life_icon",
                     android: CGRect(x: inset + px(45), y: lifeStartY, width: lifeSize, height: lifeSize))
            hudLeft(root, "x\(lives)", ax: inset + px(45) + lifeSize + px(10), ay: lifeStartY + lifeSize * 0.70, size: 32, color: white)
        }
        var i = 0
        while i < bombs {
            let posX = screenW - inset - px(45) - bombWidth - CGFloat(i) * (bombWidth + px(20))
            blitIcon(root, "Images/hud_bomb_icon",
                     android: CGRect(x: posX, y: bombStartY, width: bombWidth, height: bombHeight))
            i += 1
        }
        if lives > 0 {
            let pipW = px(70); let pipH = px(32); let pipGap = px(8)
            let rowW = CGFloat(maxHits) * pipW + CGFloat(maxHits - 1) * pipGap
            let pipLeft = (screenW - rowW) * 0.5
            let pipTop = lifeStartY + (lifeSize - pipH) * 0.5
            let filledName: String
            if hitsLeft >= 3 { filledName = "Images/hud_hit_pip_full" }
            else if hitsLeft == 2 { filledName = "Images/hud_hit_pip_mid" }
            else { filledName = "Images/hud_hit_pip_warn" }
            let warnVisible = hitsLeft > 1 || ((Int64(Date().timeIntervalSince1970 * 1000) / 180) & 1) == 0
            for seg in 0..<maxHits {
                let sx = pipLeft + CGFloat(seg) * (pipW + pipGap)
                let lit = seg < hitsLeft && warnVisible
                blitIcon(root, lit ? filledName : "Images/hud_hit_pip_empty",
                         android: CGRect(x: sx, y: pipTop, width: pipW, height: pipH),
                         key: .lime)
            }
        }
        let topTextY = px(80)
        hudLeft(root, "1PADV", ax: inset + px(30), ay: topTextY, size: 32, color: white)
        let scoreText = pad8(max(0, min(score, 99_999_999)))
        let scoreW = measure(scoreText, size: 32)
        hudLeft(root, scoreText, ax: screenW - inset - scoreW - px(30), ay: topTextY, size: 32, color: white)
    }

    private func drawStageClear(_ root: SKNode, stage: Int, phase: Int, lives: Int, bombs: Int,
                                graze: Int, total: Int, frame: Int) {
        let cx = screenW * 0.5
        center(root, "STAGE \(stage) CLEAR", cx: cx, ay: screenH * 0.20, size: 42, color: gold)
        if phase >= ScoreManager.PHASE_LIVES {
            center(root, "LIVES BONUS: \(lives) x 50,000", cx: cx, ay: screenH * 0.34, size: 32, color: white)
        }
        if phase >= ScoreManager.PHASE_BOMBS {
            center(root, "BOMBS BONUS: \(bombs) x 20,000", cx: cx, ay: screenH * 0.44, size: 32, color: white)
        }
        if phase >= ScoreManager.PHASE_GRAZE {
            center(root, "GRAZE BONUS: \(graze) x 500", cx: cx, ay: screenH * 0.54, size: 32, color: white)
        }
        if phase >= ScoreManager.PHASE_TOTAL {
            center(root, "STAGE CLEAR TOTAL:", cx: cx, ay: screenH * 0.66, size: 42, color: gold)
            center(root, "\(total)", cx: cx, ay: screenH * 0.74, size: 42, color: gold)
            if (frame % 60) < 30 {
                center(root, "PRESS FIRE TO CONTINUE", cx: cx, ay: screenH * 0.86, size: 32, color: white)
            }
        }
    }

    private func drawInterstitial(_ root: SKNode, timer: Float, stage: Int, briefing: SKTexture?) {
        var elapsed = 3.0 - CGFloat(timer)
        if elapsed < 0 { elapsed = 0 }
        var fade: CGFloat = 1
        if elapsed < 0.5 { fade = max(0, min(1, elapsed / 0.5)) }
        var cardTop: CGFloat = 0
        if let tex = briefing {
            let fill = SKSpriteNode(color: sampleTopLeft(tex), size: CGSize(width: screenW, height: screenH))
            fill.position = CGPoint(x: screenW * 0.5, y: screenH * 0.5)
            fill.alpha = 1
            fill.zPosition = 0
            root.addChild(fill)
            let img = SKSpriteNode(texture: tex)
            let scale = min(screenW / max(tex.size().width, 1), screenH / max(tex.size().height, 1))
            let drawW = tex.size().width * scale
            let drawH = tex.size().height * scale
            img.size = CGSize(width: drawW, height: drawH)
            img.alpha = fade
            img.position = CGPoint(x: screenW * 0.5, y: screenH * 0.5)
            cardTop = (screenH - drawH) * 0.5
            root.addChild(img)
        }
        let titleSize = px(42)
        let line1Y = cardTop + titleSize * 4.2
        let line2Y = line1Y + titleSize * 1.3
        center(root, "OPERATION:", cx: screenW * 0.5, ay: line1Y, size: titleSize,
               color: gold.withAlphaComponent(fade))
        center(root, StageCatalog.get(stage).operationNameString, cx: screenW * 0.5, ay: line2Y,
               size: titleSize, color: gold.withAlphaComponent(fade))
    }

    private func drawCredits(_ root: SKNode, elapsed: Float) {
        let lines = [
            "WW2 BLITZ", " ", "ALL STAGES COMPLETED", "---------------------",
            "DEVELOPER", "Claudiu Colteu", " ", "SPECIAL THANKS TO",
            "THE SHMUP COMMUNITY", " ", "THANK YOU FOR PLAYING!",
        ]
        var y = screenH - CGFloat(elapsed) * 75
        let cx = screenW * 0.5
        for (i, line) in lines.enumerated() {
            let goldLine = i == 0
            if y >= -60 && y <= screenH + 60 {
                center(root, line, cx: cx, ay: y, size: goldLine ? 42 : 32,
                       color: goldLine ? gold : white)
            }
            y += 55
        }
        if elapsed >= 22, (Int(elapsed * 3) % 2) == 0 {
            center(root, "TOUCH SCREEN TO REGISTER SCORE", cx: cx, ay: screenH * 0.85,
                   size: 42 * 0.65, color: gold)
        }
    }

    // MARK: - Widgets

    private func drawArcadeFrame(_ root: SKNode, rect: CGRect, focused: Bool) {
        if !focused {
            let wellN = SKShapeNode(rect: rect)
            wellN.fillColor = well; wellN.strokeColor = .clear; wellN.zPosition = 1
            root.addChild(wellN)
        }
        let outer = SKShapeNode(rect: rect)
        outer.fillColor = .clear
        outer.strokeColor = focused ? focusStroke : idleStroke
        outer.lineWidth = focused ? px(6) : px(5)
        outer.zPosition = 2
        root.addChild(outer)
        let inset = px(8)
        let innerR = rect.insetBy(dx: inset, dy: inset)
        let inner = SKShapeNode(rect: innerR)
        inner.fillColor = .clear
        inner.strokeColor = focused ? focusStroke : idleInner
        inner.lineWidth = px(2)
        inner.zPosition = 3
        root.addChild(inner)
        let tick = px(26)
        let color = focused ? focusStroke : idleStroke
        func tickLine(_ a: CGPoint, _ b: CGPoint) {
            let p = CGMutablePath(); p.move(to: a); p.addLine(to: b)
            let n = SKShapeNode(path: p); n.strokeColor = color; n.lineWidth = px(3); n.zPosition = 4
            root.addChild(n)
        }
        let l = rect.minX, t = rect.maxY, r = rect.maxX, b = rect.minY
        tickLine(CGPoint(x: l, y: t), CGPoint(x: l + tick, y: t))
        tickLine(CGPoint(x: l, y: t), CGPoint(x: l, y: t - tick))
        tickLine(CGPoint(x: r, y: t), CGPoint(x: r - tick, y: t))
        tickLine(CGPoint(x: r, y: t), CGPoint(x: r, y: t - tick))
        tickLine(CGPoint(x: l, y: b), CGPoint(x: l + tick, y: b))
        tickLine(CGPoint(x: l, y: b), CGPoint(x: l, y: b + tick))
        tickLine(CGPoint(x: r, y: b), CGPoint(x: r - tick, y: b))
        tickLine(CGPoint(x: r, y: b), CGPoint(x: r, y: b + tick))
    }

    private func blitPreview(_ root: SKNode, name: String, box: CGRect) {
        let n = SKSpriteNode(texture: GameArt.texture(name))
        let maxW = box.width * 0.78
        let maxH = box.height * 0.78
        let srcW = max(n.size.width, 1)
        let srcH = max(n.size.height, 1)
        let scale = min(maxW / srcW, maxH / srcH)
        n.size = CGSize(width: srcW * scale, height: srcH * scale)
        n.position = CGPoint(x: box.midX, y: box.midY)
        n.zPosition = 5
        ArcadeOutline.attach(to: n)
        root.addChild(n)
    }

    private func blitIcon(_ root: SKNode, _ name: String, android: CGRect, key: SpriteKey = .green) {
        let n = SKSpriteNode(texture: GameArt.texture(name, key: key))
        n.size = android.size
        n.position = CGPoint(x: android.midX, y: spriteY(androidTop: android.minY, height: android.height))
        n.zPosition = 2
        root.addChild(n)
    }

    @discardableResult
    private func drawVolumeGage(_ root: SKNode, cx: CGFloat, baseline: CGFloat, fill: Float,
                                flashT: Float) -> (CGRect, CGRect) {
        var gageSize: CGFloat = 88
        let caretSize: CGFloat = 56
        let caretBudget = measure("<", size: caretSize) * 2 + px(80)
        let maxGageW = max(80, safeTextWidth() - caretBudget)
        while gageSize > 24 && measure("■", size: gageSize) * 10 > maxGageW { gageSize -= 2 }
        let slotW = measure("■", size: gageSize)
        let slots = 10
        let squaresW = slotW * CGFloat(slots)
        let squaresLeft = cx - squaresW * 0.5
        let lit = min(slots, max(0, Int(fill * Float(slots) + 0.5)))
        for i in 0..<slots {
            let x = squaresLeft + CGFloat(i) * slotW
            hudLeft(root, "■", ax: x, ay: baseline, size: gageSize,
                    color: i < lit ? gold : gageEmpty)
        }
        let font = uiFont(gageSize)
        let squareTop = baseline - font.ascender
        let squareBottom = baseline - font.descender
        let track = CGRect(x: squaresLeft, y: squareTop, width: squaresW, height: squareBottom - squareTop)
        let blink = sin(Double(flashT) * 14) * 0.5 + 0.5
        let blinkA = CGFloat(80 + blink * 175) / 255
        let caretW = measure("<", size: caretSize)
        let caretGap = px(18)
        center(root, "<", cx: squaresLeft - caretGap - caretW * 0.5, ay: baseline,
               size: caretSize, color: white.withAlphaComponent(blinkA))
        center(root, ">", cx: squaresLeft + squaresW + caretGap + caretW * 0.5, ay: baseline,
               size: caretSize, color: white.withAlphaComponent(blinkA))
        let pad = px(40)
        let skTrack = androidRect(track.minX, track.minY, track.maxX, track.maxY)
        let down = androidRect(0, squareTop - pad, squaresLeft, squareBottom + pad)
        let up = androidRect(squaresLeft + squaresW, squareTop - pad, screenW, squareBottom + pad)
        _ = skTrack
        return (down, up)
    }

    // MARK: - Text

    private func center(_ root: SKNode, _ text: String, cx: CGFloat, ay: CGFloat,
                        size: CGFloat, color: UIColor, maxWidth: CGFloat? = nil) {
        let cap = maxWidth ?? safeTextWidth()
        let sz = fittedSize(text, desired: size, maxWidth: cap)
        let accent = (color == gold || color.cgColor.components?.prefix(3).elementsEqual([1, 1, 0]) == true)
            ? accentGold : accentGray
        func lab(_ c: UIColor, dx: CGFloat, dy: CGFloat, z: CGFloat) -> SKLabelNode {
            let font = uiFont(sz)
            let l = SKLabelNode(fontNamed: font.fontName)
            l.text = text; l.fontSize = font.pointSize; l.fontColor = c
            l.horizontalAlignmentMode = .center
            l.verticalAlignmentMode = .baseline
            l.position = CGPoint(x: cx + dx, y: screenH - ay - dy)
            l.zPosition = z
            return l
        }
        root.addChild(lab(black, dx: px(4), dy: px(4), z: 1))
        root.addChild(lab(accent, dx: px(2), dy: px(2), z: 2))
        root.addChild(lab(color, dx: 0, dy: 0, z: 3))
    }

    private func hudLeft(_ root: SKNode, _ text: String, ax: CGFloat, ay: CGFloat,
                         size: CGFloat, color: UIColor) {
        let accent = (color == gold || color.cgColor.components?.prefix(3).elementsEqual([1, 1, 0]) == true)
            ? accentGold : accentGray
        func lab(_ c: UIColor, dx: CGFloat, dy: CGFloat, z: CGFloat) -> SKLabelNode {
            let font = uiFont(size)
            let l = SKLabelNode(fontNamed: font.fontName)
            l.text = text; l.fontSize = font.pointSize; l.fontColor = c
            l.horizontalAlignmentMode = .left
            l.verticalAlignmentMode = .baseline
            l.position = CGPoint(x: ax + dx, y: screenH - ay - dy)
            l.zPosition = z
            return l
        }
        root.addChild(lab(black, dx: px(4), dy: px(4), z: 1))
        root.addChild(lab(accent, dx: px(2), dy: px(2), z: 2))
        root.addChild(lab(color, dx: 0, dy: 0, z: 3))
    }

    // MARK: - Geometry

    private func sampleTopLeft(_ tex: SKTexture) -> UIColor {
        let cg = tex.cgImage()
        guard let crop = cg.cropping(to: CGRect(x: 0, y: 0, width: 1, height: 1)) else { return .black }
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .black }
        ctx.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        if pixel[3] == 0 { return .black }
        let a = CGFloat(pixel[3]) / 255
        return UIColor(
            red: CGFloat(pixel[0]) / 255 / a,
            green: CGFloat(pixel[1]) / 255 / a,
            blue: CGFloat(pixel[2]) / 255 / a,
            alpha: 1
        )
    }

    private func dimScreen(_ root: SKNode) {
        let n = SKSpriteNode(color: dim, size: CGSize(width: screenW, height: screenH))
        n.anchorPoint = .zero; n.position = .zero; n.zPosition = 0
        root.addChild(n)
    }

    private func androidRect(_ l: CGFloat, _ t: CGFloat, _ r: CGFloat, _ b: CGFloat) -> CGRect {
        CGRect(x: l, y: screenH - b, width: r - l, height: b - t)
    }

    private func spriteY(androidTop: CGFloat, height: CGFloat) -> CGFloat {
        screenH - (androidTop + height * 0.5)
    }

    private func goldHit(cx: CGFloat, ay: CGFloat, text: String, extra: CGSize) -> CGRect {
        let sz = fittedSize(text, desired: 42, maxWidth: safeTextWidth())
        let font = uiFont(sz)
        let w = measure(text, size: sz)
        let l = cx - w * 0.5
        let t = ay - font.ascender
        let r = cx + w * 0.5
        let b = ay - font.descender
        var rect = androidRect(l, t, r, b)
        if extra != .zero {
            rect = rect.insetBy(dx: -extra.width / 2, dy: -extra.height / 2)
        }
        return rect
    }

    private func uiFont(_ androidSize: CGFloat) -> UIFont {
        // Android uses raw px on the 1080×1920 canvas. Scene is that canvas, so size ≈ androidSize.
        let size = max(10, androidSize * s)
        return UIFont(name: arcadeName, size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }

    private func measure(_ text: String, size: CGFloat) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: uiFont(size)]).width
    }

    private func pad8(_ score: Int) -> String {
        String(format: "%08d", score)
    }
}

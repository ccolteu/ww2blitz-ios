import Foundation

class DirectorCue {
    var bossCueFired: Bool = false

    func fireBoss(stageId: Int, boss: BossController) {
        if bossCueFired { return }
        boss.beginEntranceForStage(stageId)
        bossCueFired = true
    }
}

protocol StageDirector: AnyObject {
    func reset()
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue)
}

struct StageDirectors {
    static func create(waveScript: Int) -> StageDirector {
        switch waveScript {
        case StageWaveKind.IRON_TREADS:    return Stage2Director()
        case StageWaveKind.STEEL_ATLANTIC: return Stage3Director()
        case StageWaveKind.JUNGLE_RUINS:   return Stage4Director()
        case StageWaveKind.ASCENT_CANOPY:  return Stage5Director()
        case StageWaveKind.ORBIT_INTRO:    return Stage6Director()
        case StageWaveKind.FROZEN_FRONT:   return Stage7Director()
        case StageWaveKind.CORAL_ATOLL:    return Stage8Director()
        default:                           return Stage1Director()
        }
    }

    static func table() -> [StageDirector?] {
        let maxId = StageCatalog.maxId()
        var slots = [StageDirector?](repeating: nil, count: maxId + 1)
        for def in StageCatalog.all where def.id >= 0 && def.id <= maxId {
            slots[def.id] = create(waveScript: def.waveScript)
        }
        return slots
    }
}

// MARK: - Stage 1
class Stage1Director: StageDirector {
    private var flankGap: Float = FormationSpawner.FLANK_SPACING
    private var weaveGap: Float = 0
    private var vFormSpawned     = false
    private var s1CrossSpawned   = false
    private var wallSpawned      = false
    private var weaveStarted     = false

    func reset() {
        flankGap = FormationSpawner.FLANK_SPACING; weaveGap = 0
        vFormSpawned = false; s1CrossSpawned = false; wallSpawned = false; weaveStarted = false
    }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        if elapsed >= FormationSpawner.OPENING_END && elapsed <= FormationSpawner.FLANK_END {
            flankGap += dt
            var guard_ = 0
            while flankGap >= FormationSpawner.FLANK_SPACING && guard_ < 3 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                flankGap -= FormationSpawner.FLANK_SPACING; guard_ += 1
                enemies.spawnEnemy(startX: -0.06*w, startY: -0.06*h, velocityX:  FormationSpawner.SWEEP_VX, velocityY: FormationSpawner.SWEEP_VY, enemyType: FormationSpawner.TYPE_DRONE)
                enemies.spawnEnemy(startX:  1.06*w, startY: -0.06*h, velocityX: -FormationSpawner.SWEEP_VX, velocityY: FormationSpawner.SWEEP_VY, enemyType: FormationSpawner.TYPE_DRONE)
            }
        }
        if !vFormSpawned && elapsed >= FormationSpawner.V_FORM_AT { vFormSpawned = true; FormationSpawner.spawnVFormation(enemies: enemies, w: w, h: h) }
        if !weaveStarted && elapsed >= FormationSpawner.WEAVE_AT { weaveStarted = true; weaveGap = FormationSpawner.WEAVE_SPACING }
        if elapsed >= FormationSpawner.WEAVE_AT && elapsed <= FormationSpawner.WEAVE_END {
            weaveGap += dt; var g = 0
            while weaveGap >= FormationSpawner.WEAVE_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                weaveGap -= FormationSpawner.WEAVE_SPACING; g += 1
                enemies.spawnEnemy(startX: 0.14*w, startY: -0.02*h, velocityX: 0, velocityY: FormationSpawner.WEAVE_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
                enemies.spawnEnemy(startX: 0.86*w, startY: -0.02*h, velocityX: 0, velocityY: FormationSpawner.WEAVE_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
            }
        }
        if !s1CrossSpawned && elapsed >= FormationSpawner.S1_CROSS_AT { s1CrossSpawned = true; FormationSpawner.spawnSideCross(enemies: enemies, w: w, h: h, yFrac: FormationSpawner.S1_CROSS_Y, vx: FormationSpawner.CROSS_VX, vy: FormationSpawner.CROSS_VY, type: FormationSpawner.TYPE_DRONE) }
        if !wallSpawned && elapsed >= FormationSpawner.WALL_AT {
            wallSpawned = true
            enemies.spawnEnemy(startX: 0.30*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY, enemyType: FormationSpawner.TYPE_HEAVY, health: FormationSpawner.HEAVY_HP)
            enemies.spawnEnemy(startX: 0.70*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY, enemyType: FormationSpawner.TYPE_HEAVY, health: FormationSpawner.HEAVY_HP)
        }
    }
}

// MARK: - Stage 2
class Stage2Director: StageDirector {
    private var pincerCount = 0; private var pincerTimer: Float = -1
    private var flankHeavies = false; private var weaveCount = 0; private var weaveTimer: Float = 0
    private var turrets = false; private var kamiStep = 0; private var kamiDone = false
    private var tanks = false; private var leftWall = false; private var leftWallCount = 0
    private var rightWall = false; private var rightWallCount = 0
    private var preBoss = false; private var centerIntercept = false

    func reset() {
        pincerCount = 0; pincerTimer = -1; flankHeavies = false; weaveCount = 0; weaveTimer = 0
        turrets = false; kamiStep = 0; kamiDone = false; tanks = false
        leftWall = false; leftWallCount = 0; rightWall = false; rightWallCount = 0
        preBoss = false; centerIntercept = false
    }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        // Pincer pairs
        if elapsed >= FormationSpawner.S2_PINCER_AT && elapsed <= FormationSpawner.S2_PINCER_END && pincerCount < FormationSpawner.S2_PINCER_PAIRS {
            var g = 0
            while pincerCount < FormationSpawner.S2_PINCER_PAIRS && g < 4 {
                let at = FormationSpawner.S2_PINCER_AT + Float(pincerCount) * FormationSpawner.S2_PINCER_PAIR_GAP
                if elapsed < at { break }
                if pincerTimer < 0 { FormationSpawner.spawnS2Pincer(enemies: enemies, w: w, h: h, fromLeft: true); pincerTimer = 0 }
                if elapsed < at + FormationSpawner.S2_PINCER_STAGGER { break }
                FormationSpawner.spawnS2Pincer(enemies: enemies, w: w, h: h, fromLeft: false)
                pincerCount += 1; pincerTimer = -1; g += 1
            }
        }
        if !flankHeavies && elapsed >= FormationSpawner.S2_HEAVIES_AT {
            flankHeavies = true
            enemies.spawnEnemy(startX: 0.20*w, startY: -0.12*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY*1.2, enemyType: FormationSpawner.TYPE_HEAVY, health: FormationSpawner.HEAVY_HP, spawnCue: SpawnEvent.CUE_DEATH_CLEAR)
            enemies.spawnEnemy(startX: 0.80*w, startY: -0.12*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY*1.2, enemyType: FormationSpawner.TYPE_HEAVY, health: FormationSpawner.HEAVY_HP, spawnCue: SpawnEvent.CUE_DEATH_CLEAR)
        }
        if elapsed >= FormationSpawner.S2_WEAVE_AT && weaveCount < FormationSpawner.S2_WEAVE_COUNT {
            var g = 0
            while weaveCount < FormationSpawner.S2_WEAVE_COUNT && g < 3 {
                let at = FormationSpawner.S2_WEAVE_AT + Float(weaveCount) * FormationSpawner.S2_WEAVE_GAP
                if elapsed < at { break }
                let xFrac: Float = (weaveCount & 1) == 0 ? 0.12 : 0.88
                enemies.spawnEnemy(startX: xFrac*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.WEAVE_VY*1.4, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
                weaveCount += 1; g += 1
            }
        }
        if !turrets && elapsed >= FormationSpawner.S2_TURRETS_AT {
            turrets = true
            enemies.spawnEnemy(startX: 0.15*w, startY: -0.08*h, velocityX: 0, velocityY: FormationSpawner.INTERCEPT_VY, enemyType: FormationSpawner.TYPE_INTERCEPTOR, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.INTERCEPT_HP)
            enemies.spawnEnemy(startX: 0.85*w, startY: -0.08*h, velocityX: 0, velocityY: FormationSpawner.INTERCEPT_VY, enemyType: FormationSpawner.TYPE_INTERCEPTOR, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.INTERCEPT_HP)
        }
        if !kamiDone {
            if kamiStep == 0 && elapsed >= FormationSpawner.S2_KAMI_LEADER_AT {
                enemies.spawnEnemy(startX: 0.50*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.KAMI_VY_FAST, enemyType: FormationSpawner.TYPE_KAMIKAZE, health: FormationSpawner.KAMI_HP, spawnCue: SpawnEvent.CUE_DIAMOND_LEADER); kamiStep = 1
            }
            if kamiStep == 1 && elapsed >= FormationSpawner.S2_KAMI_WINGS_AT {
                enemies.spawnEnemy(startX: 0.28*w, startY: -0.05*h, velocityX:  FormationSpawner.KAMI_VX, velocityY: FormationSpawner.KAMI_VY, enemyType: FormationSpawner.TYPE_KAMIKAZE, health: FormationSpawner.KAMI_HP, spawnCue: SpawnEvent.CUE_DIAMOND_WING_L)
                enemies.spawnEnemy(startX: 0.72*w, startY: -0.05*h, velocityX: -FormationSpawner.KAMI_VX, velocityY: FormationSpawner.KAMI_VY, enemyType: FormationSpawner.TYPE_KAMIKAZE, health: FormationSpawner.KAMI_HP, spawnCue: SpawnEvent.CUE_DIAMOND_WING_R); kamiStep = 2
            }
            if kamiStep == 2 && elapsed >= FormationSpawner.S2_KAMI_TAIL_AT {
                enemies.spawnEnemy(startX: 0.50*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.KAMI_VY_FAST, enemyType: FormationSpawner.TYPE_KAMIKAZE, health: FormationSpawner.KAMI_HP); kamiStep = 3; kamiDone = true
            }
        }
        if !tanks && elapsed >= FormationSpawner.S2_TANKS_AT {
            tanks = true
            enemies.spawnEnemy(startX: FormationSpawner.S2_TANK_LANE_L*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY*2.2, enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.S2_TANK_HP, isLandVehicle: true)
            enemies.spawnEnemy(startX: FormationSpawner.S2_TANK_LANE_R*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY*2.2, enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.S2_TANK_HP, isLandVehicle: true)
        }
        if !leftWall && elapsed >= FormationSpawner.S2_LEFT_WALL_AT {
            var g = 0
            while leftWallCount < 3 && g < 3 {
                let at = FormationSpawner.S2_LEFT_WALL_AT + Float(leftWallCount) * FormationSpawner.S2_WALL_STAGGER
                if elapsed < at { break }
                if leftWallCount == 0 {
                    enemies.spawnEnemy(startX: -0.06*w, startY: 0.18*h, velocityX: FormationSpawner.CROSS_VX, velocityY: FormationSpawner.CROSS_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_DIAGONAL_SWEEP)
                } else if leftWallCount == 1 {
                    enemies.spawnEnemy(startX: -0.06*w, startY: 0.32*h, velocityX: FormationSpawner.CROSS_VX, velocityY: FormationSpawner.CROSS_VY*0.85, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_DIAGONAL_SWEEP)
                } else {
                    enemies.spawnEnemy(startX: -0.06*w, startY: 0.46*h, velocityX: FormationSpawner.CROSS_VX, velocityY: FormationSpawner.CROSS_VY*0.70, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_DIAGONAL_SWEEP)
                }
                leftWallCount += 1; g += 1
            }
            if leftWallCount >= 3 { leftWall = true }
        }
        if !rightWall && elapsed >= FormationSpawner.S2_RIGHT_WALL_AT {
            var g = 0
            while rightWallCount < 3 && g < 3 {
                let at = FormationSpawner.S2_RIGHT_WALL_AT + Float(rightWallCount) * FormationSpawner.S2_WALL_STAGGER
                if elapsed < at { break }
                if rightWallCount == 0 {
                    enemies.spawnEnemy(startX: 1.06*w, startY: 0.18*h, velocityX: -FormationSpawner.CROSS_VX, velocityY: FormationSpawner.CROSS_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_DIAGONAL_SWEEP)
                } else if rightWallCount == 1 {
                    enemies.spawnEnemy(startX: 1.06*w, startY: 0.32*h, velocityX: -FormationSpawner.CROSS_VX, velocityY: FormationSpawner.CROSS_VY*0.85, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_DIAGONAL_SWEEP)
                } else {
                    enemies.spawnEnemy(startX: 1.06*w, startY: 0.46*h, velocityX: -FormationSpawner.CROSS_VX, velocityY: FormationSpawner.CROSS_VY*0.70, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_DIAGONAL_SWEEP)
                }
                rightWallCount += 1; g += 1
            }
            if rightWallCount >= 3 { rightWall = true }
        }
        if !preBoss && elapsed >= FormationSpawner.S2_PRE_BOSS_AT {
            preBoss = true
            enemies.spawnEnemy(startX: 0.12*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.WEAVE_VY*1.5, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
            enemies.spawnEnemy(startX: 0.88*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.WEAVE_VY*1.5, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
        }
        if !centerIntercept && elapsed >= FormationSpawner.S2_CENTER_INTERCEPT_AT {
            centerIntercept = true
            enemies.spawnEnemy(startX: 0.12*w, startY: -0.08*h, velocityX: 0, velocityY: FormationSpawner.INTERCEPT_VY, enemyType: FormationSpawner.TYPE_INTERCEPTOR, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.INTERCEPT_HP)
        }
    }
}

// MARK: - Stage 3
class Stage3Director: StageDirector {
    private var scoutGap: Float = FormationSpawner.S3_SCOUT_SPACING
    private var cruiser = false; private var crossSpawned = false
    private var flankGap: Float = FormationSpawner.S3_FLANK_SPACING
    private var flankFromLeft = true
    private var destroyer = false

    func reset() {
        scoutGap = FormationSpawner.S3_SCOUT_SPACING; cruiser = false; crossSpawned = false
        flankGap = FormationSpawner.S3_FLANK_SPACING; flankFromLeft = true; destroyer = false
    }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        if cue.bossCueFired { return }
        if elapsed >= FormationSpawner.S3_SCOUT_START && elapsed <= FormationSpawner.S3_SCOUT_END {
            scoutGap += dt; var g = 0
            while scoutGap >= FormationSpawner.S3_SCOUT_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                scoutGap -= FormationSpawner.S3_SCOUT_SPACING; g += 1
                FormationSpawner.spawnStage3ScoutV(enemies: enemies, w: w, h: h)
            }
        }
        if !cruiser && elapsed >= FormationSpawner.S3_CRUISER_AT {
            cruiser = true
            enemies.spawnEnemy(startX: 0.30*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S3_CRUISER_HP)
            enemies.spawnEnemy(startX: 0.70*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S3_CRUISER_HP)
        }
        if !destroyer && elapsed >= FormationSpawner.S3_DESTROYER_AT {
            destroyer = true
            let vy = FormationSpawner.HEAVY_VY * 2.2
            enemies.spawnEnemy(startX: 0.28*w, startY: -0.06*h, velocityX: 0, velocityY: vy,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S3_DESTROYER_HP, isDestroyer: true)
            enemies.spawnEnemy(startX: 0.72*w, startY: -0.06*h, velocityX: 0, velocityY: vy,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S3_DESTROYER_HP, isDestroyer: true)
        }
        if !crossSpawned && elapsed >= FormationSpawner.S3_CROSS_AT {
            if enemies.countActive() < FormationSpawner.MAX_ACTIVE {
                crossSpawned = true
                FormationSpawner.spawnSideCross(enemies: enemies, w: w, h: h, yFrac: FormationSpawner.S3_CROSS_Y,
                                                vx: FormationSpawner.CROSS_VX, vy: FormationSpawner.CROSS_VY,
                                                type: FormationSpawner.TYPE_DRONE)
            }
        }
        if elapsed >= FormationSpawner.S3_FLANK_START && elapsed <= FormationSpawner.S3_FLANK_END {
            flankGap += dt; var g = 0
            while flankGap >= FormationSpawner.S3_FLANK_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                flankGap -= FormationSpawner.S3_FLANK_SPACING; g += 1
                let laneY = flankFromLeft
                    ? 0.10*h
                    : 0.10*h + FormationSpawner.formGapY(enemies: enemies, type: FormationSpawner.TYPE_INTERCEPTOR)
                if flankFromLeft {
                    enemies.spawnEnemy(startX: -0.08*w, startY: laneY, velocityX: FormationSpawner.SWEEP_VX*1.35,
                                       velocityY: FormationSpawner.FAST_DOWN*1.15, enemyType: FormationSpawner.TYPE_INTERCEPTOR,
                                       health: FormationSpawner.INTERCEPT_HP)
                } else {
                    enemies.spawnEnemy(startX: 1.08*w, startY: laneY, velocityX: -FormationSpawner.SWEEP_VX*1.35,
                                       velocityY: FormationSpawner.FAST_DOWN*1.15, enemyType: FormationSpawner.TYPE_INTERCEPTOR,
                                       health: FormationSpawner.INTERCEPT_HP)
                }
                flankFromLeft = !flankFromLeft
            }
        }
    }
}

// MARK: - Stage 4
class Stage4Director: StageDirector {
    private var flankGap: Float = FormationSpawner.S4_FLANK_SPACING
    private var weaveGap: Float = FormationSpawner.S4_WEAVE_SPACING
    private var weaveCount = 0
    private var kamiSpawned = false
    private var wallCount = 0
    private var holdVSpawned = false
    private var cruiserSpawned = false

    func reset() {
        flankGap = FormationSpawner.S4_FLANK_SPACING; weaveGap = FormationSpawner.S4_WEAVE_SPACING
        weaveCount = 0; kamiSpawned = false; wallCount = 0; holdVSpawned = false; cruiserSpawned = false
    }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        if cue.bossCueFired { return }
        if elapsed >= FormationSpawner.S4_FLANK_START && elapsed <= FormationSpawner.S4_FLANK_END {
            flankGap += dt; var g = 0
            while flankGap >= FormationSpawner.S4_FLANK_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                flankGap -= FormationSpawner.S4_FLANK_SPACING; g += 1
                let y = h * 0.40
                enemies.spawnEnemy(startX: -0.08*w, startY: y, velocityX: FormationSpawner.S4_FLANK_VX, velocityY: 0, enemyType: FormationSpawner.TYPE_DRONE)
                enemies.spawnEnemy(startX: 1.08*w, startY: y, velocityX: -FormationSpawner.S4_FLANK_VX, velocityY: 0, enemyType: FormationSpawner.TYPE_DRONE)
            }
        }
        if elapsed >= FormationSpawner.S4_WEAVE_START && elapsed <= FormationSpawner.S4_WEAVE_END && weaveCount < FormationSpawner.S4_WEAVE_PAIRS {
            weaveGap += dt; var g = 0
            while weaveCount < FormationSpawner.S4_WEAVE_PAIRS && weaveGap >= FormationSpawner.S4_WEAVE_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                weaveGap -= FormationSpawner.S4_WEAVE_SPACING; g += 1; weaveCount += 1
                enemies.spawnEnemy(startX: 0.12*w, startY: -0.02*h, velocityX: 0, velocityY: FormationSpawner.S4_WEAVE_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
                enemies.spawnEnemy(startX: 0.88*w, startY: -0.02*h, velocityX: 0, velocityY: FormationSpawner.S4_WEAVE_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
            }
        }
        if !cruiserSpawned && elapsed >= FormationSpawner.S4_CRUISER_AT {
            cruiserSpawned = true
            enemies.spawnEnemy(startX: 0.50*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.S4_CRUISER_VY,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S4_CRUISER_HP)
        }
        if !kamiSpawned && elapsed >= FormationSpawner.S4_KAMI_AT {
            kamiSpawned = true
            enemies.spawnEnemy(startX: -0.06*w, startY: 0.22*h, velocityX: FormationSpawner.S4_FLANK_VX*0.90,
                               velocityY: FormationSpawner.S4_KAMI_VY*0.70, enemyType: FormationSpawner.TYPE_KAMIKAZE)
            enemies.spawnEnemy(startX: 1.06*w, startY: 0.22*h, velocityX: -FormationSpawner.S4_FLANK_VX*0.90,
                               velocityY: FormationSpawner.S4_KAMI_VY*0.70, enemyType: FormationSpawner.TYPE_KAMIKAZE)
        }
        if elapsed >= FormationSpawner.S4_WALL_START && elapsed <= FormationSpawner.S4_WALL_END && wallCount < FormationSpawner.S4_WALL_COUNT {
            let at = FormationSpawner.S4_WALL_START + Float(wallCount) * FormationSpawner.S4_WALL_SPACING
            if elapsed >= at {
                let lane: Float
                if wallCount == 0 { lane = 0.10 }
                else if wallCount == 1 { lane = 0.22 }
                else if wallCount == 2 { lane = 0.78 }
                else { lane = 0.90 }
                enemies.spawnEnemy(startX: lane*w, startY: -0.04*h, velocityX: 0, velocityY: FormationSpawner.S4_WALL_VY, enemyType: FormationSpawner.TYPE_DRONE)
                wallCount += 1
            }
        }
        if !holdVSpawned && elapsed >= FormationSpawner.S4_HOLD_V_AT {
            holdVSpawned = true
            FormationSpawner.spawnVFormation(enemies: enemies, w: w, h: h)
        }
    }
}

// MARK: - Stage 5
class Stage5Director: StageDirector {
    private var flankGap: Float = FormationSpawner.S5_FLANK_SPACING
    private var flankFromLeft = true
    private var kamiVSpawned = false; private var heavyLeftSpawned = false
    private var wagonsSpawned = false; private var drizzleGap: Float = 0
    private var drizzleSeed: UInt64 = 1
    private var heavyRightSpawned = false; private var powerWaveSpawned = false
    private var kamiWallSpawned = false

    func reset() {
        flankGap = FormationSpawner.S5_FLANK_SPACING; flankFromLeft = true
        kamiVSpawned = false; heavyLeftSpawned = false
        wagonsSpawned = false; drizzleGap = 0; drizzleSeed = 1
        heavyRightSpawned = false; powerWaveSpawned = false; kamiWallSpawned = false
    }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        if cue.bossCueFired { return }
        if elapsed <= FormationSpawner.S5_FLANK_END {
            flankGap += dt; var g = 0
            while flankGap >= FormationSpawner.S5_FLANK_SPACING && g < 2 {
                flankGap -= FormationSpawner.S5_FLANK_SPACING; g += 1
                FormationSpawner.spawnS5FlankCascade(enemies: enemies, w: w, h: h, fromLeft: flankFromLeft)
                flankFromLeft = !flankFromLeft
            }
        }
        if !kamiVSpawned && elapsed >= FormationSpawner.S5_KAMI_V_AT {
            kamiVSpawned = true
            FormationSpawner.spawnS5CenterKamiV(enemies: enemies, w: w, h: h)
        }
        if !heavyLeftSpawned && elapsed >= FormationSpawner.S5_HEAVY_LEFT_AT {
            heavyLeftSpawned = true
            enemies.spawnEnemy(startX: 0.20*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S5_HEAVY_HP)
        }
        if !heavyRightSpawned && elapsed >= FormationSpawner.S5_HEAVY_RIGHT_AT {
            heavyRightSpawned = true
            enemies.spawnEnemy(startX: 0.80*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S5_HEAVY_HP)
        }
        if !wagonsSpawned && elapsed >= FormationSpawner.S5_WAGONS_AT {
            wagonsSpawned = true
            let vy = FormationSpawner.HEAVY_VY * 2.2
            enemies.spawnEnemy(startX: 0.22*w, startY: -0.06*h, velocityX: 0, velocityY: vy,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S5_WAGON_HP, isWagon: true)
            enemies.spawnEnemy(startX: 0.78*w, startY: -0.06*h, velocityX: 0, velocityY: vy,
                               enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD,
                               health: FormationSpawner.S5_WAGON_HP, isWagon: true)
        }
        if elapsed >= FormationSpawner.S5_DRIZZLE_START && elapsed <= FormationSpawner.S5_DRIZZLE_END {
            drizzleGap += dt; var g = 0
            while drizzleGap >= FormationSpawner.S5_DRIZZLE_SPACING && g < 2 {
                drizzleGap -= FormationSpawner.S5_DRIZZLE_SPACING; g += 1
                drizzleSeed = drizzleSeed &* 1664525 &+ 1013904223
                let u = Float((drizzleSeed >> 8) & 0xFFFFFF) / 16_777_215
                let xFrac: Float = 0.08 + u * 0.84
                enemies.spawnEnemy(startX: xFrac*w, startY: -0.04*h, velocityX: 0, velocityY: FormationSpawner.S5_DRIZZLE_VY,
                                   enemyType: FormationSpawner.TYPE_INTERCEPTOR, pattern: FormationSpawner.PATTERN_WEAVE)
            }
        }
        if !powerWaveSpawned && elapsed >= FormationSpawner.S5_POWER_WAVE_AT {
            powerWaveSpawned = true
            enemies.spawnEnemy(startX: 0.25*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.S5_POWER_VY,
                               enemyType: FormationSpawner.TYPE_DRONE, isRedShipAnchor: true)
            enemies.spawnEnemy(startX: 0.50*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.S5_POWER_VY,
                               enemyType: FormationSpawner.TYPE_DRONE, isRedShipAnchor: true)
            enemies.spawnEnemy(startX: 0.75*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.S5_POWER_VY,
                               enemyType: FormationSpawner.TYPE_DRONE, isRedShipAnchor: true)
        }
        if !kamiWallSpawned && elapsed >= FormationSpawner.S5_KAMI_WALL_AT {
            kamiWallSpawned = true
            var n = 0
            while n < 6 {
                let xFrac = (Float(n) + 0.5) / 6
                enemies.spawnEnemy(startX: xFrac*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.S5_KAMI_VY,
                                   enemyType: FormationSpawner.TYPE_KAMIKAZE)
                n += 1
            }
        }
        if elapsed >= FormationSpawner.S5_SCROLL_DECAY_AT {
            let u = min(max((elapsed - FormationSpawner.S5_SCROLL_DECAY_AT) / FormationSpawner.S5_SCROLL_DECAY_SPAN, 0), 1)
            stageData.scrollSpeedY = FormationSpawner.S5_SCROLL_START * (1 - u)
        }
        if allowBoss && elapsed >= stageData.def.bossAtSeconds {
            cue.fireBoss(stageId: stageData.currentStage, boss: boss)
            stageData.scrollSpeedY = 0
        }
    }
}

// MARK: - Stage 6 (intro only, no-op director)
class Stage6Director: StageDirector {
    func reset() {}
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {}
}

// MARK: - Stage 7
class Stage7Director: StageDirector {
    private var flurryGap: Float = FormationSpawner.S7_FLURRY_SPACING
    private var holdVSpawned = false; private var kamiSpawned = false
    private var crossSpawned = false; private var heaviesSpawned = false; private var wallSpawned = false

    func reset() { flurryGap = FormationSpawner.S7_FLURRY_SPACING; holdVSpawned = false; kamiSpawned = false; crossSpawned = false; heaviesSpawned = false; wallSpawned = false }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        if cue.bossCueFired { return }
        if elapsed >= FormationSpawner.S7_FLURRY_START && elapsed <= FormationSpawner.S7_FLURRY_END {
            flurryGap += dt; var g = 0
            while flurryGap >= FormationSpawner.S7_FLURRY_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                flurryGap -= FormationSpawner.S7_FLURRY_SPACING; g += 1
                enemies.spawnEnemy(startX: 0.18*w, startY: -0.04*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
                enemies.spawnEnemy(startX: 0.50*w, startY: -0.08*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY*0.92, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
                enemies.spawnEnemy(startX: 0.82*w, startY: -0.04*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
            }
        }
        if !holdVSpawned && elapsed >= FormationSpawner.S7_HOLD_V_AT { holdVSpawned = true; FormationSpawner.spawnVFormation(enemies: enemies, w: w, h: h) }
        if !kamiSpawned && elapsed >= FormationSpawner.S7_KAMI_AT { kamiSpawned = true; enemies.spawnEnemy(startX: -0.06*w, startY: 0.28*h, velocityX:  FormationSpawner.SWEEP_VX*0.85, velocityY: FormationSpawner.S7_KAMI_VY, enemyType: FormationSpawner.TYPE_KAMIKAZE); enemies.spawnEnemy(startX: 1.06*w, startY: 0.28*h, velocityX: -FormationSpawner.SWEEP_VX*0.85, velocityY: FormationSpawner.S7_KAMI_VY, enemyType: FormationSpawner.TYPE_KAMIKAZE) }
        if !crossSpawned && elapsed >= FormationSpawner.S7_CROSS_AT { if enemies.countActive() < FormationSpawner.MAX_ACTIVE { crossSpawned = true; FormationSpawner.spawnSideCross(enemies: enemies, w: w, h: h, yFrac: FormationSpawner.S7_CROSS_Y, vx: FormationSpawner.CROSS_VX, vy: FormationSpawner.CROSS_VY, type: FormationSpawner.TYPE_DRONE) } }
        if !heaviesSpawned && elapsed >= FormationSpawner.S7_HEAVIES_AT { heaviesSpawned = true; enemies.spawnEnemy(startX: 0.28*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY, enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.HEAVY_HP); enemies.spawnEnemy(startX: 0.72*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY, enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.HEAVY_HP) }
        if !wallSpawned && elapsed >= FormationSpawner.S7_WALL_AT {
            wallSpawned = true
            enemies.spawnEnemy(startX: 0.12*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY, enemyType: FormationSpawner.TYPE_DRONE)
            enemies.spawnEnemy(startX: 0.36*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY, enemyType: FormationSpawner.TYPE_DRONE)
            enemies.spawnEnemy(startX: 0.64*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY, enemyType: FormationSpawner.TYPE_DRONE)
            enemies.spawnEnemy(startX: 0.88*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.S7_FLURRY_VY, enemyType: FormationSpawner.TYPE_DRONE)
        }
    }
}

// MARK: - Stage 8
class Stage8Director: StageDirector {
    private var reefGap: Float = FormationSpawner.S8_REEF_SPACING
    private var holdVSpawned = false; private var kamiSpawned = false
    private var crossSpawned = false; private var heaviesSpawned = false; private var wallSpawned = false

    func reset() { reefGap = FormationSpawner.S8_REEF_SPACING; holdVSpawned = false; kamiSpawned = false; crossSpawned = false; heaviesSpawned = false; wallSpawned = false }
    func tick(dt: Float, elapsed: Float, enemies: EnemyPoolManager, w: Float, h: Float,
              boss: BossController, allowBoss: Bool, stageData: StageData, cue: DirectorCue) {
        if cue.bossCueFired { return }
        if elapsed >= FormationSpawner.S8_REEF_START && elapsed <= FormationSpawner.S8_REEF_END {
            reefGap += dt; var g = 0
            while reefGap >= FormationSpawner.S8_REEF_SPACING && g < 2 {
                if enemies.countActive() >= FormationSpawner.MAX_ACTIVE { break }
                reefGap -= FormationSpawner.S8_REEF_SPACING; g += 1
                enemies.spawnEnemy(startX: 0.22*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.S8_REEF_VY, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
                enemies.spawnEnemy(startX: 0.78*w, startY: -0.05*h, velocityX: 0, velocityY: FormationSpawner.S8_REEF_VY*1.06, enemyType: FormationSpawner.TYPE_DRONE, pattern: FormationSpawner.PATTERN_WEAVE)
            }
        }
        if !holdVSpawned && elapsed >= FormationSpawner.S8_HOLD_V_AT { holdVSpawned = true; FormationSpawner.spawnVFormation(enemies: enemies, w: w, h: h) }
        if !kamiSpawned && elapsed >= FormationSpawner.S8_KAMI_AT { kamiSpawned = true; enemies.spawnEnemy(startX: -0.06*w, startY: 0.32*h, velocityX: FormationSpawner.SWEEP_VX*0.90, velocityY: FormationSpawner.S8_KAMI_VY, enemyType: FormationSpawner.TYPE_KAMIKAZE); enemies.spawnEnemy(startX: 1.06*w, startY: 0.32*h, velocityX: -FormationSpawner.SWEEP_VX*0.90, velocityY: FormationSpawner.S8_KAMI_VY, enemyType: FormationSpawner.TYPE_KAMIKAZE) }
        if !crossSpawned && elapsed >= FormationSpawner.S8_CROSS_AT { if enemies.countActive() < FormationSpawner.MAX_ACTIVE { crossSpawned = true; FormationSpawner.spawnSideCross(enemies: enemies, w: w, h: h, yFrac: FormationSpawner.S8_CROSS_Y, vx: FormationSpawner.CROSS_VX*1.05, vy: FormationSpawner.CROSS_VY, type: FormationSpawner.TYPE_DRONE) } }
        if !heaviesSpawned && elapsed >= FormationSpawner.S8_HEAVIES_AT { heaviesSpawned = true; enemies.spawnEnemy(startX: 0.30*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY, enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.HEAVY_HP); enemies.spawnEnemy(startX: 0.70*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.HEAVY_VY, enemyType: FormationSpawner.TYPE_HEAVY, pattern: FormationSpawner.PATTERN_V_HOLD, health: FormationSpawner.HEAVY_HP) }
        if !wallSpawned && elapsed >= FormationSpawner.S8_WALL_AT {
            wallSpawned = true
            enemies.spawnEnemy(startX: 0.14*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.S8_REEF_VY*1.15, enemyType: FormationSpawner.TYPE_DRONE)
            enemies.spawnEnemy(startX: 0.38*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.S8_REEF_VY*1.15, enemyType: FormationSpawner.TYPE_DRONE)
            enemies.spawnEnemy(startX: 0.62*w, startY: -0.10*h, velocityX: 0, velocityY: FormationSpawner.S8_REEF_VY*1.15, enemyType: FormationSpawner.TYPE_DRONE)
            enemies.spawnEnemy(startX: 0.86*w, startY: -0.06*h, velocityX: 0, velocityY: FormationSpawner.S8_REEF_VY*1.15, enemyType: FormationSpawner.TYPE_DRONE)
        }
    }
}

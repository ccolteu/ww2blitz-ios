import Foundation

struct FormationSpawner {
    static let TYPE_DRONE       = EnemyPoolManager.TYPE_DRONE
    static let TYPE_KAMIKAZE    = EnemyPoolManager.TYPE_KAMIKAZE
    static let TYPE_INTERCEPTOR = EnemyPoolManager.TYPE_INTERCEPTOR
    static let TYPE_HEAVY       = EnemyPoolManager.TYPE_HEAVY
    static let PATTERN_WEAVE         = EnemyPoolManager.PATTERN_WEAVE
    static let PATTERN_V_HOLD        = EnemyPoolManager.PATTERN_V_HOLD
    static let PATTERN_DIAGONAL_SWEEP = EnemyPoolManager.PATTERN_DIAGONAL_SWEEP

    static let FAST_DOWN: Float = 320
    static let SWEEP_VX: Float = 210;  static let SWEEP_VY: Float = 240
    static let KAMI_VX: Float  = 340;  static let KAMI_VY: Float  = 560
    static let KAMI_VX_FAST: Float = 400; static let KAMI_VY_FAST: Float = 680
    static let FLANK_END: Float   = 8;   static let FLANK_SPACING: Float = 1.05
    static let V_FORM_AT: Float   = 12;  static let WEAVE_AT: Float     = 20.5
    static let WEAVE_END: Float   = 23.6; static let WALL_AT: Float     = 24.8
    static let S1_CROSS_AT: Float = 16;   static let S1_CROSS_Y: Float  = 0.36
    static let CROSS_VX: Float    = 280;  static let CROSS_VY: Float    = 110
    static let WEAVE_SPACING: Float = 1.35; static let WEAVE_VY: Float  = 150
    static let HEAVY_VY: Float = 78; static let HEAVY_HP = 10
    static let INTERCEPT_HP = 6; static let KAMI_HP = 2
    static let INTERCEPT_VY: Float = 210
    static let MAX_ACTIVE = 10
    static let OPENING_END: Float = 5
    static let POWER_WAVE_DELAY: Float = 3.0
    // Stage 2 timings
    static let S2_PINCER_AT: Float = 0.5; static let S2_PINCER_END: Float = 3.5
    static let S2_PINCER_PAIRS = 4; static let S2_PINCER_PAIR_GAP: Float = 0.6
    static let S2_PINCER_STAGGER: Float = 0.3; static let S2_HEAVIES_AT: Float = 6.5
    static let S2_WEAVE_AT: Float = 8; static let S2_WEAVE_GAP: Float = 1; static let S2_WEAVE_COUNT = 3
    static let S2_TURRETS_AT: Float = 13; static let S2_KAMI_LEADER_AT: Float = 14
    static let S2_KAMI_WINGS_AT: Float = 14.5; static let S2_KAMI_TAIL_AT: Float = 15
    static let S2_TANKS_AT: Float = 18.5; static let S2_TANK_LANE_L: Float = 0.30
    static let S2_TANK_LANE_R: Float = 0.70; static let S2_TANK_HP = 12
    static let S2_LEFT_WALL_AT: Float = 23; static let S2_RIGHT_WALL_AT: Float = 25
    static let S2_WALL_STAGGER: Float = 0.3; static let S2_PRE_BOSS_AT: Float = 27
    static let S2_CENTER_INTERCEPT_AT: Float = 28
    // Stage 3
    static let S3_SCOUT_START: Float = 1.5; static let S3_SCOUT_END: Float = 5.5
    static let S3_SCOUT_SPACING: Float = 1.65; static let S3_CRUISER_AT: Float = 7.5
    static let S3_CRUISER_HP = 16; static let S3_DESTROYER_AT: Float = 16; static let S3_DESTROYER_HP = 12
    static let S3_CROSS_AT: Float = 10.5; static let S3_CROSS_Y: Float = 0.38
    static let S3_MID_AT: Float = 12; static let S3_MID_HP = 96
    static let S3_RECOVERY_AT: Float = 38
    static let S3_FLANK_START: Float = 14; static let S3_FLANK_END: Float = 19.5
    static let S3_FLANK_SPACING: Float = 0.95; static let S3_BOSS_AT: Float = 42
    // Stage 6 (jungle)
    static let S6_FLANK_START: Float = 1; static let S6_FLANK_END: Float = 6
    static let S6_FLANK_SPACING: Float = 1.25; static let S6_FLANK_VX: Float = 340
    static let S6_CRUISER_AT: Float = 22; static let S6_CRUISER_HP = 96; static let S6_CRUISER_VY: Float = 80
    static let S6_WEAVE_START: Float = 15; static let S6_WEAVE_END: Float = 21
    static let S6_WEAVE_SPACING: Float = 1.5; static let S6_WEAVE_PAIRS = 5; static let S6_WEAVE_VY: Float = 160
    static let S6_KAMI_AT: Float = 25; static let S6_KAMI_VY: Float = 680
    static let S6_WALL_START: Float = 29.5; static let S6_WALL_END: Float = 33.5
    static let S6_WALL_SPACING: Float = 1; static let S6_WALL_COUNT = 4; static let S6_WALL_VY: Float = 440
    static let S6_HOLD_V_AT: Float = 35; static let S6_BOSS_AT: Float = 45
    // Stage 7 (canopy)
    static let S7_FLANK_END: Float = 12; static let S7_FLANK_SPACING: Float = 1.5
    static let S7_SWEEP_VX: Float = 260; static let S7_SWEEP_VY: Float = 280
    static let S7_KAMI_V_AT: Float = 8; static let S7_KAMI_VY: Float = 680
    static let S7_HEAVY_LEFT_AT: Float = 14; static let S7_HEAVY_RIGHT_AT: Float = 32
    static let S7_HEAVY_HP = 32; static let S7_WAGONS_AT: Float = 18.5; static let S7_WAGON_HP = 14
    static let S7_DRIZZLE_START: Float = 14; static let S7_DRIZZLE_END: Float = 17.5
    static let S7_DRIZZLE_SPACING: Float = 2; static let S7_DRIZZLE_VY: Float = 170
    static let S7_POWER_WAVE_AT: Float = 34; static let S7_POWER_VY: Float = 140
    static let S7_KAMI_WALL_AT: Float = 38; static let S7_SCROLL_DECAY_AT: Float = 40
    static let S7_SCROLL_DECAY_SPAN: Float = 5; static let S7_SCROLL_START: Float = 280
    // Stage 4 (frozen front)
    static let S4_FLURRY_START: Float = 6; static let S4_FLURRY_END: Float = 18
    static let S4_FLURRY_SPACING: Float = 1.55; static let S4_FLURRY_VY: Float = 140
    static let S4_HOLD_V_AT: Float = 20; static let S4_MID_AT: Float = 20; static let S4_MID_HP = 96
    static let S4_KAMI_AT: Float = 24; static let S4_KAMI_VY: Float = 620
    static let S4_CROSS_AT: Float = 28; static let S4_CROSS_Y: Float = 0.40
    static let S4_HEAVIES_AT: Float = 32; static let S4_WALL_AT: Float = 36
    // Stage 5 (coral atoll)
    static let S5_REEF_START: Float = 6; static let S5_REEF_END: Float = 16.5
    static let S5_REEF_SPACING: Float = 1.40; static let S5_REEF_VY: Float = 165
    static let S5_HOLD_V_AT: Float = 18.5; static let S5_MID_AT: Float = 18.5; static let S5_MID_HP = 96
    static let S5_KAMI_AT: Float = 23; static let S5_KAMI_VY: Float = 640
    static let S5_CROSS_AT: Float = 27; static let S5_CROSS_Y: Float = 0.42
    static let S5_HEAVIES_AT: Float = 31; static let S5_WALL_AT: Float = 35
    static let FORM_CLEAR: Float = 2.4

    static func spawnSideCross(enemies: EnemyPoolManager, w: Float, h: Float,
                               yFrac: Float, vx: Float, vy: Float, type: Int) {
        enemies.spawnEnemy(startX: -0.06*w, startY: yFrac*h, velocityX:  vx, velocityY: vy, enemyType: type, pattern: PATTERN_DIAGONAL_SWEEP)
        enemies.spawnEnemy(startX:  1.06*w, startY: yFrac*h, velocityX: -vx, velocityY: vy, enemyType: type, pattern: PATTERN_DIAGONAL_SWEEP)
    }

    static func spawnMidBoss(enemies: EnemyPoolManager, w: Float, h: Float, xFrac: Float, hp: Int,
                             isDestroyer: Bool = false, isLandVehicle: Bool = false, isHelicopter: Bool = false) {
        enemies.spawnEnemy(startX: xFrac * w, startY: -0.12 * h, velocityX: 0, velocityY: HEAVY_VY,
                           enemyType: TYPE_HEAVY, pattern: PATTERN_V_HOLD, health: hp,
                           isDestroyer: isDestroyer, isLandVehicle: isLandVehicle,
                           isHelicopter: isHelicopter, isMidBoss: true)
    }

    static func spawnVFormation(enemies: EnemyPoolManager, w: Float, h: Float) {
        let gx = formGapX(enemies: enemies, type: TYPE_INTERCEPTOR)
        let gy = formGapY(enemies: enemies, type: TYPE_INTERCEPTOR)
        let cx = 0.50*w; let cy = -0.02*h
        enemies.spawnEnemy(startX: cx,      startY: cy,      velocityX: 0, velocityY: INTERCEPT_VY, enemyType: TYPE_INTERCEPTOR, pattern: PATTERN_V_HOLD, health: INTERCEPT_HP)
        enemies.spawnEnemy(startX: cx-gx,   startY: cy-gy,   velocityX: 0, velocityY: INTERCEPT_VY, enemyType: TYPE_INTERCEPTOR, pattern: PATTERN_V_HOLD, health: INTERCEPT_HP)
        enemies.spawnEnemy(startX: cx+gx,   startY: cy-gy,   velocityX: 0, velocityY: INTERCEPT_VY, enemyType: TYPE_INTERCEPTOR, pattern: PATTERN_V_HOLD, health: INTERCEPT_HP)
    }

    static func spawnS2Pincer(enemies: EnemyPoolManager, w: Float, h: Float, fromLeft: Bool) {
        let vx = SWEEP_VX * 1.3; let vy = SWEEP_VY * 1.1
        if fromLeft { enemies.spawnEnemy(startX: -0.05*w, startY: -0.05*h, velocityX:  vx, velocityY: vy, enemyType: TYPE_DRONE) }
        else        { enemies.spawnEnemy(startX:  1.05*w, startY: -0.05*h, velocityX: -vx, velocityY: vy, enemyType: TYPE_DRONE) }
    }

    static func spawnStage3ScoutV(enemies: EnemyPoolManager, w: Float, h: Float) {
        let vy = WEAVE_VY * 1.7; let gx = formGapX(enemies: enemies, type: TYPE_DRONE); let gy = formGapY(enemies: enemies, type: TYPE_DRONE)
        let cx = 0.50*w; let cy = -0.04*h
        enemies.spawnEnemy(startX: cx, startY: cy, velocityX: 0, velocityY: vy, enemyType: TYPE_DRONE, pattern: PATTERN_WEAVE)
        enemies.spawnEnemy(startX: cx-gx, startY: cy-gy, velocityX: 0, velocityY: vy, enemyType: TYPE_DRONE, pattern: PATTERN_WEAVE)
        enemies.spawnEnemy(startX: cx+gx, startY: cy-gy, velocityX: 0, velocityY: vy, enemyType: TYPE_DRONE, pattern: PATTERN_WEAVE)
        enemies.spawnEnemy(startX: cx-gx*2, startY: cy-gy*2, velocityX: 0, velocityY: vy, enemyType: TYPE_DRONE, pattern: PATTERN_WEAVE)
        enemies.spawnEnemy(startX: cx+gx*2, startY: cy-gy*2, velocityX: 0, velocityY: vy, enemyType: TYPE_DRONE, pattern: PATTERN_WEAVE)
    }

    static func spawnS7FlankCascade(enemies: EnemyPoolManager, w: Float, h: Float, fromLeft: Bool) {
        for n in 0..<4 {
            let t = Float(n) / 3
            let x = fromLeft ? (0 + t*0.20)*w : (1 - t*0.20)*w
            let vx = fromLeft ? S7_SWEEP_VX : -S7_SWEEP_VX
            enemies.spawnEnemy(startX: x, startY: -0.05*h, velocityX: vx, velocityY: S7_SWEEP_VY, enemyType: TYPE_DRONE, pattern: PATTERN_DIAGONAL_SWEEP)
        }
    }

    static func spawnS7CenterKamiV(enemies: EnemyPoolManager, w: Float, h: Float) {
        let vy = S7_KAMI_VY * 0.70
        enemies.spawnEnemy(startX: -0.06*w, startY: 0.10*h, velocityX:  S7_SWEEP_VX,      velocityY: vy, enemyType: TYPE_KAMIKAZE)
        enemies.spawnEnemy(startX: -0.06*w, startY: 0.22*h, velocityX:  S7_SWEEP_VX*1.10, velocityY: vy, enemyType: TYPE_KAMIKAZE)
        enemies.spawnEnemy(startX:  1.06*w, startY: 0.10*h, velocityX: -S7_SWEEP_VX,      velocityY: vy, enemyType: TYPE_KAMIKAZE)
        enemies.spawnEnemy(startX:  1.06*w, startY: 0.22*h, velocityX: -S7_SWEEP_VX*1.10, velocityY: vy, enemyType: TYPE_KAMIKAZE)
        enemies.spawnEnemy(startX: -0.06*w, startY: 0.34*h, velocityX:  S7_SWEEP_VX*0.90, velocityY: vy, enemyType: TYPE_KAMIKAZE)
    }

    static func spawnSweepArcSquadron(enemies: EnemyPoolManager, h: Float) {
        let parkX: Float = -64; let parkY = h * 0.08
        let gap = enemies.sweepArcTailDelay()
        let profile = Enemy.FLIGHT_PROFILE_SWEEP_ARC
        enemies.spawnEnemy(startX: parkX, startY: parkY, velocityX: 0, velocityY: 0, enemyType: TYPE_DRONE, isRedShipAnchor: true, flightProfile: profile, patternDelay: 0)
        for i in 1...4 { enemies.spawnEnemy(startX: parkX, startY: parkY, velocityX: 0, velocityY: 0, enemyType: TYPE_DRONE, flightProfile: profile, patternDelay: Float(i)*gap) }
    }

    static func spawnOpeningPowerV(enemies: EnemyPoolManager, w: Float, h: Float) { spawnSweepArcSquadron(enemies: enemies, h: h) }
    static func spawnResupplyColumn(enemies: EnemyPoolManager, w: Float, h: Float) { spawnSweepArcSquadron(enemies: enemies, h: h) }

    static func formGapX(enemies: EnemyPoolManager, type: Int) -> Float { enemies.halfWOf(type) * FORM_CLEAR }
    static func formGapY(enemies: EnemyPoolManager, type: Int) -> Float { enemies.halfHOf(type) * FORM_CLEAR }
}

import Foundation

class SpawnTimeline {
    private var elapsedTime: Float = 0
    private var activeStage: Int = 0
    private var openingPowerVSpawned: Bool = false
    private var powerUpWaveQueued: Bool = false
    private var powerUpWaveTimer: Float = 0
    private let cue = DirectorCue()
    private let directors: [StageDirector?]

    init() {
        directors = StageDirectors.table()
    }

    func elapsedSeconds() -> Float { elapsedTime }

    func forceElapsed(_ targetSeconds: Float) { elapsedTime = targetSeconds }

    func update(dt: Float, enemyManager: EnemyPoolManager, screenWidth: Int, screenHeight: Int,
                boss: BossController, bossEnterSeconds: Float, allowBoss: Bool,
                playerWeaponPower: Int, stageData: StageData) {
        if screenWidth <= 0 || screenHeight <= 0 { return }
        activeStage = stageData.currentStage
        let def = StageCatalog.get(activeStage)
        let w = Float(screenWidth); let h = Float(screenHeight)

        if def.introOnly {
            if !cue.bossCueFired {
                elapsedTime += dt
                if allowBoss && elapsedTime >= def.introSecs {
                    cue.fireBoss(stageId: def.id, boss: boss)
                    elapsedTime = def.introSecs
                }
            }
            return
        }
        if !(def.locksElapsedAtBoss && cue.bossCueFired) { elapsedTime += dt }
        if def.usesOpeningPowerV && !openingPowerVSpawned && elapsedTime >= 0 && elapsedTime <= FormationSpawner.OPENING_END {
            openingPowerVSpawned = true
            FormationSpawner.spawnOpeningPowerV(enemies: enemyManager, w: w, h: h)
        }
        updatePowerSafeguard(dt: dt, enemies: enemyManager, w: w, h: h,
                             playerWeaponPower: playerWeaponPower, boss: boss)
        if def.id >= 0 && def.id < directors.count {
            directors[def.id]?.tick(dt: dt, elapsed: elapsedTime, enemies: enemyManager,
                                    w: w, h: h, boss: boss, allowBoss: allowBoss,
                                    stageData: stageData, cue: cue)
        }
        if allowBoss && !cue.bossCueFired && def.usesSharedBossEntranceCue && elapsedTime >= def.bossAtSeconds {
            cue.fireBoss(stageId: def.id, boss: boss)
        }
    }

    func reset() {
        elapsedTime = 0; activeStage = 0; openingPowerVSpawned = false
        powerUpWaveQueued = false; powerUpWaveTimer = 0; cue.bossCueFired = false
        directors.forEach { $0?.reset() }
    }

    private func updatePowerSafeguard(dt: Float, enemies: EnemyPoolManager, w: Float, h: Float,
                                       playerWeaponPower: Int, boss: BossController) {
        let bossOnScreen = cue.bossCueFired || boss.isActive() || boss.isExploding()
        let emergencyLive = enemies.hasActiveRedShipAnchor()
        if playerWeaponPower >= 2 || bossOnScreen { powerUpWaveQueued = false; powerUpWaveTimer = 0; return }
        if !powerUpWaveQueued && !emergencyLive { powerUpWaveQueued = true; powerUpWaveTimer = 0 }
        if !powerUpWaveQueued { return }
        powerUpWaveTimer += dt
        if powerUpWaveTimer < FormationSpawner.POWER_WAVE_DELAY { return }
        FormationSpawner.spawnResupplyColumn(enemies: enemies, w: w, h: h)
        powerUpWaveQueued = false; powerUpWaveTimer = 0
    }
}

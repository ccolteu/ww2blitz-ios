import AVFoundation

class SoundManager {
    static let instance = SoundManager()

    static let BGM_STAGE1  = "bgm_stage1"
    static let BGM_STAGE2  = "bgm_stage2"
    static let BGM_STAGE3  = "bgm_stage3"
    static let BGM_STAGE4  = "bgm_stage4"
    static let BGM_STAGE5  = "bgm_stage5"
    static let BGM_STAGE6  = "bgm_stage6"
    static let BGM_STAGE7  = "bgm_stage7"
    static let BGM_STAGE8  = "bgm_stage8"
    static let BGM_TITLE   = "bgm_title"
    static let BGM_BOSS    = "bgm_boss"
    static let BGM_BOSS2   = "bgm_boss2"
    static let BGM_VICTORY = "bgm_victory"

    static let SFX_VULCAN          = 0
    static let SFX_LASER           = 1
    static let SFX_SMALL_EXPLOSION = 2
    static let SFX_HEAVY_EXPLOSION = 3
    static let SFX_ALARM           = 4
    static let SFX_PICKUP          = 5
    static let SFX_BOMB            = 6
    static let SFX_BOSS_WARNING    = 7

    private let sfxNames = ["sfx_vulcan","sfx_laser","sfx_small_explosion",
                            "sfx_heavy_explosion","sfx_alarm","sfx_pickup","sfx_bomb",
                            "sfx_boss_warning"]
    private static let MAX_VOICES = 16

    private var engine = AVAudioEngine()
    private var sfxVoices: [AVAudioPlayerNode] = []
    private var sfxVoiceIndex = 0
    private var sfxBuffers: [AVAudioPCMBuffer?] = []
    private var bgmPlayer   = AVAudioPlayerNode()
    private var alarmPlayer = AVAudioPlayerNode()
    private var mixerFormat: AVAudioFormat?
    private var bgmCache: [String: AVAudioPCMBuffer] = [:]
    private var currentBgm: String = ""
    private var alarmLooping = false
    private var paused = false
    private var bgmWasPlaying = false

    var bgmVolume: Float = 0.5 {
        didSet { applyVolumes() }
    }
    var sfxVolume: Float = 0.65 {
        didSet { applyVolumes() }
    }
    var muted: Bool = false {
        didSet {
            applyVolumes()
            if muted {
                stopAlarm()
                pauseBGMRemembering()
            } else if !paused {
                resumeBGMIfNeeded()
            }
        }
    }

    private let kPrefs = "StrikersAudioPrefs"

    init() {
        loadPrefs()
        setupEngine()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    private func setupEngine() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)

        let mixer = engine.mainMixerNode
        let sampleRate = session.sampleRate > 0 ? session.sampleRate : 44_100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
            ?? mixer.outputFormat(forBus: 0)
        mixerFormat = format

        engine.attach(bgmPlayer)
        engine.connect(bgmPlayer, to: mixer, format: format)
        engine.attach(alarmPlayer)
        engine.connect(alarmPlayer, to: mixer, format: format)
        for _ in 0..<SoundManager.MAX_VOICES {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)
            sfxVoices.append(node)
        }
        sfxBuffers = sfxNames.map { loadBuffer(named: $0) }
        applyVolumes()
        try? engine.start()
    }

    func playBGM(_ name: String, loop: Bool = true) {
        if name.isEmpty { stopBGM(); return }
        if currentBgm == name && (bgmPlayer.isPlaying || paused) { return }
        currentBgm = name
        bgmPlayer.stop()
        guard let buf = cachedBuffer(named: name) else { return }
        bgmPlayer.volume = muted || paused ? 0 : bgmVolume
        bgmPlayer.scheduleBuffer(buf, at: nil, options: loop ? .loops : [])
        bgmWasPlaying = !paused && !muted
        if paused || muted { return }
        ensureRunning()
        bgmPlayer.play()
    }

    func isBgmPlaying(_ name: String) -> Bool {
        !name.isEmpty && name == currentBgm && bgmPlayer.isPlaying
    }

    func currentBgmName() -> String { currentBgm }

    func stopBGM() {
        bgmPlayer.stop()
        currentBgm = ""
        bgmWasPlaying = false
    }

    func pauseAll() {
        paused = true
        stopAlarm()
        pauseBGMRemembering()
        for node in sfxVoices { if node.isPlaying { node.pause() } }
    }

    func resumeAll() {
        paused = false
        if muted { return }
        ensureRunning()
        try? AVAudioSession.sharedInstance().setActive(true)
        for node in sfxVoices { if !node.isPlaying { node.play() } }
        resumeBGMIfNeeded()
        applyVolumes()
    }

    func playSFX(_ index: Int) {
        if paused || muted { return }
        if index == SoundManager.SFX_ALARM {
            playAlarm()
            return
        }
        guard index >= 0 && index < sfxBuffers.count else { return }
        guard let buf = sfxBuffers[index] else { return }
        let node = sfxVoices[sfxVoiceIndex]
        sfxVoiceIndex = (sfxVoiceIndex + 1) % sfxVoices.count
        node.volume = sfxVolume
        node.scheduleBuffer(buf)
        ensureRunning()
        if !node.isPlaying { node.play() }
    }

    func playAlarm() {
        if paused || muted { return }
        if alarmLooping && alarmPlayer.isPlaying { return }
        guard let buf = cachedBuffer(named: "sfx_alarm") else { return }
        alarmPlayer.stop()
        alarmPlayer.volume = sfxVolume
        alarmPlayer.scheduleBuffer(buf, at: nil, options: .loops)
        ensureRunning()
        alarmPlayer.play()
        alarmLooping = true
    }

    func stopAlarm() {
        alarmPlayer.stop()
        alarmLooping = false
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeVal) else { return }
        switch type {
        case .began:
            pauseAll()
        case .ended:
            let opts = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            if opts.contains(.shouldResume) {
                resumeAll()
            }
        @unknown default:
            break
        }
    }

    private func pauseBGMRemembering() {
        if bgmPlayer.isPlaying {
            bgmWasPlaying = true
            bgmPlayer.pause()
        }
    }

    private func resumeBGMIfNeeded() {
        if muted || paused || currentBgm.isEmpty { return }
        if bgmWasPlaying || !bgmPlayer.isPlaying {
            applyVolumes()
            ensureRunning()
            bgmPlayer.play()
            bgmWasPlaying = true
        }
    }

    private func applyVolumes() {
        bgmPlayer.volume = muted || paused ? 0 : bgmVolume
        alarmPlayer.volume = muted || paused ? 0 : sfxVolume
        let v: Float = muted || paused ? 0 : sfxVolume
        for node in sfxVoices { node.volume = v }
    }

    private func ensureRunning() {
        if !engine.isRunning {
            try? engine.start()
        }
    }

    private func cachedBuffer(named name: String) -> AVAudioPCMBuffer? {
        if let cached = bgmCache[name] { return cached }
        guard let buf = loadBuffer(named: name) else { return nil }
        bgmCache[name] = buf
        return buf
    }

    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav",
                                        subdirectory: "Audio") else { return nil }
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let srcFormat = file.processingFormat
        let length = AVAudioFrameCount(file.length)
        guard length > 0,
              let source = AVAudioPCMBuffer(pcmFormat: srcFormat, frameCapacity: length)
        else { return nil }
        do {
            try file.read(into: source)
        } catch {
            return nil
        }
        guard let target = mixerFormat else { return source }
        return convert(source, to: target) ?? source
    }

    private func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if buffer.format.channelCount == format.channelCount
            && abs(buffer.format.sampleRate - format.sampleRate) < 0.5
            && buffer.format.commonFormat == format.commonFormat {
            return buffer
        }
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else { return nil }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 256
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: max(capacity, 1)) else {
            return nil
        }
        var error: NSError?
        var supplied = false
        converter.convert(to: output, error: &error) { _, status in
            if supplied {
                status.pointee = .endOfStream
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }
        if error != nil { return nil }
        return output
    }

    func getBgmVolumeScale() -> Float { bgmVolume }
    func setBgmVolumeScale(_ value: Float) {
        bgmVolume = max(0, min(1, value))
        savePrefs()
    }
    func getSfxVolumeScale() -> Float { sfxVolume }
    func setSfxVolumeScale(_ value: Float) {
        sfxVolume = max(0, min(1, value))
        savePrefs()
    }

    func savePrefs() {
        let d = UserDefaults.standard
        d.set(bgmVolume, forKey: kPrefs + "_bgm")
        d.set(sfxVolume, forKey: kPrefs + "_sfx")
    }
    private func loadPrefs() {
        let d = UserDefaults.standard
        if d.object(forKey: kPrefs + "_bgm") != nil {
            bgmVolume = d.float(forKey: kPrefs + "_bgm")
            sfxVolume = d.float(forKey: kPrefs + "_sfx")
        }
    }
}

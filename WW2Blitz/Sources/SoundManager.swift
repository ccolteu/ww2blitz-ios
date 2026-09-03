import AVFoundation

class SoundManager {
    static let instance = SoundManager()

    // BGM track identifiers (filename stems without extension)
    static let BGM_STAGE1  = "bgm_stage1"
    static let BGM_STAGE2  = "bgm_stage2"
    static let BGM_TITLE   = "bgm_title"
    static let BGM_BOSS    = "bgm_boss"
    static let BGM_VICTORY = "bgm_victory"

    // SFX indices
    static let SFX_VULCAN          = 0
    static let SFX_LASER           = 1
    static let SFX_SMALL_EXPLOSION = 2
    static let SFX_HEAVY_EXPLOSION = 3
    static let SFX_ALARM           = 4
    static let SFX_PICKUP          = 5
    static let SFX_BOMB            = 6

    private let sfxNames = ["sfx_vulcan","sfx_laser","sfx_small_explosion",
                            "sfx_heavy_explosion","sfx_alarm","sfx_pickup","sfx_bomb"]

    private var engine = AVAudioEngine()
    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var sfxBuffers:  [AVAudioPCMBuffer?] = []
    private var bgmPlayer   = AVAudioPlayerNode()
    private var alarmPlayer = AVAudioPlayerNode()
    private var mixerFormat: AVAudioFormat?
    private var bgmCache: [String: AVAudioPCMBuffer] = [:]
    private var currentBgm: String = ""
    private var alarmLooping: Bool = false

    var bgmVolume: Float = 0.5 { didSet { bgmPlayer.volume = muted ? 0 : bgmVolume } }
    var sfxVolume: Float = 0.65
    var muted: Bool = false {
        didSet {
            bgmPlayer.volume = muted ? 0 : bgmVolume
            alarmPlayer.volume = muted ? 0 : sfxVolume
        }
    }

    private let kPrefs = "StrikersAudioPrefs"

    init() {
        loadPrefs()
        setupEngine()
    }

    private func setupEngine() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
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
        for _ in sfxNames {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)
            sfxPlayers.append(node)
        }
        sfxBuffers = sfxNames.map { loadBuffer(named: $0) }
        try? engine.start()
    }

    func playBGM(_ name: String, loop: Bool = true) {
        if currentBgm == name { return }
        currentBgm = name
        bgmPlayer.stop()
        guard let buf = cachedBuffer(named: name) else { return }
        bgmPlayer.volume = muted ? 0 : bgmVolume
        if loop {
            bgmPlayer.scheduleBuffer(buf, at: nil, options: .loops)
        } else {
            bgmPlayer.scheduleBuffer(buf)
        }
        ensureRunning()
        bgmPlayer.play()
    }

    func stopBGM() {
        bgmPlayer.stop()
        currentBgm = ""
    }

    func pauseBGM() { bgmPlayer.pause() }
    func resumeBGM() {
        ensureRunning()
        bgmPlayer.play()
    }

    func playSFX(_ index: Int) {
        guard index >= 0 && index < sfxPlayers.count else { return }
        guard let buf = sfxBuffers[index] else { return }
        let node = sfxPlayers[index]
        node.volume = muted ? 0 : sfxVolume
        node.scheduleBuffer(buf)
        ensureRunning()
        if !node.isPlaying { node.play() }
    }

    func playAlarm() {
        guard let buf = cachedBuffer(named: "sfx_alarm") else { return }
        alarmPlayer.stop()
        alarmPlayer.volume = muted ? 0 : sfxVolume
        alarmPlayer.scheduleBuffer(buf, at: nil, options: .loops)
        ensureRunning()
        alarmPlayer.play()
        alarmLooping = true
    }

    func stopAlarm() {
        alarmPlayer.stop()
        alarmLooping = false
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

    /// Convert file PCM (often mono) to the mixer format (stereo on iOS).
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

    // MARK: Persistence
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

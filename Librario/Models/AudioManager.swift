//
//  AudioManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/8/24.
//

import Observation
import AVFoundation

@Observable class AudioManager {
    var subscriptions = ObservationRegistrar() // Required by ObservationTracking

    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var soundEffectPlayer: AVAudioPlayer?

    init() {
        configureAudioSession()
        observeSettings()
    }

    private func observeSettings() {
        let settings = Settings.shared

        // Observe changes to musicVolume and soundEffectsVolume
        withObservationTracking {
            _ = settings.musicVolume
            _ = settings.soundEffectsVolume
        } onChange: { [weak self] in
            self?.settingsDidChange()
        }
    }

    func settingsDidChange() {
        let settings = Settings.shared
        updateMusicPlayback(volume: settings.musicVolume)
        updateSoundEffectsPlayback(volume: settings.soundEffectsVolume)
    }

    private func configureAudioSession() {
        do {
            // Set the audio session category to allow mixing with other audio
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }

    // Update music playback based on the volume
    private func updateMusicPlayback(volume: Float) {
        if volume > 0 {
            musicPlayer?.volume = volume
            if !(musicPlayer?.isPlaying ?? false) {
                musicPlayer?.play() // Play if it's not already playing
            }
        } else {
            musicPlayer?.pause() // Pause if volume is set to 0
        }
    }

    // Update sound effect playback based on the volume
    private func updateSoundEffectsPlayback(volume: Float) {
        soundEffectPlayer?.volume = volume
        // Sound effects don't have continuous playback like music, so no need to play/pause logic here
        // Just adjust volume for next sound effect that gets played
    }

    func playMusic(named filename: String, loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Could not find music file \(filename).mp3")
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0 // Loop indefinitely if true
            musicPlayer?.volume = Settings.shared.musicVolume // Set initial music volume
            musicPlayer?.prepareToPlay() // Prepare the player
            if Settings.shared.musicVolume > 0 {
                musicPlayer?.play() // Play only if volume is above 0
            }
        } catch {
            print("Failed to play music: \(error.localizedDescription)")
        }
    }

    func playSoundEffect(named filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Could not find sound effect file \(filename).mp3")
            return
        }

        do {
            soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
            soundEffectPlayer?.volume = Settings.shared.soundEffectsVolume // Set initial sound effects volume
            soundEffectPlayer?.play()
        } catch {
            print("Failed to play sound effect: \(error.localizedDescription)")
        }
    }

    // Method to set music volume directly
    func setMusicVolume(to volume: Float) {
        updateMusicPlayback(volume: volume) // Update playback based on volume
    }

    // Method to set sound effects volume directly
    func setSoundEffectsVolume(to volume: Float) {
        updateSoundEffectsPlayback(volume: volume) // Update volume for sound effects
    }
}

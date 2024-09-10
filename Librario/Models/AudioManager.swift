//
//  AudioManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/8/24.
//

import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var soundEffectPlayer: AVAudioPlayer?

    func playMusic(named filename: String, loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Could not find music file \(filename).mp3")
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0 // Loop indefinitely if true
            musicPlayer?.play()
        } catch {
            print("Failed to play music: \(error.localizedDescription)")
        }
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func playSoundEffect(named filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Could not find sound effect file \(filename).mp3")
            return
        }

        do {
            soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
            soundEffectPlayer?.play()
        } catch {
            print("Failed to play sound effect: \(error.localizedDescription)")
        }
    }
}

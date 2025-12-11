//
//  AudioPlayer.swift
//  TimeProgressTracker
//
//  Audio playback helper
//

import AVFoundation
import Foundation

class AudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?
    
    func playSound(named fileName: String, withExtension ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ [AudioPlayer] Could not find audio file: \(fileName).\(ext)")
            return
        }
        
        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            
            print("✅ [AudioPlayer] Playing: \(fileName).\(ext)")
        } catch {
            print("❌ [AudioPlayer] Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
    }
}


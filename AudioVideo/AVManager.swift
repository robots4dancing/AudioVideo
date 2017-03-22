//
//  AVManager.swift
//  AudioVideo
//
//  Created by Thomas Crawford on 3/19/17.
//  Copyright © 2017 VizNetwork. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class AVManager: NSObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    static let sharedInstance = AVManager()
    
    //MARK: - Audio Player Short Sounds Methods
    
    var boingSound :SystemSoundID = 0
    
    func loadBoingSound() {
        let boingURL = Bundle.main.url(forResource: "boing", withExtension: "wav")!
        AudioServicesCreateSystemSoundID(boingURL as CFURL, &boingSound)
    }
    
    func playBoingSound() {
        AudioServicesPlaySystemSound(boingSound)
    }
    
    //MARK: - Audio Player Long Sounds Methods
    
    var longPlayer :AVPlayer?
    
    func loadLaughSound() {
        let laughURL = Bundle.main.url(forResource: "laugh", withExtension: "mp3")!
        longPlayer = AVPlayer(url: laughURL)
        longPlayer?.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: longPlayer?.currentItem)
    }
    
    func playPlayer() {
        guard let player = longPlayer else {
            return
        }
        player.play()

    }
    
    func pausePlayer() {
        guard let player = longPlayer else {
            return
        }
        player.pause()
        
    }
    
    func resetPlayer() {
        guard let player = longPlayer, let item = player.currentItem else {
            return
        }
        item.seek(to: kCMTimeZero)
        
    }
    
    func playerItemDidReachEnd(notification: Notification) {
        print("Player Ended")
        guard  let playerItem = notification.object as? AVPlayerItem, let player = longPlayer, let item = player.currentItem else {
            return
        }
        if playerItem == item {
            item.seek(to: kCMTimeZero)
            player.pause()
        }
    }
    //MARK: - Text-To-Speech
    
    var synthesizer = AVSpeechSynthesizer()
    
    func speakThis(text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string:  text)
        synthesizer.speak(utterance)
    }
    
    //MARK: - Audio Recording Methods
    
    var audioRecorder :AVAudioRecorder!
    var audioPlayer :AVAudioPlayer!
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Audio Session Error")
        }
        
        let tmpPath = NSTemporaryDirectory()
        var url = URL(fileURLWithPath: tmpPath)
        url.appendPathComponent("recording.caf")
        
        let recordingSettings = [
            AVFormatIDKey:NSNumber(value: kAudioFormatAppleIMA4 as UInt32),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 12800,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recordingSettings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch  {
            print("Audio Recording Error")
        }
    }
    
    func stopRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stop()
        }
    }
    
    func playRecording() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioRecorder.url)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 1.0
            audioPlayer.play()
        } catch {
            print("Audio Player Error")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Finished Playing")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Finished Recording")
    }
    
    //MARK: - Life Cycle Methods
    
    override init() {
        super.init()
        loadBoingSound()
        loadLaughSound()
    }


}

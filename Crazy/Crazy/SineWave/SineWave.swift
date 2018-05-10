//
//  SineWave.swift
//  Crazy
//
//  Created by 調 原作 on 2018/05/07.
//  Copyright © 2018年 Monogs. All rights reserved.
//

import AVFoundation

class SineWave {
    let audioEngine = AVAudioEngine()
    //effectNodeの用意
    var delay = AVAudioUnitDelay()
    var reverb = AVAudioUnitReverb()
    let player = AVAudioPlayerNode()
    var cnt: Int = 0
    var timer: Timer?
    
    init(volume: Float = 0.5, hz: Float = 440, delayTime: Double = 1.5, feedback: Float = 0) {
        let audioFormat = player.outputFormat(forBus: 0)
        let sampleRate: Float = 44100.0
        let length = UInt32(sampleRate)
        //delayの設定
        delay.delayTime = delayTime
        delay.feedback = feedback
        
        //reverbの設定
        reverb.loadFactoryPreset(.largeRoom2)
        reverb.wetDryMix = 80
        
        if let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: length) {
            buffer.frameLength = length
            for n in (0 ..< Int(length)) {
                let val = sinf(hz * Float(n) * 2.0 * Float.pi / sampleRate)
                buffer.floatChannelData?.advanced(by: 0).pointee[n] = volume / 5 * val
                buffer.floatChannelData?.advanced(by: 1).pointee[n] = volume / 5 * val
            }
            //engineにdelayとreverbを追加
            audioEngine.attach(delay)
            audioEngine.attach(reverb)
            audioEngine.attach(player)
            
            //audioEngine.connect(player, to: audioEngine.mainMixerNode, format: audioFormat)
            audioEngine.connect(player, to: delay, format: audioFormat)
            audioEngine.connect(delay, to: reverb, format: audioFormat)
            audioEngine.connect(reverb, to: audioEngine.mainMixerNode, format: audioFormat)
            
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            do {
                try audioEngine.start()
            } catch {
                Swift.print(error.localizedDescription)
            }
        }
    }
    
    deinit {
        stopEngine()
    }
    
    func play() {
        if audioEngine.isRunning {
            //Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true, block: { (t) in
                if self.timer == nil || !self.timer!.isValid {
                    //t.invalidate()
                    self.cnt = 0
                    self.player.prepare(withFrameCount: 0)
                    self.player.volume = 1.0
                    self.audioEngine.mainMixerNode.outputVolume = 1.0
                    self.player.play()
                }
           // })
        }
    }
    
    func pause() {
        if player.isPlaying {
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (t) in
                self.cnt += 1
                if self.player.volume > 0 {
                    self.player.volume -= 0.33
                    self.audioEngine.mainMixerNode.outputVolume -= 0.33
                } else if self.cnt > 5 {
                    self.player.volume = 0
                    self.audioEngine.mainMixerNode.outputVolume = 0
                    t.invalidate()
                    self.player.pause()
                }
            })
        }
    }
    
    func stop() {
        if player.isPlaying {
            //timer = Timer.scheduledTimer(withTimeInterval: 0.008, repeats: true, block: { (t) in
                self.cnt += 1
                if self.player.volume > 0 {
                    self.player.volume -= 0.33
                    self.audioEngine.mainMixerNode.outputVolume -= 0.33
                } else if self.cnt > 5 {
                    self.player.volume = 0
                    self.audioEngine.mainMixerNode.outputVolume = 0
                    //t.invalidate()
                    self.player.stop()
                }
            //})
        }
    }
    
    func stopEngine() {
        stop()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    func reset() {
        self.cnt = 0
    }
}

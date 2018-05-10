//
//  ViewController.swift
//  Crazy
//
//  Created by 調 原作 on 2018/04/22.
//  Copyright © 2018年 Monogs. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    private var videoOutput : AVCaptureVideoDataOutput!
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        do {
            var finalFormat: AVCaptureDevice.Format!
            var maxFps: Double = 0
            for vFormat in backCamera.formats
            {
                var ranges      = vFormat.videoSupportedFrameRateRanges as!  [AVFrameRateRange]
                let frameRates  = ranges[0]
                if frameRates.maxFrameRate >= maxFps && frameRates.maxFrameRate <= 60
                {
                    maxFps = frameRates.maxFrameRate
                    finalFormat = vFormat as! AVCaptureDevice.Format
                }
            }
            try backCamera.lockForConfiguration() // ロック開始
            backCamera.activeFormat = finalFormat
            backCamera.activeVideoMinFrameDuration = CMTimeMake(1, 60)
            //backCamera.activeVideoMaxFrameDuration = CMTimeMake(1, 60)
        } catch {
            print("lockForConfiguration error")
        }
        backCamera.unlockForConfiguration() // ロック解除
        
        session.addInput(input)
        return session
    }()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    private lazy var highlightView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 0
        view.backgroundColor = .clear
        return view
    }()
    private lazy var ImageView : UIImageView = {
       let view = UIImageView()
        return view
    }()
    var image : UIImage!
    //vision setting
    private var requestHandler: VNSequenceRequestHandler = VNSequenceRequestHandler()
    private var lastObservation: VNDetectedObjectObservation?
    private var isTouched: Bool = false
    var counter = 0
    var sinewaveR: SineWave!,sinewaveG: SineWave!,sinewaveB: SineWave!,
        sinewave1R: SineWave!,sinewave1G: SineWave!,sinewave1B: SineWave!,
        sinewave2R: SineWave!,sinewave2G: SineWave!,sinewave2B: SineWave!,
        sinewave3R: SineWave!,sinewave3G: SineWave!,sinewave3B: SineWave!,
        sinewave4R: SineWave!,sinewave4G: SineWave!,sinewave4B: SineWave!,
        sinewave5R: SineWave!,sinewave5G: SineWave!,sinewave5B: SineWave!,
        sinewave6R: SineWave!,sinewave6G: SineWave!,sinewave6B: SineWave!,
        sinewave7R: SineWave!,sinewave7G: SineWave!,sinewave7B: SineWave!,
        sinewave8R: SineWave!,sinewave8G: SineWave!,sinewave8B: SineWave!
        /*sinewave9R: SineWave!,sinewave9G: SineWave!,sinewave9B: SineWave!,
        sinewave10R: SineWave!,sinewave10G: SineWave!,sinewave10B: SineWave!,
        sinewave11R: SineWave!,sinewave11G: SineWave!,sinewave11B: SineWave!,
        sinewave12R: SineWave!,sinewave12G: SineWave!,sinewave12B: SineWave!,
        sinewave13R: SineWave!,sinewave13G: SineWave!,sinewave13B: SineWave!,
        sinewave14R: SineWave!,sinewave14G: SineWave!,sinewave14B: SineWave!,
        sinewave15R: SineWave!,sinewave15G: SineWave!,sinewave15B: SineWave!,
        sinewave16R: SineWave!,sinewave16G: SineWave!,sinewave16B: SineWave!,
        sinewave17R: SineWave!,sinewave17G: SineWave!,sinewave17B: SineWave!,
        sinewaveRectR: SineWave!,sinewaveRectG: SineWave!,sinewaveRectB: SineWave!*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Queue"))
        self.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait

        // 遅れてきたフレームは無視する
        videoOutput.alwaysDiscardsLateVideoFrames = true
        captureSession.addOutput(videoOutput)
        captureSession.startRunning()
        self.sineWaveCreateInstance()
        self.sineWavePlay()
        
        print("\(OpenCVWrapper.openCVVersionString())")
        
        //view.layer.addSublayer(previewLayer)
        view.addSubview(self.ImageView)
        view.addSubview(self.highlightView)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sineWaveStopEngine()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.sync(execute: {
            if self.counter > 6000 { self.counter = 0 }
            var interval = 6
            //if self.counter % interval == 0 { // 1/n秒だけ処理する
                //print("読み込み数: \(self.counter)")
                guard
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                    let lastObservation = self.lastObservation
                    else {
                        requestHandler = VNSequenceRequestHandler()
                        return
                }
                if self.isTouched { return }
                let request = VNTrackObjectRequest(detectedObjectObservation: lastObservation, completionHandler: update)
                request.trackingLevel = .accurate
                do {
                    try requestHandler.perform([request], on: pixelBuffer)
                    let ciimage : CIImage = CIImage(cvPixelBuffer: pixelBuffer)
                    image = self.convert(cmage: ciimage)
                    //if self.counter % 60 == 0 {
                        OpenCVWrapper.resetKeyPoints()
                        self.sineWaveReset(); self.sineWaveStop()
                        OpenCVWrapper.keyPoints(image, success: {(success, options) in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0, execute: {
                                if success {
                                    var y:[String] = options?["y"]! as! [String], oY = NSOrderedSet(array: y), uY = oY.array as! [String]; //uY = uY.shuffled()
                                    var x:[String] = options?["x"]! as! [String], oX = NSOrderedSet(array: x), uX = oX.array as! [String]; //uX = uX.shuffled()
                                    var v:[String] = options?["v"]! as! [String], oV = NSOrderedSet(array: v), uV = oV.array as! [String]; //uV = uV.shuffled()
                                    var img:UIImage = options?["image"]! as! UIImage
                                    self.ImageView.image = img
                                    self.ImageView.frame = CGRect(x:0, y:0, width: self.view.frame.width, height: self.view.frame.height)
                                    if uY.count > 0 {
                                        let volume:Float = Float(/*0.4*/Int(uV[0])!/8)
                                        for (i, value) in uY.enumerated() {
                                            guard i >= 0 && i < uX.count else { return }
                                            let pixelColor = self.image.getColor(pos: CGPoint(x:Int(uX[i])!, y:Int(uY[i])!))
                                            let hzValue = Double(pixelColor.red + pixelColor.green + pixelColor.blue)*1.25
                                            var pixelColorR = pixelColor.red*4, pixelColorG = pixelColor.green*2, pixelColorB = pixelColor.blue
                                            //print("x \(Int(uX[i])!) y \(Int(uY[i])!) v \(Int(uV[0])!) delayTime \(Double(Float(uY.count)*Float(uV.count)/50)) feedback \(Float(uY.count)/Float(uV.count)/100) pixelColor \(pixelColor) hzValue \(hzValue)")
                                            switch i {
                                            case 0 :
                                                self.sinewaveR = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewaveR.play()
                                                self.sinewaveG = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewaveG.play()
                                                self.sinewaveB = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewaveB.play()
                                                break
                                            case 1 :
                                                self.sinewave1R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave1R.play()
                                                self.sinewave1G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave1G.play()
                                                self.sinewave1B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave1B.play()
                                                break
                                            case 2 :
                                                self.sinewave2R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave2R.play()
                                                self.sinewave2G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave2G.play()
                                                self.sinewave2B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave2B.play()
                                                break
                                            case 3 :
                                                self.sinewave3R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave3R.play()
                                                self.sinewave3G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave3G.play()
                                                self.sinewave3B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave3B.play()
                                                break
                                            case 4 :
                                                self.sinewave4R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave4R.play()
                                                self.sinewave4G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave4G.play()
                                                self.sinewave4B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave4B.play()
                                                break
                                            case 5 :
                                                self.sinewave5R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave5R.play()
                                                self.sinewave5G = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave5G.play()
                                                self.sinewave5B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave5B.play()
                                                break
                                            case 6 :
                                                self.sinewave6R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave6R.play()
                                                self.sinewave6G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave6G.play()
                                                self.sinewave6B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave6B.play()
                                                break
                                            case 7 :
                                                self.sinewave7R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave7R.play()
                                                self.sinewave7G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave7G.play()
                                                self.sinewave7B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave7B.play()
                                                break
                                            case 8 :
                                                self.sinewave8R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave8R.play()
                                                self.sinewave8G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave8G.play()
                                                self.sinewave8B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave8B.play()
                                                break
                                            /*case 9 :
                                                self.sinewave9R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave9R.play()
                                                self.sinewave9G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave9G.play()
                                                self.sinewave9B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave9B.play()
                                                break
                                            case 10 :
                                                self.sinewave10R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave10R.play()
                                                self.sinewave10G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave10G.play()
                                                self.sinewave10B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave10B.play()
                                                break
                                            case 11 :
                                                self.sinewave11R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave11R.play()
                                                self.sinewave11G = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave11G.play()
                                                self.sinewave11B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave11B.play()
                                                break
                                            case 12 :
                                                self.sinewave12R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave12R.play()
                                                self.sinewave12G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave12G.play()
                                                self.sinewave12B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave12B.play()
                                                break
                                            case 13 :
                                                self.sinewave13R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave13R.play()
                                                self.sinewave13G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave13G.play()
                                                self.sinewave13B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave13B.play()
                                                break
                                            case 14 :
                                                self.sinewave14R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave14R.play()
                                                self.sinewave14G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave14G.play()
                                                self.sinewave14B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave14B.play()
                                                break
                                            case 15 :
                                                self.sinewave15R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave15R.play()
                                                self.sinewave15G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave15G.play()
                                                self.sinewave15B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave15B.play()
                                                break
                                            case 16 :
                                                self.sinewave16R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave16R.play()
                                                self.sinewave16G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave16G.play()
                                                self.sinewave16B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave16B.play()
                                                break
                                            case 17 :
                                                self.sinewave17R = SineWave(volume: volume, hz: Float(pixelColorR), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave17R.play()
                                                self.sinewave17G = SineWave(volume: volume, hz: Float(pixelColorG), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave17G.play()
                                                self.sinewave17B = SineWave(volume: volume, hz: Float(pixelColorB), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave17B.play()
                                                break*/
                                            default:
                                                break
                                            }
                                        }
                                    }
                                }
                            })
                        })
                    //}
                } catch {
                    print("Throws: \(error)")
                }
            //}
            self.counter += 1
        })
    }
    
    // Convert CIImage to CGImagex
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .right)
        return image
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        highlightView.frame = .zero
        lastObservation = nil
        isTouched = true
        //self.sinewaveRect.reset(); self.sinewaveRect.stop()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch: UITouch = touches.first else { return }
        highlightView.frame.size = CGSize(width: 20, height: 20)
        highlightView.center = touch.location(in: view)
        isTouched = false
        var convertedRect = previewLayer.metadataOutputRectConverted(fromLayerRect: highlightView.frame)
        convertedRect.origin.y = 1 - convertedRect.origin.y
        lastObservation = VNDetectedObjectObservation(boundingBox: convertedRect)
        /*if image != nil {
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.0, execute: {
                let pixelColor = self.image.getColor(pos: CGPoint(x:Int(self.highlightView.frame.origin.y), y:Int(self.highlightView.frame.origin.x)))
                let hzValue = (pixelColor.red + pixelColor.green + pixelColor.blue)*1
                print("pixelColor \(pixelColor) hzValue \(hzValue) x \(self.highlightView.frame.origin.y) y \(self.highlightView.frame.origin.x)")
                self.sinewaveRect = SineWave(volume: 0.5, hz: Float(hzValue), delayTime: Double(Float(self.highlightView.frame.width)), feedback: Float(self.highlightView.frame.height))
                self.sinewaveRect.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
                    self.sinewaveRect.reset(); self.sinewaveRect.stop()
                })
            //})
        }*/
        
    }
    
    private func update(_ request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let newObservation = request.results?.first as? VNDetectedObjectObservation else { return }
            self.lastObservation = newObservation
            guard newObservation.confidence >= 0.3 else {
                self.highlightView.frame = .zero
                return
            }
            var transformedRect = newObservation.boundingBox
            transformedRect.origin.y = 1 - transformedRect.origin.y
            let convertedRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: transformedRect)
            self.highlightView.frame = convertedRect
        }
    }
    
    func appOrientation() -> UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }

    // UIInterfaceOrientation -> AVCaptureVideoOrientationにConvert
    func convertUIOrientation2VideoOrientation(f: () -> UIInterfaceOrientation) -> AVCaptureVideoOrientation? {
        let v = f()
        switch v {
        case UIInterfaceOrientation.unknown:
            return nil
        default:
            return ([
                UIInterfaceOrientation.portrait: AVCaptureVideoOrientation.portrait,
                UIInterfaceOrientation.portraitUpsideDown: AVCaptureVideoOrientation.portraitUpsideDown,
                UIInterfaceOrientation.landscapeLeft: AVCaptureVideoOrientation.landscapeLeft,
                UIInterfaceOrientation.landscapeRight: AVCaptureVideoOrientation.landscapeRight
                ])[v]
        }
    }
    
    //画面の回転にも対応したい時は viewWillTransitionToSize で同じく向きを教える。
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(
            alongsideTransition: nil,
            completion: {(UIViewControllerTransitionCoordinatorContext) in
                //画面の回転後に向きを教える。
                if let orientation = self.convertUIOrientation2VideoOrientation(f: {return self.appOrientation()}) {
                    self.previewLayer.connection?.videoOrientation = orientation
                }
            }
        )
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWaveCreateInstance() {
        self.sinewaveR = SineWave(volume: 0.1, hz: Float(800));self.sinewaveG = SineWave(volume: 0.1, hz: Float(800));self.sinewaveB = SineWave(volume: 0.1, hz: Float(800))
        self.sinewave1R = SineWave(volume: 0.1, hz: Float(2400));self.sinewave1G = SineWave(volume: 0.1, hz: Float(2400));self.sinewave1B = SineWave(volume: 0.1, hz: Float(2400))
        self.sinewave2R = SineWave(volume: 0.1, hz: Float(600));self.sinewave2G = SineWave(volume: 0.1, hz: Float(600));self.sinewave2B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave3R = SineWave(volume: 0.1, hz: Float(1600));self.sinewave3G = SineWave(volume: 0.1, hz: Float(1600));self.sinewave3B = SineWave(volume: 0.1, hz: Float(1600))
        self.sinewave4R = SineWave(volume: 0.1, hz: Float(440));self.sinewave4G = SineWave(volume: 0.1, hz: Float(440));self.sinewave4B = SineWave(volume: 0.1, hz: Float(440))
        self.sinewave5R = SineWave(volume: 0.1, hz: Float(140));self.sinewave5G = SineWave(volume: 0.1, hz: Float(140));self.sinewave5B = SineWave(volume: 0.1, hz: Float(140))
        self.sinewave6R = SineWave(volume: 0.1, hz: Float(8400));self.sinewave6G = SineWave(volume: 0.1, hz: Float(8400));self.sinewave6B = SineWave(volume: 0.1, hz: Float(8400))
        self.sinewave7R = SineWave(volume: 0.1, hz: Float(600));self.sinewave7G = SineWave(volume: 0.1, hz: Float(600));self.sinewave7B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave8R = SineWave(volume: 0.1, hz: Float(1200));self.sinewave8G = SineWave(volume: 0.1, hz: Float(600));self.sinewave8B = SineWave(volume: 0.1, hz: Float(600))
        /*self.sinewave9R = SineWave(volume: 0.1, hz: Float(440));self.sinewave9G = SineWave(volume: 0.1, hz: Float(600));self.sinewave9B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave10R = SineWave(volume: 0.1, hz: Float(140));self.sinewave10G = SineWave(volume: 0.1, hz: Float(600));self.sinewave10B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave11R = SineWave(volume: 0.1, hz: Float(12400));self.sinewave11G = SineWave(volume: 0.1, hz: Float(600));self.sinewave11B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave12R = SineWave(volume: 0.1, hz: Float(600));self.sinewave12G = SineWave(volume: 0.1, hz: Float(600));self.sinewave12B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave13R = SineWave(volume: 0.1, hz: Float(1600));self.sinewave13G = SineWave(volume: 0.1, hz: Float(600));self.sinewave13B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave14R = SineWave(volume: 0.1, hz: Float(440));self.sinewave14G = SineWave(volume: 0.1, hz: Float(600));self.sinewave14B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave15R = SineWave(volume: 0.1, hz: Float(140));self.sinewave15G = SineWave(volume: 0.1, hz: Float(600));self.sinewave15B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave16R = SineWave(volume: 0.1, hz: Float(240));self.sinewave16G = SineWave(volume: 0.1, hz: Float(600));self.sinewave16B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave17R = SineWave(volume: 0.1, hz: Float(140));self.sinewave17G = SineWave(volume: 0.1, hz: Float(600));self.sinewave17B = SineWave(volume: 0.1, hz: Float(600))
        self.sinewaveRectR = SineWave(volume: 0.1, hz: Float(240));self.sinewaveRectG = SineWave(volume: 0.1, hz: Float(600));self.sinewaveRectB = SineWave(volume: 0.1, hz: Float(600))*/
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWavePlay() {
        self.sinewaveR.play();self.sinewaveG.play();self.sinewaveB.play()
        self.sinewave1R.play();self.sinewave1G.play();self.sinewave1B.play()
        self.sinewave2R.play();self.sinewave2G.play();self.sinewave2B.play()
        self.sinewave3R.play();self.sinewave3G.play();self.sinewave3B.play()
        self.sinewave4R.play();self.sinewave4G.play();self.sinewave4B.play()
        self.sinewave5R.play();self.sinewave5G.play();self.sinewave5B.play()
        self.sinewave6R.play();self.sinewave6G.play();self.sinewave6B.play()
        self.sinewave7R.play();self.sinewave7G.play();self.sinewave7B.play()
        self.sinewave8R.play();self.sinewave8G.play();self.sinewave8B.play()
        /*self.sinewave9R.play();self.sinewave9G.play();self.sinewave9B.play()
        self.sinewave10R.play();self.sinewave10G.play();self.sinewave10B.play()
        self.sinewave11R.play();self.sinewave11G.play();self.sinewave11B.play()
        self.sinewave12R.play();self.sinewave12G.play();self.sinewave12B.play()
        self.sinewave13R.play();self.sinewave13G.play();self.sinewave13B.play()
        self.sinewave14R.play();self.sinewave14G.play();self.sinewave14B.play()
        self.sinewave15R.play();self.sinewave15G.play();self.sinewave15B.play()
        self.sinewave16R.play();self.sinewave16G.play();self.sinewave16B.play()
        self.sinewave17R.play();self.sinewave17G.play();self.sinewave17B.play()*/
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWaveStopEngine() {
        self.sinewaveR?.stopEngine();self.sinewaveG?.stopEngine();self.sinewaveB?.stopEngine()
        self.sinewave1R?.stopEngine();self.sinewave1G?.stopEngine();self.sinewave1B?.stopEngine()
        self.sinewave2R?.stopEngine();self.sinewave2G?.stopEngine();self.sinewave2B?.stopEngine()
        self.sinewave3R?.stopEngine();self.sinewave3G?.stopEngine();self.sinewave3B?.stopEngine()
        self.sinewave4R?.stopEngine();self.sinewave4G?.stopEngine();self.sinewave4B?.stopEngine()
        self.sinewave5R?.stopEngine();self.sinewave5G?.stopEngine();self.sinewave5B?.stopEngine()
        self.sinewave6R?.stopEngine();self.sinewave6G?.stopEngine();self.sinewave6B?.stopEngine()
        self.sinewave7R?.stopEngine();self.sinewave7G?.stopEngine();self.sinewave7B?.stopEngine()
        self.sinewave8R?.stopEngine();self.sinewave8G?.stopEngine();self.sinewave8B?.stopEngine()
        /*self.sinewave9R?.stopEngine();self.sinewave9G?.stopEngine();self.sinewave9B?.stopEngine()
        self.sinewave10R?.stopEngine();self.sinewave10G?.stopEngine();self.sinewave10B?.stopEngine()
        self.sinewave11R?.stopEngine();self.sinewave11G?.stopEngine();self.sinewave11B?.stopEngine()
        self.sinewave12R?.stopEngine();self.sinewave12G?.stopEngine();self.sinewave12B?.stopEngine()
        self.sinewave13R?.stopEngine();self.sinewave13G?.stopEngine();self.sinewave13B?.stopEngine()
        self.sinewave14R?.stopEngine();self.sinewave14G?.stopEngine();self.sinewave14B?.stopEngine()
        self.sinewave15R?.stopEngine();self.sinewave15G?.stopEngine();self.sinewave15B?.stopEngine()
        self.sinewave16R?.stopEngine();self.sinewave16G?.stopEngine();self.sinewave16B?.stopEngine()
        self.sinewave17R?.stopEngine();self.sinewave17G?.stopEngine();self.sinewave17B?.stopEngine()*/
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWaveReset() {
        self.sinewaveR.reset();self.sinewaveG.reset();self.sinewaveB.reset()
        self.sinewave1R.reset();self.sinewave1G.reset();self.sinewave1B.reset()
        self.sinewave2R.reset();self.sinewave2G.reset();self.sinewave2B.reset()
        self.sinewave3R.reset();self.sinewave3G.reset();self.sinewave3B.reset()
        self.sinewave4R.reset();self.sinewave4G.reset();self.sinewave4B.reset()
        self.sinewave5R.reset();self.sinewave5G.reset();self.sinewave5B.reset()
        self.sinewave6R.reset();self.sinewave6G.reset();self.sinewave6B.reset()
        self.sinewave7R.reset();self.sinewave7G.reset();self.sinewave7B.reset()
        self.sinewave8R.reset();self.sinewave8G.reset();self.sinewave8B.reset()
        /*self.sinewave9R.reset();self.sinewave9G.reset();self.sinewave9B.reset()
        self.sinewave10R.reset();self.sinewave10G.reset();self.sinewave10B.reset()
        self.sinewave11R.reset();self.sinewave11G.reset();self.sinewave11B.reset()
        self.sinewave12R.reset();self.sinewave12G.reset();self.sinewave12B.reset()
        self.sinewave13R.reset();self.sinewave13G.reset();self.sinewave13B.reset()
        self.sinewave14R.reset();self.sinewave14G.reset();self.sinewave14B.reset()
        self.sinewave15R.reset();self.sinewave15G.reset();self.sinewave15B.reset()
        self.sinewave16R.reset();self.sinewave16G.reset();self.sinewave16B.reset()
        self.sinewave17R.reset();self.sinewave17G.reset();self.sinewave17B.reset()*/
    }
    
    func sineWaveStop() {
        self.sinewaveR.stop();self.sinewaveG.stop();self.sinewaveB.stop()
        self.sinewave1R.stop();self.sinewave1G.stop();self.sinewave1B.stop()
        self.sinewave2R.stop();self.sinewave2G.stop();self.sinewave2B.stop()
        self.sinewave3R.stop();self.sinewave3G.stop();self.sinewave3B.stop()
        self.sinewave4R.stop();self.sinewave4G.stop();self.sinewave4B.stop()
        self.sinewave5R.stop();self.sinewave5G.stop();self.sinewave5B.stop()
        self.sinewave6R.stop();self.sinewave6G.stop();self.sinewave6B.stop()
        self.sinewave7R.stop();self.sinewave7G.stop();self.sinewave7B.stop()
        self.sinewave8R.stop();self.sinewave8G.stop();self.sinewave8B.stop()
        /*self.sinewave9R.stop();self.sinewave9G.stop();self.sinewave9B.stop()
        self.sinewave10R.stop();self.sinewave10G.stop();self.sinewave10B.stop()
        self.sinewave11R.stop();self.sinewave11G.stop();self.sinewave11B.stop()
        self.sinewave12R.stop();self.sinewave12G.stop();self.sinewave12B.stop()
        self.sinewave13R.stop();self.sinewave13G.stop();self.sinewave13B.stop()
        self.sinewave14R.stop();self.sinewave14G.stop();self.sinewave14B.stop()
        self.sinewave15R.stop();self.sinewave15G.stop();self.sinewave15B.stop()
        self.sinewave16R.stop();self.sinewave16G.stop();self.sinewave16B.stop()
        self.sinewave17R.stop();self.sinewave17G.stop();self.sinewave17B.stop()*/
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension Array {
    
    func shuffled() -> [Element] {
        var results = [Element]()
        var indexes = (0 ..< count).map { $0 }
        while indexes.count > 0 {
            let indexOfIndexes = Int(arc4random_uniform(UInt32(indexes.count)))
            let index = indexes[indexOfIndexes]
            results.append(self[index])
            indexes.remove(at: indexOfIndexes)
        }
        return results
    }
    
}

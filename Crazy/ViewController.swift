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
    var sinewave: SineWave!,sinewave1: SineWave!,sinewave2: SineWave!, sinewave3: SineWave!,sinewave4: SineWave!,sinewave5: SineWave!,
        sinewave6: SineWave!,sinewave7: SineWave!,sinewave8: SineWave!, sinewave9: SineWave!,sinewave10: SineWave!,sinewave11: SineWave!,
        sinewave12: SineWave!,sinewave13: SineWave!,sinewave14: SineWave!, sinewave15: SineWave!,sinewave16: SineWave!,sinewave17: SineWave!,
        sinewaveRect: SineWave!
    
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
                                            //print("x \(Int(uX[i])!) y \(Int(uY[i])!) v \(Int(uV[0])!) delayTime \(Double(Float(uY.count)*Float(uV.count)/50)) feedback \(Float(uY.count)/Float(uV.count)/100) pixelColor \(pixelColor) hzValue \(hzValue)")
                                            switch i {
                                            case 0 :
                                                self.sinewave = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave.play()
                                                break
                                            case 1 :
                                                self.sinewave1 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave1.play()
                                                break
                                            case 2 :
                                                self.sinewave2 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave2.play()
                                                break
                                            case 3 :
                                                self.sinewave3 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave3.play()
                                                break
                                            case 4 :
                                                self.sinewave4 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave4.play()
                                                break
                                            case 5 :
                                                self.sinewave5 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave5.play()
                                                break
                                            case 6 :
                                                self.sinewave6 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave6.play()
                                                break
                                            case 7 :
                                                self.sinewave7 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave7.play()
                                                break
                                            case 8 :
                                                self.sinewave8 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave8.play()
                                                break
                                            case 9 :
                                                self.sinewave9 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave9.play()
                                                break
                                            case 10 :
                                                self.sinewave10 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave10.play()
                                                break
                                            case 11 :
                                                self.sinewave11 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave11.play()
                                                break
                                            case 12 :
                                                self.sinewave12 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave12.play()
                                                break
                                            case 13 :
                                                self.sinewave13 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave13.play()
                                                break
                                            case 14 :
                                                self.sinewave14 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave14.play()
                                                break
                                            case 15 :
                                                self.sinewave15 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave15.play()
                                                break
                                            case 16 :
                                                self.sinewave16 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave16.play()
                                                break
                                            case 17 :
                                                self.sinewave17 = SineWave(volume: volume, hz: Float(hzValue), delayTime: Double(Float(uY.count)*Float(uV.count)/50), feedback: Float(uY.count)/Float(uV.count)/100,frequency: [pixelColor.blue, pixelColor.green*5, pixelColor.red*30])
                                                self.sinewave17.play()
                                                break
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
        self.sinewave = SineWave(volume: 0.1, hz: Float(800)); self.sinewave1 = SineWave(volume: 0.1, hz: Float(2400))
        self.sinewave2 = SineWave(volume: 0.1, hz: Float(600));self.sinewave3 = SineWave(volume: 0.1, hz: Float(1600))
        self.sinewave4 = SineWave(volume: 0.1, hz: Float(440));self.sinewave5 = SineWave(volume: 0.1, hz: Float(140))
        self.sinewave6 = SineWave(volume: 0.1, hz: Float(8400));self.sinewave7 = SineWave(volume: 0.1, hz: Float(600))
        self.sinewave8 = SineWave(volume: 0.1, hz: Float(1200));self.sinewave9 = SineWave(volume: 0.1, hz: Float(440))
        self.sinewave10 = SineWave(volume: 0.1, hz: Float(140));self.sinewave11 = SineWave(volume: 0.1, hz: Float(12400))
        self.sinewave12 = SineWave(volume: 0.1, hz: Float(600));self.sinewave13 = SineWave(volume: 0.1, hz: Float(1600))
        self.sinewave14 = SineWave(volume: 0.1, hz: Float(440));self.sinewave15 = SineWave(volume: 0.1, hz: Float(140))
        self.sinewave16 = SineWave(volume: 0.1, hz: Float(240));self.sinewave17 = SineWave(volume: 0.1, hz: Float(140))
        self.sinewaveRect = SineWave(volume: 0.1, hz: Float(240))
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWavePlay() {
        self.sinewave.play();self.sinewave1.play();self.sinewave2.play()
        self.sinewave3.play();self.sinewave4.play();self.sinewave5.play()
        self.sinewave6.play();self.sinewave7.play();self.sinewave8.play()
        self.sinewave9.play();self.sinewave10.play();self.sinewave11.play()
        self.sinewave12.play();self.sinewave13.play();self.sinewave14.play()
        self.sinewave15.play();self.sinewave16.play();self.sinewave17.play()
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWaveStopEngine() {
        sinewave?.stopEngine();sinewave1?.stopEngine();sinewave2?.stopEngine()
        sinewave3?.stopEngine();sinewave4?.stopEngine();sinewave5?.stopEngine()
        sinewave6?.stopEngine();sinewave7?.stopEngine();sinewave8?.stopEngine()
        sinewave9?.stopEngine();sinewave10?.stopEngine();sinewave11?.stopEngine()
        sinewave12?.stopEngine();sinewave13?.stopEngine();sinewave14?.stopEngine()
        sinewave15?.stopEngine();sinewave16?.stopEngine();sinewave17?.stopEngine()
    }
    
    //Viewが消える前にaudioEngineを止める（重要）
    func sineWaveReset() {
        self.sinewave.reset(); self.sinewave1.reset(); self.sinewave2.reset()
        self.sinewave3.reset(); self.sinewave4.reset(); self.sinewave5.reset()
        self.sinewave6.reset(); self.sinewave7.reset(); self.sinewave8.reset()
        self.sinewave9.reset(); self.sinewave10.reset(); self.sinewave11.reset()
        self.sinewave12.reset(); self.sinewave13.reset(); self.sinewave14.reset()
        self.sinewave15.reset(); self.sinewave16.reset(); self.sinewave17.reset()
    }
    
    func sineWaveStop() {
        self.sinewave.stop();self.sinewave1.stop();self.sinewave2.stop()
        self.sinewave3.stop();self.sinewave4.stop();self.sinewave5.stop()
        self.sinewave6.stop();self.sinewave7.stop();self.sinewave8.stop()
        self.sinewave9.stop();self.sinewave10.stop();self.sinewave11.stop()
        self.sinewave12.stop();self.sinewave13.stop();self.sinewave14.stop()
        self.sinewave15.stop();self.sinewave16.stop();self.sinewave17.stop()
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

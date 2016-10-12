//
//  ViewController.swift
//  replayKitDemo
//
//  Created by Stanley Chiang on 10/12/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit
import AVFoundation
import ReplayKit
import SpriteKit

class ViewController: UIViewController, RPPreviewViewControllerDelegate, UIKitDelegate {
    
    var cameraView: UIView = UIView(frame: UIScreen.mainScreen().bounds)
    var scene:GameScene!
    var manager:GameManager!
    var managerView:UIView!
    
    var captureDevice: AVCaptureDevice?
    var videoLayer = AVCaptureVideoPreviewLayer()
    
    var songPlayer: AVAudioPlayer?
    var songPath: NSURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("dontstopbelievinjourney", ofType: "mp3")!)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupGameLayer()
        setupGameManager()
        scene.sceneDelegate = manager
        manager.managerDelegate = scene
        manager.uikitDelegate = self
        
        
        startRecording()
        startLiveVideo()
    }

    func setupGameLayer() {
        
        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        
        self.view.addSubview(skView as UIView)
        
        //        skView.showsFPS = true
        //        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene = GameScene(size: self.view.frame.size)
        scene.scaleMode = .AspectFill
        scene.backgroundColor = UIColor.clearColor()
        skView.presentScene(scene)
    }
    
    func setupGameManager(){
        
        managerView = UIView(frame: self.view.frame)
//        managerView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
//        managerView.transform = CGAffineTransformScale(managerView.transform, 1, -1)
        
        self.view.addSubview(managerView)
        
        let skView = SKView(frame: view.frame)
        skView.allowsTransparency = true
        
        managerView.addSubview(skView as UIView)
        skView.ignoresSiblingOrder = true
        
        manager = GameManager(size: self.view.frame.size)
        manager.scaleMode = .AspectFill
        manager.backgroundColor = UIColor.clearColor()
        skView.presentScene(manager)
    }
 
    func startRecording() {
        
        let recorder = RPScreenRecorder.sharedRecorder()
        
        recorder.startRecordingWithMicrophoneEnabled(true) {(error) in
            if let unwrappedError = error {
                print(unwrappedError.localizedDescription)
            } else {
                print("called")
                self.prepareAudioToPlay()
            }
        }
    }
    
    func prepareAudioToPlay(){
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)){
            do{
                try self.songPlayer = AVAudioPlayer(contentsOfURL:self.songPath)
            } catch {
                print("Woops")
            }
            self.songPlayer!.prepareToPlay()
            self.songPlayer!.settings
            
            self.songPlayer!.play()
        }
    }
    
    func stopRecording() {
        
        let recorder = RPScreenRecorder.sharedRecorder()
        
        recorder.stopRecordingWithHandler { [unowned self] (preview, error) in
            if let previewView = preview {
                previewView.previewControllerDelegate = self
                self.presentViewController(previewView, animated: true, completion: nil)
            }
        }
    }
    
    func startLiveVideo(){
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                
                let captureSession = AVCaptureSession()
                captureSession.sessionPreset = AVCaptureSessionPresetiFrame960x540
                
                let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
                let deviceAudio = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
                
                for device in devices {
                    if(device.position == AVCaptureDevicePosition.Front){
                        self.captureDevice = device as? AVCaptureDevice
                    }
                }
                
                do {
                    let input = try AVCaptureDeviceInput(device: self.captureDevice)
                    captureSession.addInput(input)
                    
                } catch {
                    print("woops no Video")
                }
                
                do {
                    let input = try AVCaptureDeviceInput(device: deviceAudio)
                    captureSession.addInput(input)
                } catch {
                    print("woops no Audio")
                }
                
                captureSession.startRunning()
                
                self.videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                
                dispatch_async(dispatch_get_main_queue()){ [unowned self] in
                    self.videoLayer.frame = self.view.bounds
                    self.cameraView.clipsToBounds = true
                    self.cameraView.layer.addSublayer(self.videoLayer)
                    self.view.addSubview(self.cameraView)
                    self.view.sendSubviewToBack(self.cameraView)
                }
            }
        }
    }

    func loadPostGameModal() {
        stopRecording()
    }
}

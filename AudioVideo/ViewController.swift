//
//  ViewController.swift
//  AudioVideo
//
//  Created by Thomas Crawford on 3/19/17.
//  Copyright © 2017 VizNetwork. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, CameraManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let avMgr = AVManager.sharedInstance
    
    //MARK: - Short AudioPlayer Methods
    
    @IBAction func play1Pressed(button: UIButton) {
        avMgr.playBoingSound()
    }
    
    //MARK: - Long AudioPlayer Methods
    
    @IBOutlet var playPauseButton :UIButton!
    
    @IBAction func playPause2Pressed(button: UIButton) {
        if playPauseButton.titleLabel!.text == "Play 2" {
            playPauseButton.setTitle("Pause 2", for: .normal)
            avMgr.playPlayer()
        } else {
            playPauseButton.setTitle("Play 2", for: .normal)
            avMgr.pausePlayer()
        }
    }
    
    @IBAction func reset2Pressed(button: UIButton) {
        avMgr.resetPlayer()
    }
    
    //MARK: - Text-To-Speech Methods
    
    @IBOutlet var speakThisTextView :UITextView!
    
    @IBAction func speakThisPressed(button: UIButton) {
        guard let text = speakThisTextView.text else {
            return
        }
        speakThisTextView.resignFirstResponder()
        avMgr.speakThis(text: text)
    }
    
    //MARK: - Audio Recording Methods
    
    @IBAction func startRecording(button: UIButton) {
        avMgr.startRecording()
    }
    
    @IBAction func stopRecording(button: UIButton) {
        avMgr.stopRecording()
    }
    
    @IBAction func playRecording(button: UIButton) {
        avMgr.playRecording()
    }
    
    //MARK: - Video Player Methods
    
    @IBOutlet var videoView            :UIView!
    @IBOutlet var videoPlayPauseButton :UIButton!
    @IBOutlet var videoProgressView    :UIProgressView!
    var videoPlayer :AVPlayer!
    var playerLayer :AVPlayerLayer!

    @IBAction func playPauseVideoPressed(button: UIButton) {
        if videoPlayPauseButton.titleLabel!.text == "Play" {
            videoPlayPauseButton.setTitle("Pause", for: .normal)
            videoPlayer.play()

        } else {
            videoPlayPauseButton.setTitle("Play", for: .normal)
            videoPlayer.pause()
        }
    }
    
    func playerDidReachEnd() {
        videoPlayer.rate = 0
        print("Video Ended")
    }
    
    func setupVideoPlayer() {
        let url = Bundle.main.url(forResource: "bearhead", withExtension: "mov")!
        videoPlayer = AVPlayer(url: url)
        videoPlayer.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { (notification) in
            self.playerDidReachEnd()
        }
        videoPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 20), queue: DispatchQueue.main) { (time) in
            let currentPlayerItem = self.videoPlayer.currentItem
            let duration = CMTimeGetSeconds((currentPlayerItem?.asset.duration)!)
            let currentTime = CMTimeGetSeconds(self.videoPlayer.currentTime())
            let percentComplete = Float(currentTime) / Float(duration)
            self.videoProgressView.progress = percentComplete
        }
    }
    
    func setupVideoView() {
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        videoView.layer.insertSublayer(playerLayer, at: 0)
    }
    
    //MARK: - Save File Methods
    
    @IBOutlet private weak var capturedImage :UIImageView!
    
    @IBAction func savePressed(button: UIButton) {
        if let image = capturedImage.image {
            cameraMgr.save(image: image)
        } else {
            print("No Image")
        }
    }
    
    //MARK: - Built-In Camera Methods
    
    @IBAction func galleryPressed(button: UIButton) {
        print("Gallery")
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func builtinCameraPressed(button :UIButton) {
        print("Camera")
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            print("No Camera")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        capturedImage.image = (info[UIImagePickerControllerOriginalImage] as! UIImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Custom Camera Methods
    
    @IBOutlet var previewView: UIView!
    
    let cameraMgr = CameraManager()
    
    func camera(didSet previewLayer: AVCaptureVideoPreviewLayer) {
        previewView.layer.addSublayer(previewLayer)
    }
    
    func cameraBoundsForPreviewView() -> CGRect {
        return previewView.bounds
    }
    
    @IBAction func takePhotoPressed(button: UIButton) {
        cameraMgr.takePhoto()
    }
    
    func camera(didCapture image: UIImage) {
        capturedImage.image = image
    }
    
    //MARK: - Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayer()
        cameraMgr.delegate = self
        cameraMgr.checkForCameraAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupVideoView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}


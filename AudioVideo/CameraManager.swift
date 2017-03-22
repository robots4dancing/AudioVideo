//
//  CameraManager.swift
//
//  Copyright © 2017 Tom Crawford. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraManagerDelegate: class {
    func camera(didCapture image: UIImage)
    func camera(didSet previewLayer: AVCaptureVideoPreviewLayer)
    func cameraBoundsForPreviewView() -> CGRect
    func cameraDidCompleteLocalSave(filename: String)
    func cameraDidFailSetup(message: String)
    func cameraDidFailImageProcessing(message: String)
    func cameraDidFailAuthorization(message: String)
    func cameraDidFailLocalSave(message: String)
}

extension CameraManagerDelegate {
    func cameraDidCompleteLocalSave(filename: String) {
    }
    func cameraDidFailSetup(message: String) {
    }
    func cameraDidFailImageProcessing(message: String) {
    }
    func cameraDidFailAuthorization(message: String) {
    }
    func cameraDidFailLocalSave(message: String) {
    }
}

class CameraManager: NSObject, AVCapturePhotoCaptureDelegate {
    static let sharedInstance = CameraManager()
    
    weak var delegate: CameraManagerDelegate?
    
    private var captureSession :AVCaptureSession!
    private var cameraOutput   :AVCapturePhotoOutput!
    private var previewLayer   :AVCaptureVideoPreviewLayer!
    
    private var shouldSaveToDocuments = false
    
    //MARK: - Manual Camera Methods
    
    private func startupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        cameraOutput = AVCapturePhotoOutput()
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        if let input = try? AVCaptureDeviceInput(device: device) {
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                if captureSession.canAddOutput(cameraOutput) {
                    captureSession.addOutput(cameraOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    if let bounds = delegate?.cameraBoundsForPreviewView() {
                        previewLayer.frame = bounds
                    }
                    delegate?.camera(didSet: previewLayer)
                    captureSession.startRunning()
                } else {
                    delegate?.cameraDidFailSetup(message: "Error: Error adding output to camera")
                }
            } else {
                delegate?.cameraDidFailSetup(message: "Error: Error adding input to camera")
            }
        } else {
            delegate?.cameraDidFailSetup(message: "Error: Error creating camera")
        }
    }
    
    public func takePhoto(saveToDocs: Bool = false) {
        shouldSaveToDocuments = saveToDocs
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 300,
            kCVPixelBufferHeightKey as String: 400
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    internal func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            delegate?.cameraDidFailImageProcessing(message: "Error: Image Processing \(error.localizedDescription)")
            return
        }
        
        if  let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            delegate?.camera(didCapture: image)
            
            if shouldSaveToDocuments {
                let filename = getNewImageFilename()
                save(image: image, filename: filename)
            }
        } else {
            delegate?.cameraDidFailImageProcessing(message: "Error: Image Processing Buffers")
        }
    }
    
    //MARK: - Camera Authorization Methods
    
    private func askForCameraAccess() {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (success) in
            if success {
                self.startupCamera()
            } else {
                print("User Didn't Give Access")
            }
        }
    }
    
    public func checkForCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            print("Startup Camera")
            startupCamera()
        case .denied, .restricted:
            print("User Didn't Give Access")
        case .notDetermined:
            askForCameraAccess()
        }
    }
    
    //MARK: - File Management Methods

    private func getNewImageFilename() -> String {
        return ProcessInfo.processInfo.globallyUniqueString + ".png"
    }
    
    private func getDocumentPathForFile(filename: String) -> URL {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let docURL = URL(fileURLWithPath: docPath)
        return docURL.appendingPathComponent(filename)
    }
    
    private func delete(localFileURL: URL) {
        let fileMgr = FileManager()
        try? fileMgr.removeItem(at: localFileURL)
    }
    
    public func save(image: UIImage) {
        save(image: image, filename: getNewImageFilename())
    }
    
    private func save(image: UIImage, filename: String) {
        do {
            let localPath = getDocumentPathForFile(filename: filename)
            guard let png = UIImagePNGRepresentation(image) else {
                print("Error: Failed to create PNG")
                return
            }
            try png.write(to: localPath)
            print("Saved: \(filename)")
        } catch let error {
            print("Error: Saving local failed \(error.localizedDescription)")
        }
        
    }
        
}

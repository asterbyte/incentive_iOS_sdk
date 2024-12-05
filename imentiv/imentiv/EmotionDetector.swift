//
//  EmotionDetector.swift
//  imentiv
//
//  Created by aster on 05/12/24.
//

import UIKit
import AVFoundation
import Vision


public enum CameraPosition {
    case front
    case back

    var avCapturePosition: AVCaptureDevice.Position {
        switch self {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

public class EmotionDetector: NSObject {
    private let captureSession = AVCaptureSession()
    private var emotionCallback: ((String) -> Void)?
    private var emotionArrayCallback: ((MLMultiArray?) -> Void)?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let model = try! RepVGG_A0_EmotionDetector()
    private var isProcessing = false

    public override init() {
        super.init()
        setupAudioSessionForBackground()
    }

    /// Configures the camera and starts the feed
    
    public func startCamera(cameraPosition: CameraPosition = .front)
    {
        setupCamera(cameraPosition: cameraPosition)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    public func getEmotionDetected(emotionDetected: @escaping (String) -> Void) {
        self.emotionCallback = emotionDetected
    }
    
    public func detectedEmotionArray(values: @escaping (MLMultiArray?) -> Void) {
        emotionArrayCallback = values
       }

    /// Stops the camera feed
    public func stopCamera() {
        captureSession.stopRunning()
    }

    // MARK: - Background Support
    
    private func setupAudioSessionForBackground() {
        // Configure audio session to keep the app active in the background
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, options: [.mixWithOthers, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session for background mode: \(error.localizedDescription)")
        }
    }

    // MARK: - Camera Setup

    private func setupCamera(cameraPosition: CameraPosition) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: cameraPosition.avCapturePosition)

        guard let device = deviceDiscoverySession.devices.first,
              let deviceInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(deviceInput) else {
            print("Failed to configure camera.")
            return
        }

        captureSession.addInput(deviceInput)

        // Configure video output
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        captureSession.addOutput(videoDataOutput)
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }

    // MARK: - Face Detection and Emotion Recognition

    private func detectFaces(in image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            print("Invalid CIImage")
            isProcessing = false
            return
        }

        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation], let face = results.first else {
                print("No faces detected.")
                self?.isProcessing = false // Reset here if no face is found
                return
            }
            self?.processFace(in: image, with: face)
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Face detection failed: \(error.localizedDescription)")
            isProcessing = false // Reset here in case of an error
        }
    }

    private func processFace(in image: UIImage, with faceObservation: VNFaceObservation) {
        let imageSize = image.size
        let boundingBox = faceObservation.boundingBox
        let convertedBoundingBox = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )

        guard let croppedCGImage = image.cgImage?.cropping(to: convertedBoundingBox) else {
            print("Failed to crop face")
            isProcessing = false // Reset here if cropping fails
            return
        }

        let croppedImage = UIImage(cgImage: croppedCGImage)
        performEmotionClassification(on: croppedImage)
    }

    private func performEmotionClassification(on image: UIImage) {
        guard let pixelBuffer = image.pixelBuffer(width: 224, height: 224) else {
            print("Failed to create pixel buffer.")
            isProcessing = false // Reset here if pixel buffer creation fails
            return
        }

        do {
            let input = RepVGG_A0_EmotionDetectorInput(x: pixelBuffer)
            let output = try model.prediction(input: input)
            let emotionLabels = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]
            let emotionIndex = argmax(array: output.var_455)
            let emotion = emotionLabels[emotionIndex]

            DispatchQueue.main.async {
                self.emotionCallback?(emotion)
                self.emotionArrayCallback?(output.var_455)
            }
        } catch {
            print("Prediction error: \(error.localizedDescription)")
        }

        isProcessing = false // Always reset after prediction
    }

    private func argmax(array: MLMultiArray) -> Int {
        let floatArray = UnsafeBufferPointer(start: array.dataPointer.bindMemory(to: Float.self, capacity: array.count), count: array.count)
        return floatArray.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }
}

extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary

        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &pixelBuffer) == kCVReturnSuccess,
              let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let ciImage = CIImage(image: self)!
        CIContext().render(ciImage, to: buffer)
        return buffer
    }
}

extension EmotionDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isProcessing, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        isProcessing = true

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            detectFaces(in: uiImage)
        } else {
            isProcessing = false // Reset here if creating a CGImage fails
        }
    }
}
 
 

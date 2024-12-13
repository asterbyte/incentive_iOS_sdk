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
    private var emptyFaceCount : Int = 0
    private var temporaryEmotionArray: [[Float32]] = []
    
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

    private func convertMLMultiArrayToFloat32Array(_ multiArray: MLMultiArray) -> [Float32] {
            let pointer = multiArray.dataPointer.bindMemory(to: Float32.self, capacity: multiArray.count)
            return Array(UnsafeBufferPointer(start: pointer, count: multiArray.count))
        }


    
    /// Configures the camera and starts the feed
    
    public func startEmotionsCapture(cameraPosition: CameraPosition = .front)
    {
        emptyFaceCount = 0
        temporaryEmotionArray.removeAll()
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
   /* public func stopCamera() {
        captureSession.stopRunning()
       // print("Temporart \(temporaryEmotionArray)")
        let emotions = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]

        // Calculate the aggregate for each emotion
        var aggregates = Array(repeating: 0.0, count: emotions.count)
                for row in temporaryEmotionArray {
                    for (index, value) in row.enumerated() {
                        aggregates[index] += Double(value)
                    }
                }

                // Print the aggregated results
                for (index, emotion) in emotions.enumerated() {
                    print("\(emotion): \(String(format: "%.4f", aggregates[index]))")
                }
        
        if let maxIndex = aggregates.enumerated().max(by: { $0.element < $1.element })?.offset {
               let dominantEmotion = emotions[maxIndex]
               print("Dominant Emotion: \(dominantEmotion)")
           }
        
    }*/
    
    // Selected Code
   
    /*public func stopCamera(onEmotionsProcessed: (([String: Double], String) -> Void)? = nil) {
        // Stop the capture session
        captureSession.stopRunning()

        // Define the emotions array
        let emotions = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]

        // Initialize a dictionary to store aggregates for each emotion
        var emotionAggregates = [String: Double]()
        emotions.forEach { emotionAggregates[$0] = 0.0 }

        // Calculate the aggregate for each emotion
        for row in temporaryEmotionArray {
            for (index, value) in row.enumerated() {
                if index < emotions.count {
                    emotionAggregates[emotions[index], default: 0.0] += Double(value)
                }
            }
        }

        // Determine the dominant emotion
        let dominantEmotion = emotionAggregates.max(by: { $0.value < $1.value })?.key ?? "Unknown"

        // Invoke the callback with the results
        onEmotionsProcessed?(emotionAggregates, dominantEmotion)
    }
     */
    
    
    /*
     
    0 to 10
     
    public func stopEmotionsCapture(onEmotionsProcessed: (([String: Double], String) -> Void)? = nil) {
        // Stop the capture session
        captureSession.stopRunning()

        // Define the emotions array
        let emotions = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]

        // Initialize a dictionary to store aggregates for each emotion
        var emotionAggregates = [String: Double]()
        emotions.forEach { emotionAggregates[$0] = 0.0 }

        // Calculate the aggregate for each emotion
        for row in temporaryEmotionArray {
            for (index, value) in row.enumerated() {
                if index < emotions.count {
                    // Scale the value to be between 0.0 and 10.0
                    let scaledValue = min(max(Double(value), 0.0), 10.0) // Ensure value stays within bounds
                    emotionAggregates[emotions[index], default: 0.0] += scaledValue
                }
            }
        }

        // Optionally, you can normalize the values so that the sum doesn't exceed 10.0
        let total = emotionAggregates.values.reduce(0.0, +)
        if total > 0 {
            emotions.forEach { emotion in
                emotionAggregates[emotion] = (emotionAggregates[emotion]! / total) * 10.0
            }
        }

        // Determine the dominant emotion
        let dominantEmotion = emotionAggregates.max(by: { $0.value < $1.value })?.key ?? "Unknown"

        // Invoke the callback with the results
        onEmotionsProcessed?(emotionAggregates, dominantEmotion)
    }*/

    
    public func stopEmotionsCapture(onEmotionsProcessed: (([String: Double], String) -> Void)? = nil) {
        // Stop the capture session
        captureSession.stopRunning()
        
        print("Total Empty Face count\(emptyFaceCount)")

        // Define the emotions array
        let emotions = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]

        // Initialize a dictionary to store aggregates for each emotion
        var emotionAggregates = [String: Double]()
        emotions.forEach { emotionAggregates[$0] = 0.0 }

        // Calculate the aggregate for each emotion
        for row in temporaryEmotionArray {
            for (index, value) in row.enumerated() {
                if index < emotions.count {
                    // Scale the value to be between 0.0 and 1.0 (originally between 0.0 and 10.0)
                    let scaledValue = min(max(Double(value), 0.0), 10.0) / 10.0 // Scale between 0.0 and 1.0
                    emotionAggregates[emotions[index], default: 0.0] += scaledValue
                }
            }
        }

        // Normalize the values so that the sum doesn't exceed 1.0
        let total = emotionAggregates.values.reduce(0.0, +)
        if total > 0 {
            emotions.forEach { emotion in
                emotionAggregates[emotion] = emotionAggregates[emotion]! / total
            }
        }

        // Determine the dominant emotion
        let dominantEmotion = emotionAggregates.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        

        // Invoke the callback with the results
        onEmotionsProcessed?(emotionAggregates, dominantEmotion)
    }
    
    public func stopEmotionsCapture(onEmotionsProcessed: (([String: Double], String, _ totalFrames: Int) -> Void)? = nil) {
        // Stop the capture session
        captureSession.stopRunning()
        
        print("Total Empty Face count\(emptyFaceCount)")

        // Define the emotions array
        let emotions = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]

        // Initialize a dictionary to store aggregates for each emotion
        var emotionAggregates = [String: Double]()
        emotions.forEach { emotionAggregates[$0] = 0.0 }

        // Calculate the aggregate for each emotion
        for row in temporaryEmotionArray {
            for (index, value) in row.enumerated() {
                if index < emotions.count {
                    // Scale the value to be between 0.0 and 1.0 (originally between 0.0 and 10.0)
                    let scaledValue = min(max(Double(value), 0.0), 10.0) / 10.0 // Scale between 0.0 and 1.0
                    emotionAggregates[emotions[index], default: 0.0] += scaledValue
                }
            }
        }

        // Normalize the values so that the sum doesn't exceed 1.0
        let total = emotionAggregates.values.reduce(0.0, +)
        if total > 0 {
            emotions.forEach { emotion in
                emotionAggregates[emotion] = emotionAggregates[emotion]! / total
            }
        }

        // Determine the dominant emotion
        let dominantEmotion = emotionAggregates.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        
        let totalFrames = temporaryEmotionArray.count + emptyFaceCount

        // Invoke the callback with the results
        onEmotionsProcessed?(emotionAggregates, dominantEmotion, totalFrames)
    }

    public func stopEmotionsCapture(onEmotionsProcessed: (([String: Double], String, _ totalFrames: Int, _ totalFaceDetectFrameCount: Int) -> Void)? = nil) {
        // Stop the capture session
        captureSession.stopRunning()
        
        print("Total Empty Face count\(emptyFaceCount)")

        // Define the emotions array
        let emotions = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]

        // Initialize a dictionary to store aggregates for each emotion
        var emotionAggregates = [String: Double]()
        emotions.forEach { emotionAggregates[$0] = 0.0 }

        // Calculate the aggregate for each emotion
        for row in temporaryEmotionArray {
            for (index, value) in row.enumerated() {
                if index < emotions.count {
                    // Scale the value to be between 0.0 and 1.0 (originally between 0.0 and 10.0)
                    let scaledValue = min(max(Double(value), 0.0), 10.0) / 10.0 // Scale between 0.0 and 1.0
                    emotionAggregates[emotions[index], default: 0.0] += scaledValue
                }
            }
        }

        // Normalize the values so that the sum doesn't exceed 1.0
        let total = emotionAggregates.values.reduce(0.0, +)
        if total > 0 {
            emotions.forEach { emotion in
                emotionAggregates[emotion] = emotionAggregates[emotion]! / total
            }
        }

        // Determine the dominant emotion
        let dominantEmotion = emotionAggregates.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        
        let totalFaceDetectFrameCount = temporaryEmotionArray.count
        
        let totalFrames = temporaryEmotionArray.count + emptyFaceCount

        // Invoke the callback with the results
        onEmotionsProcessed?(emotionAggregates, dominantEmotion, totalFrames, totalFaceDetectFrameCount)
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
                self?.emptyFaceCount = self!.emptyFaceCount + 1
                print("No face \(self?.emptyFaceCount)")
                self?.isProcessing = false // Reset here if no face is found
                return
            }
            self?.processFace(in: image, with: face)
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
          //  print("Face detection failed: \(error.localizedDescription)")
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
            // Convert MLMultiArray to [Float32]
            let flatArray = convertMLMultiArrayToFloat32Array(output.var_455)
                      temporaryEmotionArray.append(flatArray)
            

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
 
 

//
//  EmoClassify.swift
//  imentiv_iOS_sdk
//
//  Created by aster on 16/10/24.
//


import UIKit
import AVFoundation
import Vision
import CoreML

public class CameraEmotionDetection: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let emotionModel = ds()
    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var emotionCompletionHandler: ((String, Double) -> Void)?
    
    public override init() {
        super.init()
    }
    
    public func startCamera() {
        setupCamera()
    }
    
    public func stopCamera() {
        captureSession.stopRunning()
    }
    
    public func getPredictedEmotion(completion: @escaping (String, Double) -> Void) {
        self.emotionCompletionHandler = completion
        //startCamera()
    }
    
    func setupCamera() {
        if captureSession.isRunning {
            return
        }
        captureSession.sessionPreset = .high
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Error: No front camera available")
            return
        }
        do {
            if let existingInput = captureSession.inputs.first {
                captureSession.removeInput(existingInput)
            }
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error: Could not create camera input: \(error)")
            return
        }
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if captureSession.outputs.contains(videoOutput) {
            captureSession.removeOutput(videoOutput)
        }
        captureSession.addOutput(videoOutput)
        captureSession.startRunning()
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let error = error {
                print("Error in face detection: \(error)")
                return
            }
            
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                return
            }
            
            if let face = results.first {
                self.handleDetectedFace(face: face, pixelBuffer: pixelBuffer)
            }
        }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try requestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform face detection: \(error)")
        }
    }
    
    
    private func handleDetectedFace(face: VNFaceObservation, pixelBuffer: CVPixelBuffer) {
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let boundingBox = face.boundingBox
        let faceRect = VNImageRectForNormalizedRect(boundingBox, Int(imageWidth), Int(imageHeight))
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: faceRect) else {
            print("Failed to create CGImage from CIImage")
            return
        }
        // Resize image for model (299x299)
        let faceImage = resizeImage(cgImage: cgImage, targetSize: CGSize(width: 299, height: 299))
        do {
            let buffer = try buffer(from: faceImage)
            let prediction = try emotionModel.prediction(image: buffer)
            let emotion = prediction.target
            if let confidence = prediction.targetProbability[emotion] {
                emotionCompletionHandler?(emotion, confidence)
            } else {
                print("Error: Confidence for the predicted emotion not found")
            }
        } catch {
            print("Error making prediction: \(error)")
        }
    }
    
    private func resizeImage(cgImage: CGImage, targetSize: CGSize) -> UIImage {
        let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: cgImage.bytesPerRow,
            space: cgImage.colorSpace!,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )!
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
        
        return UIImage(cgImage: context.makeImage()!)
    }
    
    // Convert UIImage to CVPixelBuffer
    private func buffer(from image: UIImage) throws -> CVPixelBuffer {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(image.size.width),
            Int(image.size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "Error creating pixel buffer", code: -1, userInfo: nil)
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )!
        context.draw(image.cgImage!, in: CGRect(origin: .zero, size: image.size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}






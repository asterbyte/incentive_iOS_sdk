//
//  EmotionClassify.swift
//  imentiv
//
//  Created by aster on 03/02/25.
//


/*
import Foundation

import UIKit
import Vision
import CoreML

public class EmotionClassify {
    
    private let model: RepVGG_A0_EmotionDetector
    
    public init() throws {
        // Initialize the emotion detection model
        self.model = try RepVGG_A0_EmotionDetector()
    }
    
    /// Detects faces in the given image and predicts emotions for each face.
    /// - Parameters:
    ///   - image: The input image containing faces.
    ///   - completion: A closure that returns an array of tuples containing bounding box coordinates and emotions.
    public func detectFacesAndEmotions(in image: UIImage, completion: @escaping ([(boundingBox: CGRect, emotion: String)]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        // Create a face detection request
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNFaceObservation],
                  !observations.isEmpty else {
                completion([])
                return
            }
            
            // Process the detected faces and predict emotions
            self.processFaces(in: image, observations: observations, completion: completion)
        }
        
        // Perform the face detection request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Face detection failed: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    /// Processes the detected faces, crops them, and predicts emotions.
    private func processFaces(in image: UIImage, observations: [VNFaceObservation], completion: @escaping ([(boundingBox: CGRect, emotion: String)]) -> Void) {
        let group = DispatchGroup()
        var faceDetails: [(boundingBox: CGRect, emotion: String)] = []
        
        for observation in observations {
            group.enter()
            
            // Crop the face from the image
            if let croppedFaceImage = self.cropFace(from: image, boundingBox: observation.boundingBox) {
                // Predict the emotion for the cropped face
                self.performEmotionClassification(on: croppedFaceImage) { emotion in
                    let boundingBox = self.transformBoundingBox(observation.boundingBox, for: image.size)
                    faceDetails.append((boundingBox: boundingBox, emotion: emotion))
                    group.leave()
                }
            } else {
                group.leave()
            }
        }
        
        // Notify when all faces have been processed
        group.notify(queue: .main) {
            completion(faceDetails)
        }
    }
    
    /// Crops a face from the image using the bounding box.
    private func cropFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        let imageSize = image.size
        let convertedBoundingBox = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        guard let cgImage = image.cgImage?.cropping(to: convertedBoundingBox) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Transforms the bounding box from normalized coordinates to image coordinates.
    private func transformBoundingBox(_ boundingBox: CGRect, for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }
    
    /// Predicts the emotion for a given face image.
    private func performEmotionClassification(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let facePixelBuffer = image.pixelBuffer(width: 224, height: 224) else {
            completion("unknown")
            return
        }
        do {
            let input = RepVGG_A0_EmotionDetectorInput(x: facePixelBuffer)
            let output = try model.prediction(input: input)
            let emotionLabels = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]
            let emotionIndex = argmax(array: output.var_455)
            let emotion = emotionLabels[emotionIndex]
            completion(emotion)
        } catch {
            completion("error")
        }
    }
    
    /// Finds the index of the maximum value in an MLMultiArray.
    private func argmax(array: MLMultiArray) -> Int {
        let floatArray = UnsafeBufferPointer(start: array.dataPointer.bindMemory(to: Float.self, capacity: array.count), count: array.count)
        return floatArray.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }
}
*/


import Foundation

import UIKit
import Vision
import CoreML

public class EmotionClassify {
    
    private let model: RepVGG_A0_EmotionDetector
    
    public init() throws {
        // Initialize the emotion detection model
        self.model = try RepVGG_A0_EmotionDetector()
    }
    
    /// Detects faces in the given image and predicts emotions for each face.
    /// - Parameters:
    ///   - image: The input image containing faces.
    ///   - completion: A closure that returns an array of tuples containing bounding box coordinates, emotions, and cropped face images.
    public func detectFacesAndEmotions(in image: UIImage, completion: @escaping ([(boundingBox: CGRect, emotion: String, faceImage: UIImage?)]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        // Create a face detection request
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNFaceObservation],
                  !observations.isEmpty else {
                completion([])
                return
            }
            
            // Process the detected faces and predict emotions
            self.processFaces(in: image, observations: observations, completion: completion)
        }
        
        // Perform the face detection request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Face detection failed: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    /// Processes the detected faces, crops them, and predicts emotions.
    private func processFaces(in image: UIImage, observations: [VNFaceObservation], completion: @escaping ([(boundingBox: CGRect, emotion: String, faceImage: UIImage?)]) -> Void) {
        let group = DispatchGroup()
        var faceDetails: [(boundingBox: CGRect, emotion: String, faceImage: UIImage?)] = []
        
        for observation in observations {
            group.enter()
            
            // Crop the face from the image
            let croppedFaceImage = self.cropFace(from: image, boundingBox: observation.boundingBox)
            
            if let croppedFaceImage = croppedFaceImage {
                // Predict the emotion for the cropped face
                self.performEmotionClassification(on: croppedFaceImage) { emotion in
                    let boundingBox = self.transformBoundingBox(observation.boundingBox, for: image.size)
                    faceDetails.append((boundingBox: boundingBox, emotion: emotion, faceImage: croppedFaceImage))
                    group.leave()
                }
            } else {
                let boundingBox = self.transformBoundingBox(observation.boundingBox, for: image.size)
                faceDetails.append((boundingBox: boundingBox, emotion: "unknown", faceImage: nil))
                group.leave()
            }
        }
        
        // Notify when all faces have been processed
        group.notify(queue: .main) {
            completion(faceDetails)
        }
    }
    
    /// Crops a face from the image using the bounding box.
    private func cropFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        let imageSize = image.size
        let convertedBoundingBox = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        guard let cgImage = image.cgImage?.cropping(to: convertedBoundingBox) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Transforms the bounding box from normalized coordinates to image coordinates.
    private func transformBoundingBox(_ boundingBox: CGRect, for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }
    
    /// Predicts the emotion for a given face image.
    private func performEmotionClassification(on image: UIImage, completion: @escaping (String) -> Void) {
        guard let facePixelBuffer = image.pixelBuffer(width: 224, height: 224) else {
            completion("unknown")
            return
        }
        do {
            let input = RepVGG_A0_EmotionDetectorInput(x: facePixelBuffer)
            let output = try model.prediction(input: input)
            let emotionLabels = ["anger", "contempt", "disgust", "fear", "happy", "neutral", "sad", "surprise"]
            let emotionIndex = argmax(array: output.var_455)
            let emotion = emotionLabels[emotionIndex]
            completion(emotion)
        } catch {
            completion("error")
        }
    }
    
    /// Finds the index of the maximum value in an MLMultiArray.
    private func argmax(array: MLMultiArray) -> Int {
        let floatArray = UnsafeBufferPointer(start: array.dataPointer.bindMemory(to: Float.self, capacity: array.count), count: array.count)
        return floatArray.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }
}

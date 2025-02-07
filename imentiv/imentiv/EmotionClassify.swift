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
    public func detectFacesAndEmotions(in image: UIImage, completion: @escaping ([(boundingBox: CGRect, emotion: String, faceImage: UIImage?)]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self, let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
                completion([])
                return
            }
            
            self.processFaces(in: image, observations: observations, completion: completion)
        }
        
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
    
    /// Processes detected faces, crops them, and predicts emotions.
    private func processFaces(in image: UIImage, observations: [VNFaceObservation], completion: @escaping ([(boundingBox: CGRect, emotion: String, faceImage: UIImage?)]) -> Void) {
        let group = DispatchGroup()
        var faceDetails: [(boundingBox: CGRect, emotion: String, faceImage: UIImage?)] = []
        
        for observation in observations {
            group.enter()
            
            let boundingBox = transformBoundingBox(observation.boundingBox, for: image.size)
            let croppedFaceImage = cropFace(from: image, boundingBox: boundingBox)
            
            if let croppedFaceImage = croppedFaceImage {
                performEmotionClassification(on: croppedFaceImage) { emotion in
                    faceDetails.append((boundingBox: boundingBox, emotion: emotion, faceImage: croppedFaceImage))
                    group.leave()
                }
            } else {
                faceDetails.append((boundingBox: boundingBox, emotion: "unknown", faceImage: nil))
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(faceDetails)
        }
    }
    
    private func cropFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        let imageSize = image.size
        let convertedBoundingBox = CGRect(
            x: boundingBox.origin.x,
            y: boundingBox.origin.y,
            width: boundingBox.width,
            height: boundingBox.height
        )
        
        // Ensure the crop is within image bounds
        let adjustedBoundingBox = CGRect(
            x: max(0, convertedBoundingBox.origin.x),
            y: max(0, convertedBoundingBox.origin.y),
            width: min(imageSize.width - convertedBoundingBox.origin.x, convertedBoundingBox.width),
            height: min(imageSize.height - convertedBoundingBox.origin.y, convertedBoundingBox.height)
        )
        
        guard let cgImage = image.cgImage?.cropping(to: adjustedBoundingBox) else {
            return nil
        }
        
        return normalizedImage(from: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Crops a face from the image based on the bounding box.
   /* private func cropFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        let imageSize = image.size
        let convertedBoundingBox = CGRect(
            x: boundingBox.origin.x,
            y: boundingBox.origin.y,
            width: boundingBox.width,
            height: boundingBox.height
        )
        
        // Ensure the crop is within image bounds
        let adjustedBoundingBox = CGRect(
            x: max(0, convertedBoundingBox.origin.x),
            y: max(0, convertedBoundingBox.origin.y),
            width: min(imageSize.width - convertedBoundingBox.origin.x, convertedBoundingBox.width),
            height: min(imageSize.height - convertedBoundingBox.origin.y, convertedBoundingBox.height)
        )
        
        guard let cgImage = image.cgImage?.cropping(to: adjustedBoundingBox) else {
            return nil
        }
        
        return normalizedImage(from: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }*/
    
    /// Transforms Vision's normalized bounding box to image coordinates.
   /* private func transformBoundingBox(_ boundingBox: CGRect, for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1.0 - boundingBox.origin.y) * imageSize.height - (boundingBox.height * imageSize.height),
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }*/
    private func transformBoundingBox(_ boundingBox: CGRect, for imageSize: CGSize) -> CGRect {
        // Vision's bounding box is normalized (0 to 1) and has its origin at the bottom-left.
        // UIKit's coordinate system has its origin at the top-left.
        
        let width = boundingBox.width * imageSize.width
        let height = boundingBox.height * imageSize.height
        let x = boundingBox.origin.x * imageSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
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
    
    /// Normalizes UIImage orientation to prevent rotation issues.
    private func normalizedImage(from cgImage: CGImage, scale: CGFloat, orientation: UIImage.Orientation) -> UIImage {
        let uiImage = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        UIGraphicsBeginImageContextWithOptions(uiImage.size, false, scale)
        uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? uiImage
    }
}















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
    public func detectFacesAndEmotions(in image: UIImage, completion: @escaping ([(boundingBox: CGRect, emotion: String, faceImage: UIImage?)]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self, let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
                completion([])
                return
            }
            
            self.processFaces(in: image, observations: observations, completion: completion)
        }
        
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
    
    /// Processes detected faces, crops them, and predicts emotions.
    private func processFaces(in image: UIImage, observations: [VNFaceObservation], completion: @escaping ([(boundingBox: CGRect, emotion: String, faceImage: UIImage?)]) -> Void) {
        let group = DispatchGroup()
        var faceDetails: [(boundingBox: CGRect, emotion: String, faceImage: UIImage?)] = []
        
        for observation in observations {
            group.enter()
            
            let boundingBox = transformBoundingBox(observation.boundingBox, for: image.size)
            let croppedFaceImage = cropFace(from: image, boundingBox: boundingBox)
            
            if let croppedFaceImage = croppedFaceImage {
                performEmotionClassification(on: croppedFaceImage) { emotion in
                    faceDetails.append((boundingBox: boundingBox, emotion: emotion, faceImage: croppedFaceImage))
                    group.leave()
                }
            } else {
                faceDetails.append((boundingBox: boundingBox, emotion: "unknown", faceImage: nil))
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(faceDetails)
        }
    }
    
    /// Crops a face from the image based on the bounding box.
    private func cropFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        let imageSize = image.size
        let convertedBoundingBox = CGRect(
            x: boundingBox.origin.x,
            y: boundingBox.origin.y,
            width: boundingBox.width,
            height: boundingBox.height
        )
        
        // Ensure the crop is within image bounds
        let adjustedBoundingBox = CGRect(
            x: max(0, convertedBoundingBox.origin.x),
            y: max(0, convertedBoundingBox.origin.y),
            width: min(imageSize.width - convertedBoundingBox.origin.x, convertedBoundingBox.width),
            height: min(imageSize.height - convertedBoundingBox.origin.y, convertedBoundingBox.height)
        )
        
        guard let cgImage = image.cgImage?.cropping(to: adjustedBoundingBox) else {
            return nil
        }
        
        return normalizedImage(from: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Transforms Vision's normalized bounding box to image coordinates.
    private func transformBoundingBox(_ boundingBox: CGRect, for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1.0 - boundingBox.origin.y) * imageSize.height - (boundingBox.height * imageSize.height),
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
    
    /// Normalizes UIImage orientation to prevent rotation issues.
    private func normalizedImage(from cgImage: CGImage, scale: CGFloat, orientation: UIImage.Orientation) -> UIImage {
        let uiImage = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        UIGraphicsBeginImageContextWithOptions(uiImage.size, false, scale)
        uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? uiImage
    }
}


*/









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
*/

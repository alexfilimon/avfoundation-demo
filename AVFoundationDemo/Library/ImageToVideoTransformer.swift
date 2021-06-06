//
//  ImageToVideoTransformer.swift
//  AVFoundationDemo
//
//  Created by al.filimonov on 01.06.2021.
//

import AVFoundation
import UIKit

class ImageToVideoTransformer: NSObject{

    // Private Properties

    private let videoSettings:[String : Any]
    private let fileURL:URL
    private let duration: CMTime

    private var assetWriter:AVAssetWriter!
    private var writeInput:AVAssetWriterInput!
    private var bufferAdapter:AVAssetWriterInputPixelBufferAdaptor!

    init(size: CGSize, duration: CMTime) {
        videoSettings = [AVVideoCodecKey: AVVideoCodecType.h264,
                         AVVideoWidthKey: Int(size.width),
                         AVVideoHeightKey: Int(size.height)]
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(ProcessInfo().globallyUniqueString)
            .appendingPathExtension("mov")
        self.fileURL = tmpURL
        self.duration = duration

        super.init()

        self.assetWriter = try! AVAssetWriter(url: self.fileURL, fileType: AVFileType.mov)
        self.writeInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assert(self.assetWriter.canAdd(self.writeInput), "add failed")

        self.assetWriter.add(self.writeInput)
        let bufferAttributes:[String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
        self.bufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.writeInput, sourcePixelBufferAttributes: bufferAttributes)
    }

    func createMovieFrom(image: UIImage, withCompletion: @escaping (URL) -> Void) {
        self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: CMTime.zero)

        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")

        self.writeInput.requestMediaDataWhenReady(on: mediaInputQueue) {

            if (self.writeInput.isReadyForMoreMediaData){
                var sampleBuffer:CVPixelBuffer?
                autoreleasepool{
                    sampleBuffer = self.newPixelBufferFrom(cgImage: image.cgImage!)
                }
                if (sampleBuffer != nil){
                    self.bufferAdapter.append(sampleBuffer!, withPresentationTime: .zero)
                    self.bufferAdapter.append(sampleBuffer!, withPresentationTime: self.duration)
                }
            }
            self.writeInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.sync {
                    withCompletion(self.fileURL)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func newPixelBufferFrom(cgImage:CGImage) -> CVPixelBuffer?{
        let options: [String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true,
                                     kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        var pxbuffer: CVPixelBuffer?
        let frameWidth = self.videoSettings[AVVideoWidthKey] as! Int
        let frameHeight = self.videoSettings[AVVideoHeightKey] as! Int

        let status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")

        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: frameWidth, height: frameHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")

        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }

}

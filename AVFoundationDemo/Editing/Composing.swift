//
//  Composing.swift
//  AVFoundationDemo
//
//  Created by al.filimonov on 31.05.2021.
//

import AVFoundation

class Composing {

    // MARK: - Constants

    private enum Constants {
        static let transitionDuration: Double = 1
        static let compositionSize = CGSize(width: 1920, height: 1080)
    }

    // MARK: - Private Properties

    private let items: [MediaItem]

    // MARK: - Initializaion

    init(items: [MediaItem]) {
        self.items = items
    }

    // MARK: - Methods

    func compose(completion: @escaping (Timeline) -> Void) {
        // создаем все свойства композиции
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        let audioMix = AVMutableAudioMix()

        // создаем треки
        let videoTrack1 = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )!
        let videoTrack2 = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )!
        let musicTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )!

        // создаем массив инструкций
        var instructions: [AVMutableVideoCompositionInstruction] = []

        // итерируемся по ранее найденным "частям"
        var time = CMTime.zero
        let transitionDuration = CMTime(
            seconds: Constants.transitionDuration,
            preferredTimescale: 600
        )
        for part in getParts(transitionDuration: transitionDuration) {

            switch part.type {
            case .single(let singleAssetInfo):
                let assetVideoTrack = singleAssetInfo.asset.tracks(withMediaType: .video).first!

                let instruction = AVMutableVideoCompositionInstruction()
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
                instruction.layerInstructions = [layerInstruction]
                instruction.timeRange = CMTimeRange(start: time, duration: part.duration)

                layerInstruction.setTransform(singleAssetInfo.transform, at: time)

                try! videoTrack1.insertTimeRange(
                    CMTimeRange(start: singleAssetInfo.startAt, duration: part.duration),
                    of: assetVideoTrack,
                    at: time
                )

                instructions.append(instruction)
            case .transition(let fromAssetInfo, let toAssetInfo):
                let fromAssetVideoTrack = fromAssetInfo.asset.tracks(withMediaType: .video).first!
                let toAssetVideoTrack = toAssetInfo.asset.tracks(withMediaType: .video).first!

                let instruction = AVMutableVideoCompositionInstruction()

                let fromLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
                let toLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)

                instruction.layerInstructions = [fromLayerInstruction, toLayerInstruction]
                instruction.timeRange = CMTimeRange(start: time, duration: part.duration)

                fromLayerInstruction.setTransform(fromAssetInfo.transform, at: time)
                toLayerInstruction.setTransform(toAssetInfo.transform, at: time)

                fromLayerInstruction.setOpacityRamp(
                    fromStartOpacity: 1,
                    toEndOpacity: 0,
                    timeRange: CMTimeRange(
                        start: time,
                        duration: transitionDuration
                    )
                )
                toLayerInstruction.setOpacityRamp(
                    fromStartOpacity: 0,
                    toEndOpacity: 1,
                    timeRange: CMTimeRange(
                        start: time,
                        duration: transitionDuration
                    )
                )

                try! videoTrack1.insertTimeRange(
                    CMTimeRange(start: fromAssetInfo.startAt, duration: part.duration),
                    of: fromAssetVideoTrack,
                    at: time
                )
                try! videoTrack2.insertTimeRange(
                    CMTimeRange(start: toAssetInfo.startAt, duration: part.duration),
                    of: toAssetVideoTrack,
                    at: time
                )

                instructions.append(instruction)
            }


            time = CMTimeAdd(time, part.duration)
        }

        // добавляем музыку
        let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3")!
        let musicAsset = AVAsset(url: musicURL)
        let musicAssetTrack = musicAsset.tracks(withMediaType: .audio).first!
        try! musicTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: time),
            of: musicAssetTrack,
            at: .zero
        )

        // настраиваем AVVideoComposition
        videoComposition.instructions = instructions
        videoComposition.frameDuration = CMTime(value: 1, timescale: 600)
        videoComposition.renderSize = .init(width: 1920, height: 1080)

        // создаем Timeline и вызываем completion
        let result = Timeline(
            composition: composition,
            audioMix: audioMix,
            videoComposition: videoComposition
        )
        completion(result)
    }

    // MARK: - Private Methods

    private func getTransform(from assetVideoTrack: AVAssetTrack) -> CGAffineTransform {
        let assetTrackSize = assetVideoTrack.naturalSize
        let prefferedTransform = assetVideoTrack.preferredTransform
        let assetTrackSizeAfterPrefferedTransform = assetTrackSize.applying(prefferedTransform)
        let fitTransform = AffineTransformations.getFitTransform(of: assetTrackSizeAfterPrefferedTransform, to: Constants.compositionSize)
        return prefferedTransform.concatenating(fitTransform)
    }

    private struct AssetInfo {
        let asset: AVAsset
        let startAt: CMTime
        let transform: CGAffineTransform
    }

    private struct PartInfo {
        let type: Part
        let duration: CMTime
    }

    private enum Part {
        case single(AssetInfo)
        case transition(from: AssetInfo, to: AssetInfo)
    }

    private func getParts(transitionDuration: CMTime) -> [PartInfo] {
        var partsInfos: [PartInfo] = []

        var previousItem: MediaItem?
        for currentItem in items {

            let currentVideoTrack = currentItem.asset.tracks(withMediaType: .video).first!
            let currentItemTransform = getTransform(from: currentVideoTrack)

            if let previousItem = previousItem {
                let previousVideoTrack = previousItem.asset.tracks(withMediaType: .video).first!
                let previousTransform = getTransform(from: previousVideoTrack)

                partsInfos.append(
                    .init(
                        type: .transition(
                            from: .init(asset: previousItem.asset, startAt: CMTimeSubtract(previousItem.duration, transitionDuration), transform: previousTransform),
                            to: .init(asset: currentItem.asset, startAt: .zero, transform: currentItemTransform)
                        ),
                        duration: transitionDuration
                    )
                )

                partsInfos.append(
                    .init(
                        type: .single(.init(asset: currentItem.asset, startAt: transitionDuration, transform: currentItemTransform)),
                        duration: CMTimeSubtract(currentItem.duration, CMTimeMultiply(transitionDuration, multiplier: 2))
                    )
                )
            } else {
                partsInfos.append(
                    .init(
                        type: .single(.init(asset: currentItem.asset, startAt: .zero, transform: currentItemTransform)),
                        duration: CMTimeSubtract(currentItem.duration, transitionDuration)
                    )
                )
            }

            previousItem = currentItem
        }

        return partsInfos
    }

}

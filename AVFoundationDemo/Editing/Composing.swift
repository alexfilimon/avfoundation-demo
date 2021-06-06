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
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

        // создаем инструкции для определения правил смешивания видео (всегда берем videoTrack)
        let mainInstruction = AVMutableVideoCompositionInstruction()
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        // добавляем все AVAsset в видео трек
        var time = CMTime.zero
        for item in items {

            let itemAssetTrack = item.asset.tracks(withMediaType: .video).first!

            try! videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: item.duration), of: itemAssetTrack, at: time)

            layerInstruction.setTransform(getTransform(from: itemAssetTrack), at: time)

            time = CMTimeAdd(time, item.duration)
        }

        // добавляем музыку
        let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3")!
        let musicAsset = AVAsset(url: musicURL)
        let musicAssetTrack = musicAsset.tracks(withMediaType: .audio).first!
        try! audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: time), of: musicAssetTrack, at: .zero)

        // настраиваем инструкции
        mainInstruction.layerInstructions = [layerInstruction]
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: time)

        // конфигурируем AVVideoComposition
        videoComposition.renderSize = CGSize(width: 1920, height: 1080)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [mainInstruction]

        // создаем Timeline и вызываем completion
        let result = Timeline(
            composition: composition,
            audioMix: audioMix,
            videoComposition: videoComposition
        )
        completion(result)
    }

    private func getTransform(from assetVideoTrack: AVAssetTrack) -> CGAffineTransform {
        let assetTrackSize = assetVideoTrack.naturalSize
        let prefferedTransform = assetVideoTrack.preferredTransform
        let assetTrackSizeAfterPrefferedTransform = assetTrackSize.applying(prefferedTransform)
        let fitTransform = AffineTransformations.getFitTransform(of: assetTrackSizeAfterPrefferedTransform, to: Constants.compositionSize)
        return prefferedTransform.concatenating(fitTransform)
    }

}

//
//  Exporter.swift
//  AVFoundationDemo
//
//  Created by al.filimonov on 31.05.2021.
//

import AVFoundation

class Exporter {

    // MARK: - Private Properties

    private let timeline: Timeline

    // MARK: - Initializaion

    init(timeline: Timeline) {
        self.timeline = timeline
    }

    // MARK: - Methods

    func export(completion: @escaping (URL) -> Void) {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(ProcessInfo().globallyUniqueString)
            .appendingPathExtension("mp4")
        guard
            let exportSession = AVAssetExportSession(asset: timeline.composition, presetName: AVAssetExportPreset1920x1080),
            exportSession.supportedFileTypes.contains(.mp4)
        else {
            return
        }

        exportSession.videoComposition = timeline.videoComposition
        exportSession.outputURL = tmpURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.timeRange = CMTimeRange(start: .zero, duration: timeline.composition.duration)

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(tmpURL)
            default:
                print()
            }

        }

    }

}

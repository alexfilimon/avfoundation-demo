//
//  MediaItem.swift
//  AVFoundationDemo
//
//  Created by al.filimonov on 01.06.2021.
//

import AVFoundation

struct MediaItem {

    // MARK: - Nested Types

    enum ItemType {
        case video
        case image
    }

    // MARK: - Properties

    let asset: AVAsset
    let type: ItemType

    // MARK: - Computed Properties

    var duration: CMTime {
        switch type {
        case .image:
            return CMTime(seconds: 6, preferredTimescale: CMTimeScale(600))
        case .video:
            return asset.duration
        }
    }

}

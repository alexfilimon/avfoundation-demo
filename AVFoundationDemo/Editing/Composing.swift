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

    }

}

//
//  CustomViewController.swift
//  AVFoundationDemo
//
//  Created by al.filimonov on 31.05.2021.
//

import UIKit
import AnyImageKit
import TinyConstraints
import AVKit

class CustomViewController: UIViewController, ImagePickerControllerDelegate {

    private let button = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(button)
        button.bottomToSuperview(offset: -20)
        button.horizontalToSuperview(insets: .horizontal(16), usingSafeArea: true)
        button.height(60)
        button.setTitle("Pick from gallery", for: .normal)
        button.addTarget(self, action: #selector(handleButtonPress), for: .touchUpInside)
    }

    @objc
    private func handleButtonPress() {
        var options = PickerOptionsInfo()
        options.selectOptions = [.photo, .video]
        options.albumOptions = [.userCreated]
        let controller = ImagePickerController(options: options, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    private func handleGalleryItems(_ items: [MediaItem]) {
        print("\(items.count) items picked from gallery")

        Composing(items: items).compose { [weak self] timeline in
            Exporter(timeline: timeline).export { [weak self] exportedURL in
                self?.openRenderedResult(url: exportedURL)
            }
        }
    }

    private func openRenderedResult(url: URL) {
        DispatchQueue.main.async {
            let playerController = AVPlayerViewController()
            playerController.player = AVPlayer(url: url)
            self.present(playerController, animated: true, completion: nil)
        }
    }

    // MARK: - ImagePickerControllerDelegate

    func imagePickerDidCancel(_ picker: ImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        var composeItems: [MediaItem] = []

        let group = DispatchGroup()

        for asset in result.assets {
            switch asset.mediaType {
            case .photo, .photoGIF, .photoLive:
                group.enter()
                let imageToVideo = ImageToVideoTransformer(
                    size: asset.image.size,
                    duration: CMTime(seconds: 30, preferredTimescale: 600)
                )
                imageToVideo.createMovieFrom(image: asset.image) { url in
                    composeItems.append(.init(asset: AVAsset(url: url), type: .image))
                    group.leave()
                }
            case .video:
                let options = VideoURLFetchOptions()
                group.enter()
                asset.fetchVideoURL(options: options) { result, _ in
                    switch result {
                    case .success(let response):
                        composeItems.append(.init(asset: AVAsset(url: response.url), type: .video))
                    case .failure:
                        print("error getting video URL")
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.handleGalleryItems(composeItems)
        }

        picker.dismiss(animated: true, completion: nil)
    }

}

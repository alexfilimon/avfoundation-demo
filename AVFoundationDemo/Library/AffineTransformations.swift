import AVFoundation

enum AffineTransformations {

    // MARK: - Static Methods

    static func getFitTransform(of ofSize: CGSize, to toSize: CGSize) -> CGAffineTransform {
        let itemAspectRatio = getAspectRatio(of: ofSize)
        let areaAspectRatio = getAspectRatio(of: toSize)

        if (itemAspectRatio > areaAspectRatio) {
            // scale (according to the width) and translate y
            let scaleFactor = abs(toSize.width) / abs(ofSize.width)
            let scaleTransform = CGAffineTransform.init(scaleX: scaleFactor, y: scaleFactor)

            let yOffset = (abs(toSize.height) - abs(ofSize.height) * scaleFactor) / 2
            let translateTransform = CGAffineTransform(translationX: 0, y: yOffset)

            return scaleTransform.concatenating(translateTransform)
        } else {
            // scale (according to the height) and translate x
            let scaleFactor = abs(toSize.height) / abs(ofSize.height)
            let scaleTransform = CGAffineTransform.init(scaleX: scaleFactor, y: scaleFactor)

            let xOffset = (abs(toSize.width) - abs(ofSize.width) * scaleFactor) / 2
            let translateTransform = CGAffineTransform(translationX: xOffset, y: 0)

            return scaleTransform.concatenating(translateTransform)
        }
    }

    static func getFillTransform(of ofSize: CGSize, to toSize: CGSize) -> CGAffineTransform {
        return getFitTransform(of: toSize, to: ofSize)
    }

    // MARK: - Private Static Methods

    private static func getAspectRatio(of size: CGSize) -> CGFloat {
        return abs(size.width) / abs(size.height)
    }

}

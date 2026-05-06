//  EventCVC.swift

import UIKit

final class EventCVC: UICollectionViewCell {

    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var eventTimeLbl: UILabel!
    @IBOutlet weak var bgImg: UIImageView!
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var gradientView: UIView!

    private let gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        gradientView.backgroundColor = .clear
        gradientView.isUserInteractionEnabled = false
        gradientView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = gradientView.bounds
        CATransaction.commit()
    }

    // ✅ MUST HAVE — keeps gradientLayer frame in sync with gradientView
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        CATransaction.begin()
//        CATransaction.setDisableActions(true)
//        gradientLayer.frame = gradientView.bounds
//        CATransaction.commit()
//    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bgImg.image = nil
        bgImage.image = nil
        gradientLayer.opacity = 0
    }

    func setupData(event: Event) {
        gradientLayer.opacity = 0
        let imageURL = URL(string: (event.flyer?.key ?? "").imageURL)

        bgImg.sd_setImage(with: imageURL, placeholderImage: Constant.Icon.uploadImage)

        bgImage.sd_setImage(
            with: imageURL,
            placeholderImage: Constant.Icon.uploadImage
        ) { [weak self] image, _, _, _ in
            guard let self else { return }

            guard let image else {
                    let color = Constant.Icon.uploadImage?.bottomAverageColor()
                    self.applyImageGradient(from: color)
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let color = image.bottomAverageColor()
                DispatchQueue.main.async {
                    self.applyImageGradient(from: color)
                }
            }
        }

        venueName.text     = event.venue?.name
        eventTitleLbl.text = event.title.uppercased()

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            eventTimeLbl.text = customText
        } else {
            let timezone  = ""
            let dateText  = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, customTimeZone: timezone)
            let startTime = event.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .hmma,    customTimeZone: timezone)
            let endTime   = event.endDateTime?.convertDateFormat(from:  .yyyyMMddHHmmss, to: .hmma,    customTimeZone: timezone) ?? "LATE"
            eventTimeLbl.text = (!dateText.isEmpty && !startTime.isEmpty) ? "\(dateText) at \(startTime) - \(endTime)" : ""
        }
    }

    // ✅ color is pre-sampled once — no double averageColor() call
    private func applyImageGradient(from color: UIColor?) {
        let base = color ?? UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)

        gradientLayer.colors = [
            UIColor.clear.cgColor,
            base.withAlphaComponent(0.25).cgColor,
            base.withAlphaComponent(0.65).cgColor,
            base.withAlphaComponent(0.92).cgColor,
            base.withAlphaComponent(1.0).cgColor,
            base.withAlphaComponent(1.0).cgColor   // ← double full opacity at very bottom
        ]
        gradientLayer.locations = [0.0, 0.15, 0.45, 0.70, 0.88, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        gradientLayer.opacity = 1
        CATransaction.commit()
    }

    func applyHeroIDs(event: Event, suffix: String) {
        bgImg.hero.id         = "event.image.\(event.id ?? "").\(suffix)"
        eventTitleLbl.hero.id = "event.title.\(event.id ?? "").\(suffix)"
    }

    func clearHeroIDs() {
        bgImg.hero.id         = nil
        eventTitleLbl.hero.id = nil
    }
}

// MARK: - UIImage + Bottom Color Sampling
extension UIImage {

    // samples only bottom 25% — matches Figma gradient color behavior
    func bottomAverageColor() -> UIColor {
        guard let cgImage = self.cgImage else { return .black }

        let fullWidth  = cgImage.width
        let fullHeight = cgImage.height
        let cropHeight = max(1, fullHeight / 4)
        let cropRect   = CGRect(
            x: fullWidth / 4,
            y: fullHeight - cropHeight,
            width: fullWidth / 2,
            height: cropHeight
        )

        guard let cropped = cgImage.cropping(to: cropRect) else { return .black }

        let ciImage      = CIImage(cgImage: cropped)
        let extentVector = CIVector(x: ciImage.extent.origin.x,
                                    y: ciImage.extent.origin.y,
                                    z: ciImage.extent.size.width,
                                    w: ciImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: ciImage,
                                                 kCIInputExtentKey: extentVector]),
              let output = filter.outputImage else { return .black }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(output,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        // * 0.85 keeps color vibrant but dark enough for readable text
        return UIColor(
            red:   CGFloat(bitmap[0]) / 255 * 0.85,
            green: CGFloat(bitmap[1]) / 255 * 0.85,
            blue:  CGFloat(bitmap[2]) / 255 * 0.85,
            alpha: 1
        )
    }
}

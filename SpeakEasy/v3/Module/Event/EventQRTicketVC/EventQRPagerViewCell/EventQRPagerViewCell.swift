import UIKit
import PassKit
import FSPagerView

struct EventTicketQR {
    let ticketName: String
    let qrString: String
    let backupCode: String
    let purchasedAtText: String
}

class EventQRPagerViewCell: FSPagerViewCell {

    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var ticketNameLbl: UILabel!
    @IBOutlet weak var ticketProgressLbl: UILabel!
    @IBOutlet weak var noTicketHiddenView: UIView!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!

    private var flipBackWorkItem: DispatchWorkItem?

    override func awakeFromNib() {
        super.awakeFromNib()
        qrCodeImageView.layer.magnificationFilter = .nearest
        noTicketHiddenView.isHidden = true
        ticketCodeView.isHidden = true
        backupCode.textColor = .black
        bookingDateTime.textColor = .black

        let tap = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        flipBackWorkItem?.cancel()
        flipBackWorkItem = nil
        ticketCodeView.isHidden = true
        qrCodeImageView.isHidden = false
        qrCodeImageView.image = nil
        containerView.isUserInteractionEnabled = true
    }

    deinit {
        flipBackWorkItem?.cancel()
    }

    func configure(with ticket: EventTicketQR, index: Int, total: Int) {
        ticketNameLbl.text = ticket.ticketName
        ticketProgressLbl.text = "\(index + 1) of \(total)"
        backupCode.text = ticket.backupCode
        bookingDateTime.text = ticket.purchasedAtText

        let hasQR = !ticket.qrString.isEmpty
        noTicketHiddenView.isHidden = hasQR
        qrCodeImageView.isHidden = !hasQR
        ticketCodeView.isHidden = true
        containerView.isUserInteractionEnabled = hasQR && !ticket.backupCode.isEmpty

        if hasQR {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let image = Self.generateQRCode(from: ticket.qrString)
                DispatchQueue.main.async {
                    self?.qrCodeImageView.image = image
                }
            }
        } else {
            qrCodeImageView.image = nil
        }
    }

    static func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
            return nil
        }

        let scaleX = 240.0 / ciImage.extent.width
        let scaleY = 240.0 / ciImage.extent.height
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    @objc private func qrImageTapped() {
        guard ticketCodeView.isHidden else { return }

        containerView.isUserInteractionEnabled = false
        flipBackWorkItem?.cancel()
        flipView()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.flipView()
            self.containerView.isUserInteractionEnabled = true
        }
        flipBackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func flipView() {
        UIView.transition(
            with: containerView,
            duration: 1,
            options: [.transitionFlipFromRight, .allowUserInteraction]
        ) { [weak self] in
            guard let self else { return }
            self.ticketCodeView.isHidden.toggle()
            self.qrCodeImageView.isHidden.toggle()
        }
    }
}

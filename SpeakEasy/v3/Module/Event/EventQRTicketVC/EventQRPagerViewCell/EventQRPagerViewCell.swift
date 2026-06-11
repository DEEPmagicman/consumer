import UIKit
import PassKit
import FSPagerView

struct EventTicketQR {
    let ticketName: String
    let qrString: String
}

class EventQRPagerViewCell: FSPagerViewCell {

    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var ticketNameLbl: UILabel!
    @IBOutlet weak var ticketProgressLbl: UILabel!
    @IBOutlet weak var noTicketHiddenView: UIView!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backupCode: UILabel!
    @IBOutlet weak var bookingDateTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        qrCodeImageView.layer.magnificationFilter = .nearest
        noTicketHiddenView.isHidden = true
    }

    func configure(with ticket: EventTicketQR, index: Int, total: Int) {
        ticketNameLbl.text = ticket.ticketName
        ticketProgressLbl.text = "\(index + 1) of \(total)"

        let hasQR = !ticket.qrString.isEmpty
        noTicketHiddenView.isHidden = hasQR
        qrCodeImageView.isHidden = !hasQR

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
}

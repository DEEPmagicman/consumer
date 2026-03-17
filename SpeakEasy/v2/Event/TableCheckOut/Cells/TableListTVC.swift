import UIKit

class TableListTVC: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tableName: UILabel!
    @IBOutlet weak var totalAmount: UILabel!
    @IBOutlet weak var secondAmountLbl: UILabel!
    @IBOutlet weak var tableDetailLbl: UILabel!
    @IBOutlet weak var tableDescriptionLbl: UILabel!
    @IBOutlet weak var bookBtn: UIButton!
    @IBOutlet weak var shimmerView: ShimmerView!

    let infoTextAttributes: [NSAttributedString.Key: Any] = [
        .font: AppFont.font(weight: .regular, size: 12),
        .foregroundColor: UIColor(hex: "#D2D5DB")
    ]

    var onBookTap: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        bookBtn.layer.cornerRadius = 16
        bookBtn.clipsToBounds = true
        stopShimmer()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBookTap = nil
        stopShimmer()
        tableName.text = nil
        totalAmount.text = nil
        secondAmountLbl.text = nil
        tableDetailLbl.attributedText = nil
        tableDescriptionLbl.text = nil
        bookBtn.setTitle(nil, for: .normal)
    }

    func startShimmer() {
        shimmerView.isHidden = false
        shimmerView.startAnimating()
        tableName.isHidden = true
        totalAmount.isHidden = true
        secondAmountLbl.isHidden = true
        tableDetailLbl.isHidden = true
        tableDescriptionLbl.isHidden = true
        bookBtn.isHidden = true
    }

    func stopShimmer() {
        shimmerView.stopAnimating()
        shimmerView.isHidden = true
        tableName.isHidden = false
        totalAmount.isHidden = false
        secondAmountLbl.isHidden = false
        tableDetailLbl.isHidden = false
        tableDescriptionLbl.isHidden = false
        bookBtn.isHidden = false
    }

    func makeIconAttachment(systemName: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemName)?
            .withTintColor(UIColor(hex: "#D2D5DB"), renderingMode: .alwaysOriginal)
        attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        return attachment
    }

    func buildGuestsTimeText(guests: String, time: String) -> NSAttributedString {
        let text = NSMutableAttributedString()

        text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "person.2")))
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
        text.append(NSAttributedString(string: guests, attributes: infoTextAttributes))

        if !time.isEmpty {
            text.append(NSAttributedString(string: "  ", attributes: infoTextAttributes))
            text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "clock")))
            text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
            text.append(NSAttributedString(string: time, attributes: infoTextAttributes))
        }

        return text
    }

    func configure(
        name: String,
        depositText: String,
        minimumText: String,
        guestsText: String,
        timeText: String,
        descriptionText: String,
        buttonTitle: String,
        hidePricing: Bool
    ) {
        tableName.text = name
        tableDescriptionLbl.text = descriptionText
        tableDetailLbl.attributedText = buildGuestsTimeText(guests: guestsText, time: timeText)
        bookBtn.setTitle(buttonTitle, for: .normal)

        totalAmount.text = hidePricing ? "" : depositText
        secondAmountLbl.text = hidePricing ? "" : minimumText
    }

    @IBAction func bookButtonTapped(_ sender: UIButton) {
        onBookTap?()
    }
}

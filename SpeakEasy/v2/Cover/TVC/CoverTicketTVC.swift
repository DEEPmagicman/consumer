import UIKit

final class CoverTicketTVC: UITableViewCell {

    @IBOutlet weak var minusBtnView: UIView!
    @IBOutlet weak var ticketCountView: UIView!
    @IBOutlet weak var plusBtnView: UIView!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var ticketCount: UILabel!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var extraFeesLbl: UILabel!
    @IBOutlet weak var viewMoreBtnView: UIView!
    @IBOutlet weak var viewMoreBtn: UIButton!

    private let collapsedLines = 3
    private var isExpanded = false
    private var currentTicketId: String?
    private var descriptionText: String = ""
    private var shouldShowViewMore = false
    private var lastMeasuredWidth: CGFloat = 0

    var onDescriptionToggle: ((String?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        descLbl.numberOfLines = collapsedLines
        descLbl.lineBreakMode = .byTruncatingTail
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        isExpanded = false
        currentTicketId = nil
        descriptionText = ""
        shouldShowViewMore = false
        lastMeasuredWidth = 0

        descLbl.text = nil
        descLbl.isHidden = false
        descLbl.numberOfLines = collapsedLines

        viewMoreBtnView.isHidden = true
        viewMoreBtn.setTitle("View More", for: .normal)

        onDescriptionToggle = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateViewMoreVisibilityIfNeeded()
    }

    func configure(description: String?, isExpanded: Bool, id: String?) {
        self.isExpanded = isExpanded
        self.currentTicketId = id

        let text = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !text.isEmpty else {
            descLbl.isHidden = true
            viewMoreBtnView.isHidden = true
            return
        }

        descLbl.isHidden = false
        descLbl.text = text
        descLbl.numberOfLines = isExpanded ? 0 : collapsedLines
        viewMoreBtn.setTitle(isExpanded ? "View Less" : "View More", for: .normal)

        layoutIfNeeded()

        let fullHeight = descLbl.sizeThatFits(
            CGSize(width: descLbl.frame.width, height: .greatestFiniteMagnitude)
        ).height

        let collapsedHeight = descLbl.font.lineHeight * CGFloat(collapsedLines)

        if fullHeight > collapsedHeight {
            viewMoreBtnView.isHidden = false
        } else {
            viewMoreBtnView.isHidden = true
            descLbl.numberOfLines = 0
        }
    }

    private func updateViewMoreVisibilityIfNeeded() {
        guard !descriptionText.isEmpty else { return }

        let width = descLbl.bounds.width
        guard width > 0 else { return }

        // Avoid repeating expensive and unstable calculations
        guard abs(width - lastMeasuredWidth) > 0.5 || shouldShowViewMore == false else {
            return
        }

        lastMeasuredWidth = width
        shouldShowViewMore = isTextCollapsible(text: descriptionText, width: width)
        applyDescriptionState()
    }

    private func isTextCollapsible(text: String, width: CGFloat) -> Bool {
        guard let font = descLbl.font else { return false }

        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )

        let collapsedHeight = ceil(font.lineHeight * CGFloat(collapsedLines))
        let fullHeight = ceil(boundingRect.height)

        return fullHeight > collapsedHeight
    }

    private func applyDescriptionState() {
        guard !descriptionText.isEmpty else {
            descLbl.isHidden = true
            viewMoreBtnView.isHidden = true
            return
        }

        descLbl.isHidden = false
        descLbl.text = descriptionText

        if shouldShowViewMore {
            viewMoreBtnView.isHidden = false
            descLbl.numberOfLines = isExpanded ? 0 : collapsedLines
            viewMoreBtn.setTitle(isExpanded ? "View Less" : "View More", for: .normal)
        } else {
            viewMoreBtnView.isHidden = true
            descLbl.numberOfLines = 0
            viewMoreBtn.setTitle("View More", for: .normal)
        }
    }

    @IBAction func onClickViewMoreBtn(_ sender: Any) {
        isExpanded.toggle()
        descLbl.numberOfLines = isExpanded ? 0 : collapsedLines
        viewMoreBtn.setTitle(isExpanded ? "View Less" : "View More", for: .normal)
        onDescriptionToggle?(currentTicketId)
    }
}

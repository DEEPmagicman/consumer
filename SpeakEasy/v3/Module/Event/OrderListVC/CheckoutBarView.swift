import UIKit
import MHLoadingButton

protocol CheckoutBarDelegate: AnyObject {
    func checkoutBarDidTapButton()
}

class CheckoutBarView: UIView {

    @IBOutlet var containerView: UIView!
    @IBOutlet private weak var totalAmountLbl: UILabel!
    @IBOutlet private weak var totalTicketLbl: UILabel!
    @IBOutlet private weak var extraFeesLbl: UILabel!
    @IBOutlet private weak var actionBtn: LoadingButton!

    weak var delegate: CheckoutBarDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromXib()
    }

    private func loadFromXib() {

        let nib = UINib(nibName: "CheckoutBarView", bundle: nil)

        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }

        containerView = view
        backgroundColor = .clear
        containerView.backgroundColor = .clear

        containerView.frame = bounds
        containerView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        addSubview(containerView)
        applyAccentColor(.white)
    }

    // MARK: - Public API

    func updateSummary(currency: String, currencyPosition: String?, count: Int, subtotal: Double, fees: Double) {
        totalAmountLbl.isHidden = true
        totalTicketLbl.isHidden = false
        totalTicketLbl.text = "\(count) Ticket\(count == 1 ? "" : "s")"
        extraFeesLbl.isHidden = true
    }

    func setButtonTitle(_ title: String) {
        actionBtn.setTitle(title, for: .normal)
    }

    func applyAccentColor(_ color: UIColor?) {
        let accentColor = color ?? .white
        let textColor = preferredButtonTextColor(for: accentColor)

        actionBtn.backgroundColor = accentColor
        actionBtn.bgColor = accentColor
        [
            UIControl.State.normal,
            .highlighted,
            .selected,
            .focused,
            .disabled
        ].forEach {
            actionBtn.setTitleColor(textColor, for: $0)
        }
        actionBtn.titleLabel?.textColor = textColor
        actionBtn.indicator = MaterialLoadingIndicator(color: textColor)
    }

    private func preferredButtonTextColor(for color: UIColor) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return UIColor(hex: "#121212")
        }

        func linearValue(_ value: CGFloat) -> CGFloat {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        let luminance = 0.2126 * linearValue(red)
            + 0.7152 * linearValue(green)
            + 0.0722 * linearValue(blue)

        return luminance > 0.35 ? UIColor(hex: "#121212") : .white
    }

    func showLoader() { actionBtn.showLoader(userInteraction: false) }
    func hideLoader() { actionBtn.hideLoader() }

    @IBAction private func buttonTapped(_ sender: Any) {
        delegate?.checkoutBarDidTapButton()
    }
}

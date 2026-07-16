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
        totalTicketLbl.text = "\(count) Ticket\(count == 1 ? "" : "s")"
        totalAmountLbl.text = subtotal <= 0
            ? "Free"
            : CurrencyFormatter.amount(subtotal, symbol: currency, position: currencyPosition)
        if fees > 0 {
            extraFeesLbl.isHidden = false
            extraFeesLbl.text = "Incl. \(CurrencyFormatter.amount(fees, symbol: currency, position: currencyPosition)) in fees"
        } else {
            extraFeesLbl.isHidden = true
        }
    }

    func setButtonTitle(_ title: String) {
        actionBtn.setTitle(title, for: .normal)
    }

    func applyAccentColor(_ color: UIColor?) {
        let accentColor = color ?? .white
        let textColor = accentColor.suitableTextColor()

        actionBtn.backgroundColor = accentColor
        actionBtn.bgColor = accentColor
        actionBtn.setTitleColor(textColor, for: .normal)
        actionBtn.indicator = MaterialLoadingIndicator(color: textColor)
    }

    func showLoader() { actionBtn.showLoader(userInteraction: false) }
    func hideLoader() { actionBtn.hideLoader() }

    @IBAction private func buttonTapped(_ sender: Any) {
        delegate?.checkoutBarDidTapButton()
    }
}

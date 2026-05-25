import UIKit
import MHLoadingButton

protocol CheckoutBarDelegate: AnyObject {
    func checkoutBarDidTapButton()
}

class CheckoutBarView: UIView {

    @IBOutlet private weak var containerView: UIView!
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
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        view.isHidden = false
        view.alpha = 1
    }

    // MARK: - Public API

    func updateSummary(currency: String, count: Int, subtotal: Double, fees: Double) {
        totalTicketLbl.text = "\(count) Ticket\(count == 1 ? "" : "s")"
        totalAmountLbl.text = "\(currency)\(subtotal.decimalFormat(true))"
        if fees > 0 {
            extraFeesLbl.isHidden = false
            extraFeesLbl.text = "Incl. \(currency)\(fees.decimalFormat(true)) in fees"
        } else {
            extraFeesLbl.isHidden = true
        }
    }

    func setButtonTitle(_ title: String) {
        actionBtn.setTitle(title, for: .normal)
    }

    func setVisible(_ visible: Bool, animated: Bool = true) {
        guard containerView.isHidden == visible else { return }

        if visible {
            containerView.isHidden = false
            containerView.alpha = 0
        }

        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.containerView.alpha = visible ? 1 : 0
            self.layoutIfNeeded()
        } completion: { _ in
            self.containerView.isHidden = !visible
        }
    }

    func showLoader() { actionBtn.showLoader(userInteraction: false) }
    func hideLoader() { actionBtn.hideLoader() }

    @IBAction private func buttonTapped(_ sender: Any) {
        delegate?.checkoutBarDidTapButton()
    }
}

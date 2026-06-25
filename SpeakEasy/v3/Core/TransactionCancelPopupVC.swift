import UIKit

final class TransactionCancelPopupVC: UIViewController {

    private let dimmedView = UIView()
    private let popupView = GradientBorderCardView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let keepCheckoutBtn = PrimaryButton()
    private let cancelTransactionBtn = PrimaryButton()

    private let titleText: String
    private let subtitleText: String
    private let keepTitle: String
    private let cancelTitle: String
    private let onCancelTransaction: () -> Void

    init(
        title: String = "Cancel transaction?",
        subtitle: String = "Your reserved tickets will be released and this checkout will close.",
        keepTitle: String = "Continue to checkout",
        cancelTitle: String = "Cancel transaction",
        onCancelTransaction: @escaping () -> Void
    ) {
        self.titleText = title
        self.subtitleText = subtitle
        self.keepTitle = keepTitle
        self.cancelTitle = cancelTitle
        self.onCancelTransaction = onCancelTransaction
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        dimmedView.alpha = 0
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmedView)

        let outsideTap = UITapGestureRecognizer(target: self, action: #selector(onClickKeepCheckout))
        dimmedView.addGestureRecognizer(outsideTap)
        dimmedView.isUserInteractionEnabled = true

        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.fillColor = AppColor.primaryColor.withAlphaComponent(0.5).cgColor
        popupView.showsBlur = true
        popupView.blurAlpha = 0.9
        popupView.cornerRadius = 30
        popupView.layer.cornerCurve = .continuous
        popupView.clipsToBounds = true
        popupView.alpha = 0
        view.addSubview(popupView)

        titleLabel.text = titleText
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(titleLabel)

        subtitleLabel.text = subtitleText
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 15)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(subtitleLabel)

        keepCheckoutBtn.configure(title: keepTitle, fontSize: 17, cornerRadius: 16)
        keepCheckoutBtn.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        keepCheckoutBtn.setTitleColor(AppColor.primaryWhiteColor, for: .normal)
        keepCheckoutBtn.addTarget(self, action: #selector(onClickKeepCheckout), for: .touchUpInside)
        popupView.addSubview(keepCheckoutBtn)

        cancelTransactionBtn.configure(title: cancelTitle, fontSize: 17, cornerRadius: 16)
        cancelTransactionBtn.backgroundColor = UIColor.systemRed.withAlphaComponent(0.95)
        cancelTransactionBtn.setTitleColor(.white, for: .normal)
        cancelTransactionBtn.addTarget(self, action: #selector(onClickCancelTransaction), for: .touchUpInside)
        popupView.addSubview(cancelTransactionBtn)

        let compactWidth = popupView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48)
        compactWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            popupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            popupView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            popupView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            popupView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            popupView.widthAnchor.constraint(lessThanOrEqualToConstant: 392),
            compactWidth,

            titleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 34),
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -24),

            keepCheckoutBtn.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 26),
            keepCheckoutBtn.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 18),
            keepCheckoutBtn.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -18),
            keepCheckoutBtn.heightAnchor.constraint(equalToConstant: 50),

            cancelTransactionBtn.topAnchor.constraint(equalTo: keepCheckoutBtn.bottomAnchor, constant: 12),
            cancelTransactionBtn.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 18),
            cancelTransactionBtn.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -18),
            cancelTransactionBtn.heightAnchor.constraint(equalToConstant: 50),
            cancelTransactionBtn.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -18)
        ])
    }

    private func animateIn() {
        popupView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.4,
            options: .curveEaseOut
        ) {
            self.dimmedView.alpha = 1
            self.popupView.alpha = 1
            self.popupView.transform = .identity
        }
    }

    private func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn]) {
            self.dimmedView.alpha = 0
            self.popupView.alpha = 0
            self.popupView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    @objc private func onClickKeepCheckout() {
        dismissSheet()
    }

    @objc private func onClickCancelTransaction() {
        keepCheckoutBtn.isUserInteractionEnabled = false
        cancelTransactionBtn.showLoader(userInteraction: false)
        let completion = onCancelTransaction
        dismissSheet(completion: completion)
    }
}

extension UIViewController {

    func presentTransactionCancelConfirmation(
        title: String = "Cancel transaction?",
        subtitle: String = "Your reserved tickets will be released and this checkout will close.",
        onCancelTransaction: @escaping () -> Void
    ) {
        let vc = TransactionCancelPopupVC(
            title: title,
            subtitle: subtitle,
            onCancelTransaction: onCancelTransaction
        )
        present(vc, animated: false)
    }
}

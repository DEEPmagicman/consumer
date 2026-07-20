import UIKit
import PassKit
import FSPagerView
import EventKit
import MapKit
import SDWebImage

enum EventQRTicketPresentationMode {
    case modal
    case pushedFromPurchase
}

class EventQRTicketVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var progressBarView: UIView?
    @IBOutlet weak var pagerView: FSPagerView!
    @IBOutlet weak var fandQtableView: UITableView!
    @IBOutlet weak var fandQtableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var fAndQDropDownImage: UIImageView!
    @IBOutlet weak var fandQtableHiddenView: UIView!
    @IBOutlet weak var eventTitle: UILabel?
    
    // MARK: - Data
    var tickets: [EventTicketQR] = []

    private var dotViews: [UIView] = []

    private var currentPage: Int = 0 {
        didSet {
            updateProgressDots()
        }
    }

    var bookingId = ""
    var booking: Booking?
    var sourceEvent: Event?
    var type: PaymentIntentType = .singleTickedEvent
    var presentationMode: EventQRTicketPresentationMode = .modal

    private var pass: PKPass?
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var isUpdatingTableHeight = false
    private var pagerViewConfigured = false
    private let posterHeaderView = EventPosterHeaderView()
    private let eventService = EventService()
    private let paymentService = PaymentService()
    private let eventStore = EKEventStore()
    private let loadingShimmerView = EventQRLoadingShimmerView()
    private var hasSetupPosterBackground = false
    private let actionStackView = UIStackView()
    private var hasSetupActionSection = false
    private var hasPlayedIntro = false
    private var hasPlayedPurchaseSuccessHaptic = false
    private var introOverlayView: UIView?
    private var introTicketCardView: TicketCardView?
    private var introHideWorkItem: DispatchWorkItem?
    private let ticketScrollView = UIScrollView()
    private let ticketContentView = UIView()
    private let ticketStackView = UIStackView()
    private let topHeaderView = UIView()
    private let eventHeaderTitleLabel = PremiumMarqueeLabel()
    private let eventHeaderVenueLabel = UILabel()
    private let eventHeaderTimeLabel = UILabel()
    private let passCardView = UIView()
    private let accountNameLabel = UILabel()
    private let purchaseTimeLabel = UILabel()
    private let qrGreenView = UIView()
    private let qrFlipBoxView = UIView()
    private let qrImageView = UIImageView()
    private let qrLogoContainerView = UIView()
    private let qrLogoImageView = UIImageView()
    private let qrCodeLabel = UILabel()
    private let helperTextLabel = UILabel()
    private let ticketRowsStackView = UIStackView()
    private let actionRowsStackView = UIStackView()
    private let orderSummaryView = UIView()
    private let orderSummaryStackView = UIStackView()
    private var isShowingBackupCode = false
    private var qrFlipWorkItem: DispatchWorkItem?
    private var didFetchFullBookingDetail = false
    private var previousInteractivePopEnabled: Bool?

    private var whiteLabelAccentColor: UIColor {
        UIColor(hex: booking?.event?.whiteLabelColor ?? sourceEvent?.whiteLabelColor ?? "#FFFFFF")
    }

    private var faqs: [(question: String, answer: String)] = []

    private var fandQItems: [EventFAQ] = []

    private var expandedFandQIndex: Int?
    private var expandedFAQIndex: Int?
    private var isFAndQExpanded = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPosterBackground()
        setupLoadingShimmer()
        setupLegacyContentHidden()
        setupTicketPassLayout()
        configurePresentationMode()
        hideShareButton()
        setupPagerView()
        setupTableView()
        setupActionSection()
        setupKVO()

        tableView.register(
            UINib(nibName: "TicketDetailTVC", bundle: nil),
            forCellReuseIdentifier: "TicketDetailTVC"
        )

        ticketListHeightObservation = tableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.tableView.contentSize.height
        }

        loadBookingData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playPurchaseSuccessHapticIfNeeded()
        WebSocketWrapper.shared.updateSocketContext(venueId: currentVenueIdForSocket())
        WebSocketWrapper.shared.removeDelegate(self)
        WebSocketWrapper.shared.addDelegate(self) 
    }

    private func playPurchaseSuccessHapticIfNeeded() {
        guard presentationMode == .pushedFromPurchase,
              !hasPlayedPurchaseSuccessHaptic else { return }

        hasPlayedPurchaseSuccessHaptic = true
        AppHaptic.success()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard presentationMode == .pushedFromPurchase else { return }
        previousInteractivePopEnabled =
        navigationController?.interactivePopGestureRecognizer?.isEnabled
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        introHideWorkItem?.cancel()
        qrFlipWorkItem?.cancel()
        WebSocketWrapper.shared.removeDelegate(self)

        if presentationMode == .pushedFromPurchase,
           let previousInteractivePopEnabled {
            navigationController?.interactivePopGestureRecognizer?.isEnabled =
            previousInteractivePopEnabled
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if posterHeaderView.superview != nil {
            view.sendSubviewToBack(posterHeaderView)
        }

        guard !pagerViewConfigured,
              pagerView.bounds.height > 0 else {
            return
        }

        pagerViewConfigured = true
        pagerView.itemSize = CGSize(
            width: view.bounds.width - 40,
            height: pagerView.bounds.height
        )
    }

    private func setupPosterBackground() {
        guard !hasSetupPosterBackground else { return }

        hasSetupPosterBackground = true
        posterHeaderView.applyBackgroundStyle(.softColorWash)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false
        posterHeaderView.isUserInteractionEnabled = false
        view.insertSubview(posterHeaderView, at: 0)

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLoadingShimmer() {
        loadingShimmerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingShimmerView)

        NSLayoutConstraint.activate([
            loadingShimmerView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingShimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingShimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingShimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configurePresentationMode() {
        let isPushed = presentationMode == .pushedFromPurchase
        closeButton()?.iconTypeValue =
        isPushed
        ? AppIconType.leftSideBack.rawValue
        : AppIconType.close.rawValue
    }

    private func closeButton() -> AppIconButton? {
        findAppIconButton(in: view) { button in
            button.iconTypeValue == AppIconType.close.rawValue ||
            button.iconTypeValue == AppIconType.leftSideBack.rawValue
        }
    }

    private func hideShareButton() {
        guard let shareButton = findAppIconButton(
            in: view,
            where: { $0.iconTypeValue == "share" }
        ) else {
            return
        }

        shareButton.isHidden = true
        shareButton.isUserInteractionEnabled = false
    }

    private func findAppIconButton(
        in view: UIView,
        where predicate: (AppIconButton) -> Bool
    ) -> AppIconButton? {
        for subview in view.subviews {
            if let button = subview as? AppIconButton,
               predicate(button) {
                return button
            }

            if let button = findAppIconButton(
                in: subview,
                where: predicate
            ) {
                return button
            }
        }

        return nil
    }

    private func setQRLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.view.bringSubviewToFront(self.loadingShimmerView)
                self.loadingShimmerView.show(animated: true)
            } else {
                self.loadingShimmerView.hide(animated: true)
            }
        }
    }

    private func showTicketToast(_ message: String) {
            Alert.showToast(message, vc: self)
    }

    private func refreshPosterBackground() {
        let imageURLString = (booking?.event?.flyer?.key ?? "").imageURL
        posterHeaderView.loadImage(from: imageURLString)
    }

    private func setupLegacyContentHidden() {
        pagerView.superview?.superview?.isHidden = true
        tableView.isHidden = true
        tableViewHeight.constant = 0
        fandQtableHiddenView.superview?.superview?.isHidden = true

        view.subviews
            .filter { subview in
                !(subview is UIButton)
                    && subview !== posterHeaderView
                    && subview !== loadingShimmerView
                    && subview.subviews.contains(where: { $0 is UILabel })
            }
            .forEach { $0.isHidden = true }
    }

    private func setupTicketPassLayout() {
        setupTopHeaderView()

        ticketScrollView.translatesAutoresizingMaskIntoConstraints = false
        ticketScrollView.showsVerticalScrollIndicator = false
        ticketScrollView.showsHorizontalScrollIndicator = false
        ticketScrollView.alwaysBounceVertical = true
        ticketScrollView.contentInset.bottom = 24
        view.addSubview(ticketScrollView)

        ticketContentView.translatesAutoresizingMaskIntoConstraints = false
        ticketScrollView.addSubview(ticketContentView)

        ticketStackView.axis = .vertical
        ticketStackView.spacing = 18
        ticketStackView.translatesAutoresizingMaskIntoConstraints = false
        ticketContentView.addSubview(ticketStackView)

        NSLayoutConstraint.activate([
            ticketScrollView.topAnchor.constraint(equalTo: topHeaderView.bottomAnchor, constant: 18),
            ticketScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ticketScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ticketScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ticketContentView.topAnchor.constraint(equalTo: ticketScrollView.contentLayoutGuide.topAnchor),
            ticketContentView.leadingAnchor.constraint(equalTo: ticketScrollView.contentLayoutGuide.leadingAnchor),
            ticketContentView.trailingAnchor.constraint(equalTo: ticketScrollView.contentLayoutGuide.trailingAnchor),
            ticketContentView.bottomAnchor.constraint(equalTo: ticketScrollView.contentLayoutGuide.bottomAnchor),
            ticketContentView.widthAnchor.constraint(equalTo: ticketScrollView.frameLayoutGuide.widthAnchor),

            ticketStackView.topAnchor.constraint(equalTo: ticketContentView.topAnchor),
            ticketStackView.leadingAnchor.constraint(equalTo: ticketContentView.leadingAnchor, constant: 12),
            ticketStackView.trailingAnchor.constraint(equalTo: ticketContentView.trailingAnchor, constant: -12),
            ticketStackView.bottomAnchor.constraint(equalTo: ticketContentView.bottomAnchor, constant: -24)
        ])

        ticketStackView.addArrangedSubview(passCardView)
        setupPassCardView()

        setupOrderSummaryView()
        ticketStackView.addArrangedSubview(orderSummaryView)

        ticketStackView.addArrangedSubview(makeActionSectionView())

        view.subviews.filter { $0 is UIButton }.forEach { view.bringSubviewToFront($0) }
        view.bringSubviewToFront(topHeaderView)
        view.bringSubviewToFront(loadingShimmerView)
    }

    private func setupTopHeaderView() {
        topHeaderView.translatesAutoresizingMaskIntoConstraints = false
        topHeaderView.backgroundColor = .clear
        topHeaderView.isUserInteractionEnabled = false
        view.addSubview(topHeaderView)

        let labelStack = UIStackView()
        labelStack.axis = .vertical
        labelStack.spacing = 6
        labelStack.alignment = .fill
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        topHeaderView.addSubview(labelStack)

        eventHeaderTitleLabel.font = Constant.Font.geistMedium(size: 20)
        eventHeaderTitleLabel.textColor = .white
        eventHeaderTitleLabel.animationSpeed = 25
        eventHeaderTitleLabel.animationDelay = 1.2
        eventHeaderTitleLabel.trailingSpacing = 48
        eventHeaderTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        eventHeaderVenueLabel.font = Constant.Font.geistMedium(size: 14)
        eventHeaderVenueLabel.textColor = .white
        eventHeaderVenueLabel.textAlignment = .center
        eventHeaderVenueLabel.numberOfLines = 1
        eventHeaderVenueLabel.lineBreakMode = .byTruncatingTail

        eventHeaderTimeLabel.font = Constant.Font.geistMedium(size: 14)
        eventHeaderTimeLabel.textColor = whiteLabelAccentColor
        eventHeaderTimeLabel.textAlignment = .center
        eventHeaderTimeLabel.numberOfLines = 2
        eventHeaderTimeLabel.lineBreakMode = .byTruncatingTail

        labelStack.addArrangedSubview(eventHeaderTitleLabel)
        labelStack.addArrangedSubview(eventHeaderVenueLabel)
        labelStack.addArrangedSubview(eventHeaderTimeLabel)

        NSLayoutConstraint.activate([
            topHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            topHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 75),
            topHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -75),

            labelStack.topAnchor.constraint(equalTo: topHeaderView.topAnchor),
            labelStack.leadingAnchor.constraint(equalTo: topHeaderView.leadingAnchor),
            labelStack.trailingAnchor.constraint(equalTo: topHeaderView.trailingAnchor),
            labelStack.bottomAnchor.constraint(equalTo: topHeaderView.bottomAnchor),

            eventHeaderTitleLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func setupPassCardView() {
        passCardView.translatesAutoresizingMaskIntoConstraints = false
        passCardView.applyAutoBorderBackground()
        passCardView.layer.cornerRadius = 18
        passCardView.layer.masksToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 22
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        passCardView.addSubview(stack)

        let metadataStack = UIStackView()
        metadataStack.axis = .vertical
        metadataStack.spacing = 7
        metadataStack.alignment = .center

        accountNameLabel.font = Constant.Font.geistSemiBold(size: 17)
        accountNameLabel.textColor = .white
        accountNameLabel.textAlignment = .center
        accountNameLabel.numberOfLines = 2

        purchaseTimeLabel.font = Constant.Font.geistMedium(size: 15)
        purchaseTimeLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        purchaseTimeLabel.textAlignment = .center
        purchaseTimeLabel.numberOfLines = 2

        metadataStack.addArrangedSubview(accountNameLabel)
        metadataStack.addArrangedSubview(purchaseTimeLabel)

        setupQRCodeView()

        helperTextLabel.font = Constant.Font.geistMedium(size: 15)
        helperTextLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        helperTextLabel.textAlignment = .center
        helperTextLabel.numberOfLines = 0
        helperTextLabel.text = "This code will be your way in. Show it upon arrival"

        ticketRowsStackView.axis = .vertical
        ticketRowsStackView.spacing = 0

        stack.addArrangedSubview(metadataStack)
        stack.addArrangedSubview(qrGreenView)
        stack.addArrangedSubview(helperTextLabel)
        stack.addArrangedSubview(ticketRowsStackView)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: passCardView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: passCardView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: passCardView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: passCardView.bottomAnchor, constant: -24)
        ])
    }

    private func setupQRCodeView() {
        qrGreenView.translatesAutoresizingMaskIntoConstraints = false
        qrGreenView.backgroundColor = .clear
        qrGreenView.layer.cornerRadius = 22
        qrGreenView.clipsToBounds = true

        qrFlipBoxView.translatesAutoresizingMaskIntoConstraints = false
        qrFlipBoxView.backgroundColor = .white
        qrFlipBoxView.layer.cornerRadius = 10
        qrFlipBoxView.clipsToBounds = true
        qrGreenView.addSubview(qrFlipBoxView)

        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.layer.magnificationFilter = .nearest
        qrFlipBoxView.addSubview(qrImageView)

        qrLogoContainerView.translatesAutoresizingMaskIntoConstraints = false
        qrLogoContainerView.backgroundColor = .white
        qrLogoContainerView.layer.cornerRadius = 22
        qrLogoContainerView.layer.borderWidth = 1
        qrLogoContainerView.layer.borderColor = UIColor.black.withAlphaComponent(0.12).cgColor
        qrLogoContainerView.clipsToBounds = true
        qrFlipBoxView.addSubview(qrLogoContainerView)

        qrLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        qrLogoImageView.contentMode = .scaleAspectFit
        qrLogoImageView.image = UIImage(named: "qrLogo")
        qrLogoContainerView.addSubview(qrLogoImageView)

        qrCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        qrCodeLabel.font = Constant.Font.geistSemiBold(size: 28)
        qrCodeLabel.textColor = .black
        qrCodeLabel.textAlignment = .center
        qrCodeLabel.numberOfLines = 2
        qrCodeLabel.adjustsFontSizeToFitWidth = true
        qrCodeLabel.minimumScaleFactor = 0.55
        qrCodeLabel.isHidden = true
        qrFlipBoxView.addSubview(qrCodeLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapQRCodeView))
        qrGreenView.addGestureRecognizer(tap)
        qrGreenView.isUserInteractionEnabled = true

        NSLayoutConstraint.activate([
            qrGreenView.heightAnchor.constraint(equalToConstant: 270),

            qrFlipBoxView.centerXAnchor.constraint(equalTo: qrGreenView.centerXAnchor),
            qrFlipBoxView.centerYAnchor.constraint(equalTo: qrGreenView.centerYAnchor),
            qrFlipBoxView.widthAnchor.constraint(equalToConstant: 214),
            qrFlipBoxView.heightAnchor.constraint(equalTo: qrFlipBoxView.widthAnchor),

            qrImageView.topAnchor.constraint(equalTo: qrFlipBoxView.topAnchor, constant: 12),
            qrImageView.leadingAnchor.constraint(equalTo: qrFlipBoxView.leadingAnchor, constant: 12),
            qrImageView.trailingAnchor.constraint(equalTo: qrFlipBoxView.trailingAnchor, constant: -12),
            qrImageView.bottomAnchor.constraint(equalTo: qrFlipBoxView.bottomAnchor, constant: -12),

            qrLogoContainerView.centerXAnchor.constraint(equalTo: qrFlipBoxView.centerXAnchor),
            qrLogoContainerView.centerYAnchor.constraint(equalTo: qrFlipBoxView.centerYAnchor),
            qrLogoContainerView.widthAnchor.constraint(equalToConstant: 44),
            qrLogoContainerView.heightAnchor.constraint(equalTo: qrLogoContainerView.widthAnchor),

            qrLogoImageView.topAnchor.constraint(equalTo: qrLogoContainerView.topAnchor, constant: 8),
            qrLogoImageView.leadingAnchor.constraint(equalTo: qrLogoContainerView.leadingAnchor, constant: 8),
            qrLogoImageView.trailingAnchor.constraint(equalTo: qrLogoContainerView.trailingAnchor, constant: -8),
            qrLogoImageView.bottomAnchor.constraint(equalTo: qrLogoContainerView.bottomAnchor, constant: -8),

            qrCodeLabel.leadingAnchor.constraint(equalTo: qrFlipBoxView.leadingAnchor, constant: 12),
            qrCodeLabel.trailingAnchor.constraint(equalTo: qrFlipBoxView.trailingAnchor, constant: -12),
            qrCodeLabel.centerYAnchor.constraint(equalTo: qrFlipBoxView.centerYAnchor)
        ])
    }

    private func makeActionSectionView() -> UIView {
        let container = UIView()
        container.applyAutoBorderBackground()
        container.layer.cornerRadius = 18
        container.layer.masksToBounds = true

        actionRowsStackView.axis = .vertical
        actionRowsStackView.spacing = 0
        actionRowsStackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(actionRowsStackView)

        [
            makePassActionRow(title: "View Event", icon: UIImage(systemName: "info.circle"), action: #selector(onClickViewEvent)),
            makePassActionRow(title: "Add to Calendar", icon: UIImage(systemName: "calendar"), action: #selector(onClickAddToCalendar)),
            makePassActionRow(title: "Add to Apple Wallet", icon: UIImage(systemName: "wallet.pass"), action: #selector(onClickAddToWallet)),
            makePassActionRow(title: "Get Directions", icon: UIImage(systemName: "mappin"), action: #selector(onClickGetDirections))
        ].enumerated().forEach { index, row in
            actionRowsStackView.addArrangedSubview(row)
            if index < 3 {
                actionRowsStackView.addArrangedSubview(makeDivider())
            }
        }

        NSLayoutConstraint.activate([
            actionRowsStackView.topAnchor.constraint(equalTo: container.topAnchor),
            actionRowsStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            actionRowsStackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            actionRowsStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makePassActionRow(
        title: String,
        icon: UIImage?,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: action, for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Constant.Font.geistSemiBold(size: 17)
        titleLabel.textColor = .white
        titleLabel.isUserInteractionEnabled = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.isUserInteractionEnabled = false
        iconView.contentMode = .scaleAspectFit

        button.addSubview(titleLabel)
        button.addSubview(iconView)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 62),

            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -16),

            iconView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -18),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
        ])

        return button
    }

    private func setupOrderSummaryView() {
        orderSummaryView.isHidden = false
        orderSummaryView.translatesAutoresizingMaskIntoConstraints = false
        orderSummaryView.applyAutoBorderBackground()
        orderSummaryView.layer.cornerRadius = 18
        orderSummaryView.layer.masksToBounds = true

        orderSummaryStackView.axis = .vertical
        orderSummaryStackView.spacing = 13
        orderSummaryStackView.translatesAutoresizingMaskIntoConstraints = false
        orderSummaryView.addSubview(orderSummaryStackView)

        NSLayoutConstraint.activate([
            orderSummaryStackView.topAnchor.constraint(equalTo: orderSummaryView.topAnchor, constant: 20),
            orderSummaryStackView.leadingAnchor.constraint(equalTo: orderSummaryView.leadingAnchor, constant: 18),
            orderSummaryStackView.trailingAnchor.constraint(equalTo: orderSummaryView.trailingAnchor, constant: -18),
            orderSummaryStackView.bottomAnchor.constraint(equalTo: orderSummaryView.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - KVO
    private func setupKVO() {
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        fandQtableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize")
        fandQtableView.removeObserver(self, forKeyPath: "contentSize")
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentSize", !isUpdatingTableHeight else {
            return
        }

        if let tv = object as? UITableView {
            if tv === tableView {
                let newHeight = tableView.contentSize.height
                guard newHeight != tableViewHeight.constant else { return }

                isUpdatingTableHeight = true
                tableViewHeight.constant = newHeight
                view.layoutIfNeeded()
                isUpdatingTableHeight = false
            } else if tv === fandQtableView {
                let newHeight = fandQtableView.contentSize.height
                guard newHeight != fandQtableViewHeight.constant else { return }

                isUpdatingTableHeight = true
                fandQtableViewHeight.constant = newHeight
                view.layoutIfNeeded()
                isUpdatingTableHeight = false
            }
        }
    }

    // MARK: - Pager Setup
    private func setupPagerView() {
        pagerView.dataSource = self
        pagerView.delegate = self

        pagerView.register(
            UINib(nibName: "EventQRPagerViewCell", bundle: nil),
            forCellWithReuseIdentifier: EventQRPagerViewCell.identifier
        )

        pagerView.isInfinite = false
        pagerView.automaticSlidingInterval = 0
        pagerView.interitemSpacing = 16
    }

    private func loadBookingData() {
        tableView.isHidden = true
        fandQtableHiddenView.superview?.superview?.isHidden = true

        if let booking {
            applyBooking(booking)
            refreshFullBookingDetailsIfNeeded(id: booking.id)
            return
        }

        guard !bookingId.isEmpty else {
            updateFAndQAvailability()
            return
        }

        getBooking(id: bookingId)
    }

    private func applyBooking(_ booking: Booking) {
        self.booking = booking
        WebSocketWrapper.shared.updateSocketContext(venueId: currentVenueIdForSocket())
        self.eventTitle?.text = booking.event?.title
        if bookingId.isEmpty {
            bookingId = booking.id
        }

        applyWhiteLabelTheme()
        configureEventRows()
        refreshPosterBackground()
        renderTicketPass()
    }

    private func currentVenueIdForSocket() -> String? {
        booking?.venueId
        ?? booking?.venueObject?.id
        ?? booking?.event?.venue?.id
        ?? sourceEvent?.venue?.id
    }

    private func configureEventRows() {
        faqs = [
            (
                question: "Event details.",
                answer: "View all event information including venue, date, time, and other event-related details."
            ),
            (
                question: "How to use my tickets",
                answer: "This code will be your way in. Show it upon arrival"
            )
        ]
        tableView.isHidden = true
        tableViewHeight.constant = 0
        fandQtableHiddenView.superview?.superview?.isHidden = true
    }

    private func setupActionSection() {
        guard !hasSetupActionSection,
              let parentStack = tableView.superview as? UIStackView else {
            return
        }

        hasSetupActionSection = true
        actionStackView.axis = .vertical
        actionStackView.spacing = 10
        actionStackView.isHidden = true
        actionStackView.translatesAutoresizingMaskIntoConstraints = false

        parentStack.addArrangedSubview(actionStackView)
        configureActionSection()
    }

    private func configureActionSection() {
        actionStackView.isHidden = booking?.event == nil

        actionStackView.arrangedSubviews.forEach {
            actionStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        [
            makeActionRow(title: "View Event", icon: UIImage(systemName: "info.circle"), action: #selector(onClickViewEvent)),
            makeActionRow(title: "Add to Calendar", icon: UIImage(systemName: "calendar"), action: #selector(onClickAddToCalendar)),
            makeActionRow(title: "Add to Apple Wallet", icon: UIImage(systemName: "wallet.pass"), action: #selector(onClickAddToWallet)),
            makeActionRow(title: "Get Directions", icon: UIImage(systemName: "mappin"), action: #selector(onClickGetDirections))
        ].forEach { actionStackView.addArrangedSubview($0) }
    }

    private func makeActionRow(title: String, icon: UIImage?, action: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        button.layer.cornerRadius = 14
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.font = Constant.Font.geistMedium(size: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false

        let imageView = UIImageView(image: icon)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false

        button.addSubview(label)
        button.addSubview(imageView)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 64),

            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 18),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: imageView.leadingAnchor, constant: -16),

            imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -18),
            imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        ])

        return button
    }

    private func showTicketIntroIfNeeded() {
        guard !hasPlayedIntro, !tickets.isEmpty else { return }
        hasPlayedIntro = true
        showTicketIntro()
    }

    private func showTicketIntro() {
        introHideWorkItem?.cancel()

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = true

        let ticketCard = TicketCardView()
        ticketCard.translatesAutoresizingMaskIntoConstraints = false
        ticketCard.setImage(named: "newSpeakeasy")
        overlay.addSubview(ticketCard)

        let venueLabel = UILabel()
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        venueLabel.text = booking?.venueObject?.name ?? booking?.event?.venue?.name ?? ""
        venueLabel.textAlignment = .center
        venueLabel.font = Constant.Font.geistMedium(size: 22)
        venueLabel.textColor = .white
        venueLabel.numberOfLines = 2
        overlay.addSubview(venueLabel)

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.text = eventDateTimeText()
        dateLabel.textAlignment = .center
        dateLabel.font = Constant.Font.geistMedium(size: 18)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        dateLabel.numberOfLines = 2
        overlay.addSubview(dateLabel)

        view.addSubview(overlay)
        view.bringSubviewToFront(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            ticketCard.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            ticketCard.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -18),
            ticketCard.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.62),
            ticketCard.heightAnchor.constraint(equalTo: ticketCard.widthAnchor, multiplier: 0.97),

            venueLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 36),
            venueLabel.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -36),
            venueLabel.bottomAnchor.constraint(equalTo: ticketCard.topAnchor, constant: -24),

            dateLabel.leadingAnchor.constraint(equalTo: venueLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: venueLabel.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: ticketCard.bottomAnchor, constant: 24)
        ])

        introOverlayView = overlay
        introTicketCardView = ticketCard

        if let imageUrlString = booking?.event?.flyer?.key?.imageURL,
           let url = URL(string: imageUrlString) {
            SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil) {
                [weak ticketCard] image, _, _, _, _, _ in
                DispatchQueue.main.async {
                    ticketCard?.setImage(image ?? UIImage(named: "newSpeakeasy"))
                }
            }
        }

        view.layoutIfNeeded()
        ticketCard.playEntryAnimation()

        let workItem = DispatchWorkItem { [weak self] in
            self?.hideTicketIntro()
        }
        introHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: workItem)
    }

    private func hideTicketIntro() {
        guard let overlay = introOverlayView else { return }

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            overlay.alpha = 0
            overlay.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { [weak self] _ in
            overlay.removeFromSuperview()
            self?.introOverlayView = nil
            self?.introTicketCardView = nil
        }
    }

    private func renderTicketPass() {
        guard let booking else { return }

        eventHeaderTitleLabel.setText(booking.event?.title ?? "-")
        eventHeaderVenueLabel.text = booking.venueObject?.name
            ?? booking.event?.venue?.name
            ?? "-"
        eventHeaderTimeLabel.text = eventHeaderTimeText()
        applyWhiteLabelTheme()
        accountNameLabel.text = accountNameText()
        purchaseTimeLabel.text = purchaseTimeText()
        qrCodeLabel.text = backupCodeText()
        qrImageView.image = EventQRPagerViewCell.generateQRCode(from: eventQRCodePayload(for: booking.id))
        applyQRCodeBorderColor(for: booking)

        qrLogoImageView.image = UIImage(named: "qrLogo") ?? UIImage(named: "newSpeakeasy") ?? UIImage(named: "appLogo")
        renderTicketRows()
        renderOrderSummary()
    }

    private func applyWhiteLabelTheme() {
        eventHeaderTimeLabel.textColor = whiteLabelAccentColor
    }

    private func applyQRCodeBorderColor(for booking: Booking) {
        if let eventQRCodeColor = TicketQRCodeColorResolver.normalizeColor(
            booking.event?.eventSettings?.qrCodeColor
            ?? sourceEvent?.eventSettings?.qrCodeColor
        ) {
            qrGreenView.backgroundColor = UIColor(hex: eventQRCodeColor)
            return
        }

        qrGreenView.backgroundColor = TicketQRCodeColorResolver.color(
            venueSettings: booking.venueObject?.venueSettings
            ?? booking.event?.venue?.venueSettings
            ?? sourceEvent?.venue?.venueSettings,
            ticketType: .event,
            isFreeTicket: isFreeEventBooking(booking),
            preferredColor: booking.isCompedTicket == true
            ? booking.venueObject?.venueSettings?.compedTicketQrCodeBorderColor
            : nil,
            useFallbackWhenPreferredMissing: booking.isCompedTicket == true,
            fallbackColor: "#19D43A"
        ) ?? UIColor(hex: "#19D43A")
    }

    private func isFreeEventBooking(_ booking: Booking) -> Bool {
        let tickets = booking.bookingHasItem
        guard !tickets.isEmpty else { return false }
        return tickets.allSatisfy { $0.ticketPrice <= 0 }
    }

    private func renderTicketRows() {
        ticketRowsStackView.arrangedSubviews.forEach {
            ticketRowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let ticketItems = booking?.uniqueTickets ?? []
        ticketItems.enumerated().forEach { index, ticket in
            ticketRowsStackView.addArrangedSubview(makeTicketProgressRow(for: ticket))
            if index < ticketItems.count - 1 {
                ticketRowsStackView.addArrangedSubview(makeDivider())
            }
        }
    }

    private func makeTicketProgressRow(for ticket: BookingHasItem) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = ticketDisplayName(ticket)
        titleLabel.font = Constant.Font.geistSemiBold(size: 15)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2

        let quantityLabel = UILabel()
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.text = "\(ticket.selectedQuantity ?? 0)x"
        quantityLabel.font = Constant.Font.geistSemiBold(size: 15)
        quantityLabel.textColor = .white
        quantityLabel.textAlignment = .right

        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.24)
        progressView.progressTintColor = UIColor.white.withAlphaComponent(0.78)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true

        let checkedIn = checkedInQuantity(for: ticket)
        let total = max(ticket.selectedQuantity ?? 0, 0)
        progressView.progress = total > 0 ? Float(checkedIn) / Float(total) : 0

        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.text = "\(checkedIn)/\(total)"
        countLabel.font = Constant.Font.geistSemiBold(size: 15)
        countLabel.textColor = .white
        countLabel.textAlignment = .right

        container.addSubview(titleLabel)
        container.addSubview(quantityLabel)
        container.addSubview(progressView)
        container.addSubview(countLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 82),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -12),

            quantityLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            quantityLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            quantityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),

            progressView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -16),
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            progressView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            countLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 48)
        ])

        return container
    }

    private func checkedInQuantity(for ticket: BookingHasItem) -> Int {
        let checkedItemIds = Set(
            booking?.bookingHasCheckIn?
                .flatMap { $0.bookingItemCheckIn }
                .filter { !$0.isDeleted }
                .map { $0.bookingHasItemId } ?? []
        )

        guard !checkedItemIds.isEmpty else {
            return ticket.checkedInQuantity ?? 0
        }

        return booking?.bookingHasItem
            .filter { $0.ticketId == ticket.ticketId && checkedItemIds.contains($0.id) }
            .count ?? (ticket.checkedInQuantity ?? 0)
    }

    private func renderOrderSummary() {
        orderSummaryStackView.arrangedSubviews.forEach {
            orderSummaryStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.text = "Your order"
        titleLabel.font = Constant.Font.geistSemiBold(size: 18)
        titleLabel.textColor = .white
        orderSummaryStackView.addArrangedSubview(titleLabel)

        let ticketItems = booking?.uniqueTickets ?? []
        let ticketSubtotal = ticketItems.reduce(0.0) { partialResult, ticket in
            partialResult + (Double(ticket.selectedQuantity ?? 0) * ticket.ticketPrice)
        }

        ticketItems.forEach { ticket in
            let quantity = ticket.selectedQuantity ?? 0
            let price = Double(quantity) * ticket.ticketPrice
            orderSummaryStackView.addArrangedSubview(
                makeOrderSummaryRow(
                    title: "\(quantity)x \(ticketDisplayName(ticket))",
                    value: price <= 0 ? "Free" : "$\(price.decimalFormat(true))"
                )
            )
        }

        orderSummaryStackView.addArrangedSubview(makeDivider())

        let fees = booking?.fees
        let subtotal = fees?.subTotal ?? ticketSubtotal
        let salesTax = fees?.salesTax ?? 0
        let processingFee = fees?.processingFee ?? 0
        let customFee = fees?.customFee ?? 0
        let total = booking?.totalPrice ?? fees?.total ?? subtotal + salesTax + processingFee + customFee

        orderSummaryStackView.addArrangedSubview(
            makeOrderSummaryRow(
                title: "Subtotal",
                value: subtotal <= 0 ? "Free" : "$\(subtotal.decimalFormat(true))"
            )
        )

        if salesTax > 0 {
            orderSummaryStackView.addArrangedSubview(
                makeOrderSummaryRow(
                    title: fees?.salesTaxName?.isEmpty == false ? (fees?.salesTaxName ?? "Sales Tax") : "Sales Tax",
                    value: "$\(salesTax.decimalFormat(true))"
                )
            )
        }

        if processingFee > 0 {
            orderSummaryStackView.addArrangedSubview(
                makeOrderSummaryRow(
                    title: "Processing Fee",
                    value: "$\(processingFee.decimalFormat(true))"
                )
            )
        }

        if customFee > 0 {
            orderSummaryStackView.addArrangedSubview(
                makeOrderSummaryRow(
                    title: fees?.customFeeName?.isEmpty == false ? (fees?.customFeeName ?? "Fee") : "Fee",
                    value: "$\(customFee.decimalFormat(true))"
                )
            )
        }

        fees?.customFees?.forEach { fee in
            let amount = fee.amount ?? fee.fee ?? 0
            guard amount > 0 else { return }
            orderSummaryStackView.addArrangedSubview(
                makeOrderSummaryRow(
                    title: fee.name,
                    value: "$\(amount.decimalFormat(true))"
                )
            )
        }

        fees?.additionalFees?.forEach { fee in
            let amount = fee.amount ?? fee.fee ?? 0
            guard amount > 0 else { return }
            orderSummaryStackView.addArrangedSubview(
                makeOrderSummaryRow(
                    title: fee.name,
                    value: "$\(amount.decimalFormat(true))"
                )
            )
        }

        orderSummaryStackView.addArrangedSubview(
            makeOrderSummaryRow(
                title: "Total",
                value: total <= 0 ? "Free" : "$\(total.decimalFormat(true))",
                isTotal: true
            )
        )
    }

    private func makeOrderSummaryRow(title: String, value: String, isTotal: Bool = false) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = isTotal ? Constant.Font.geistSemiBold(size: 15) : Constant.Font.geistMedium(size: 14)
        titleLabel.textColor = isTotal ? .white : UIColor.white.withAlphaComponent(0.76)
        titleLabel.numberOfLines = 0

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = isTotal ? Constant.Font.geistSemiBold(size: 15) : Constant.Font.geistMedium(size: 14)
        valueLabel.textColor = isTotal ? .white : UIColor.white.withAlphaComponent(0.76)
        valueLabel.textAlignment = .right
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)
        return row
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }

    private func updateProgressDots() {
        for (index, dot) in dotViews.enumerated() {
            UIView.animate(withDuration: 0.2) {
                dot.backgroundColor = index == self.currentPage
                    ? .white
                    : UIColor.white.withAlphaComponent(0.25)
            }
        }
    }

    private func getBooking(id: String) {
        setQRLoading(true)

        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.setQRLoading(false)
                guard isSuccess, let booking else {
                    self.updateFAndQAvailability()
                    return
                }

                self.didFetchFullBookingDetail = true
                self.applyBooking(booking)
            }
        }
    }

    private func refreshFullBookingDetailsIfNeeded(id: String) {
        guard !didFetchFullBookingDetail, !id.isEmpty else { return }
        didFetchFullBookingDetail = true

        paymentService.fetchBookingDetail(bookingId: id) { [weak self] isSuccess, _, fetchedBooking in
            guard let self, isSuccess, let fetchedBooking else { return }
            DispatchQueue.main.async {
                self.applyBooking(fetchedBooking)
            }
        }
    }

    private func getEventFAQs() {
        guard let eventId = booking?.event?.uniqueId, !eventId.isEmpty else {
            updateFAndQAvailability()
            return
        }

        eventService.fetchEventFAQs(eventId: eventId) { [weak self] isSuccess, _, faqs, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if isSuccess {
                    self.fandQItems = (faqs ?? [])
                        .filter { $0.isDeleted != true }
                        .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
                } else {
                    self.fandQItems = []
                }

                self.expandedFandQIndex = nil
                self.isFAndQExpanded = false
                self.fandQtableView.reloadData()
                self.updateFAndQAvailability()
            }
        }
    }

    // MARK: - Table Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FAQsTableViewCell.nib, forCellReuseIdentifier: FAQsTableViewCell.identifier)
        configureFAQTable(tableView)

        fandQtableView.delegate = self
        fandQtableView.dataSource = self
        fandQtableView.register(FAQsTableViewCell.nib, forCellReuseIdentifier: FAQsTableViewCell.identifier)
        configureFAQTable(fandQtableView)
    }

    private func configureFAQTable(_ tableView: UITableView) {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.contentInset = .zero
        tableView.sectionHeaderHeight = .leastNormalMagnitude
        tableView.sectionFooterHeight = .leastNormalMagnitude
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    private func updateFAndQSection(animated: Bool) {
        fandQtableHiddenView.isHidden = !isFAndQExpanded

        let angle: CGFloat = isFAndQExpanded ? 0 : .pi
        let updates = {
            self.fAndQDropDownImage.transform = CGAffineTransform(rotationAngle: angle)
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }

    private func updateFAndQAvailability() {
        let hasFAQs = !fandQItems.isEmpty
        fandQtableHiddenView.superview?.superview?.isHidden = !hasFAQs
        if !hasFAQs {
            isFAndQExpanded = false
            fandQtableHiddenView.isHidden = true
            fandQtableViewHeight.constant = 0
        }
        updateFAndQSection(animated: false)
    }

    private func accountNameText() -> String {
        let first = UserDefault.shared.user?.firstName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = UserDefault.shared.user?.lastName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Guest" : name
    }

    private func eventHeaderTimeText() -> String {
        guard let event = booking?.event else { return "" }

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customText
        }

        let timezone = booking?.venueObject?.useTimezone
            ?? booking?.event?.venue?.useTimezone
            ?? booking?.event?.venue?.timezone
            ?? ""
        let dateText = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .EEEMMMD,
            customTimeZone: timezone
        )
        let startTime = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .hmma,
            customTimeZone: timezone
        )

        return "\(dateText) at \(startTime)"
    }

    private func eventDateTimeText() -> String {
        guard let event = booking?.event else { return "" }

        if let customText = event.openTimeCustomText,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customText
        }

        let timezone = booking?.venueObject?.useTimezone
            ?? booking?.event?.venue?.useTimezone
            ?? booking?.event?.venue?.timezone
            ?? ""
        let dateText = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .EEEMMMD,
            customTimeZone: timezone
        )
        let startTime = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .hmma,
            customTimeZone: timezone
        )

        return "\(dateText) at \(startTime)"
    }

    private func purchaseTimeText() -> String {
        guard let booking else { return "" }
        let timezone = booking.venueObject?.useTimezone
            ?? booking.event?.venue?.useTimezone
            ?? booking.event?.venue?.timezone
            ?? ""
        let purchasedAt = booking.createdAt.convertDateFormat(
            from: .yyyyMMddTHHmmssSSSz,
            to: .MMDDYYYYHMMA,
            isUTC: true,
            customTimeZone: timezone
        )
        return "Purchased at \(purchasedAt)"
    }

    private func backupCodeText() -> String {
        let venueBookingCode = (booking?.venueObject?.bookingCode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard venueBookingCode.isEmpty else { return venueBookingCode }

        let rawCode = booking?.id.prefix(8).uppercased() ?? ""
        return rawCode.isEmpty ? "" : "#\(rawCode)"
    }

    private func eventQRCodePayload(for bookingID: String) -> String {
        """
        {
            "id": "\(bookingID)",
            "type": "BOOKING"
        }
        """
    }

    private func ticketDisplayName(_ ticket: BookingHasItem) -> String {
        let customName = ticket.ticketCustomName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !customName.isEmpty {
            return customName
        }

        return ticket.ticketName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (ticket.ticketName ?? "")
            : "Ticket"
    }

    private func venueLogoURL() -> String? {
        let key = booking?.venueObject?.logo?.key
            ?? booking?.event?.venue?.logo?.key
            ?? ""
        guard !key.isEmpty else { return nil }
        return key.imageURL
    }

    private func eventStartDate() -> Date? {
        guard let value = booking?.event?.startDateTime else { return nil }
        return parseEventDate(value)
    }

    private func eventEndDate() -> Date? {
        guard let value = booking?.event?.endDateTime else { return nil }
        return parseEventDate(value)
    }

    private func parseEventDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.yyyyMMddHHmmss.rawValue
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: value)
    }

    private func eventCoordinate() -> CLLocationCoordinate2D? {
        if let customVenue = booking?.event?.customVenue,
           let latitude = customVenue.latitude,
           let longitude = customVenue.longitude,
           latitude != 0 || longitude != 0 {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        if let venue = booking?.venueObject,
           venue.latitude != 0 || venue.longitude != 0 {
            return CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude)
        }

        if let venue = booking?.event?.venue,
           venue.latitude != 0 || venue.longitude != 0 {
            return CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude)
        }

        return nil
    }

    private func eventLocationName() -> String {
        booking?.event?.customVenue?.name
            ?? booking?.venueObject?.name
            ?? booking?.event?.venue?.name
            ?? "Venue"
    }

    private func presentAddPKPass(_ pass: PKPass) {
        guard let vc = PKAddPassesViewController(pass: pass) else { return }
        vc.delegate = self
        present(vc, animated: true)
    }

    @objc private func onClickViewEvent() {
        AppHaptic.cardOpen()
        openEventDetails()
    }

    @objc private func onClickAddToCalendar() {
        guard let event = booking?.event,
              let startDate = eventStartDate() else {
            AppHaptic.warning()
            showTicketToast("Event date not available")
            return
        }

        let saveEvent: () -> Void = { [weak self] in
            guard let self else { return }
            guard let calendar = self.eventStore.defaultCalendarForNewEvents else {
                AppHaptic.error()
                self.showTicketToast("No writable Calendar found")
                return
            }

            let calendarEvent = EKEvent(eventStore: self.eventStore)
            calendarEvent.title = event.title
            calendarEvent.startDate = startDate
            calendarEvent.endDate = self.eventEndDate() ?? Calendar.current.date(byAdding: .hour, value: 3, to: startDate) ?? startDate
            calendarEvent.location = self.eventLocationName()
            calendarEvent.calendar = calendar

            do {
                try self.eventStore.save(calendarEvent, span: .thisEvent)
                AppHaptic.success()
                self.showTicketToast("Added to Calendar")
            } catch {
                AppHaptic.error()
                self.showTicketToast("Unable to add event to Calendar")
            }
        }

        if #available(iOS 17.0, *) {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .fullAccess, .writeOnly:
                saveEvent()
            case .notDetermined:
                eventStore.requestFullAccessToEvents { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            saveEvent()
                        } else {
                            AppHaptic.error()
                            self.showTicketToast("Calendar access denied")
                        }
                    }
                }
            default:
                AppHaptic.error()
                showTicketToast("Please allow Calendar access in Settings")
            }
        } else {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .authorized:
                saveEvent()
            case .notDetermined:
                eventStore.requestAccess(to: .event) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            saveEvent()
                        } else {
                            AppHaptic.error()
                            self.showTicketToast("Calendar access denied")
                        }
                    }
                }
            default:
                AppHaptic.error()
                showTicketToast("Please allow Calendar access in Settings")
            }
        }
    }

    @objc private func onClickAddToWallet() {
        guard let bookingId = booking?.id, !bookingId.isEmpty,
              let url = URL(string: APIBuilder.eventAppleWallet(bookingId)) else {
            AppHaptic.error()
            Alert.showAlertSheet(style: .alert, title: "Booking not found", message: "")
            return
        }

        AppHaptic.primaryAction()
        let passLibrary = PKPassLibrary()
        if let pass {
            if passLibrary.containsPass(pass) {
                AppHaptic.warning()
                Alert.showToast("Ticket already added to Wallet", vc: self)
            } else {
                presentAddPKPass(pass)
            }
            return
        }

        URLSession.shared.fetchData(at: url) { [weak self] data, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                guard let data else {
                    AppHaptic.error()
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                    return
                }

                do {
                    let pass = try PKPass(data: data)
                    self.pass = pass
                    self.presentAddPKPass(pass)
                } catch {
                    AppHaptic.error()
                    Alert.showAlertSheet(style: .alert, title: "Invalid ticket data", message: "")
                }
            }
        }
    }

    @objc private func onClickGetDirections() {
        guard let coordinate = eventCoordinate() else {
            AppHaptic.warning()
            Alert.showToast("Venue location not available")
            return
        }

        AppHaptic.navigation()
        let mapItem = MKMapItem(
            placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        )
        mapItem.name = eventLocationName()
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    @objc private func onTapQRCodeView() {
        guard !isShowingBackupCode else { return }

        AppHaptic.selectionChanged()
        isShowingBackupCode = true
        qrFlipWorkItem?.cancel()
        flipQRCode(showCode: true)

        let workItem = DispatchWorkItem { [weak self] in
            self?.flipQRCode(showCode: false)
        }
        qrFlipWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func flipQRCode(showCode: Bool) {
        UIView.transition(
            with: qrFlipBoxView,
            duration: 0.65,
            options: [.transitionFlipFromRight, .allowUserInteraction]
        ) {
            self.qrImageView.isHidden = showCode
            self.qrLogoContainerView.isHidden = showCode
            self.qrCodeLabel.isHidden = !showCode
        } completion: { [weak self] _ in
            guard let self else { return }
            if !showCode {
                self.isShowingBackupCode = false
            }
        }
    }

    @IBAction func onClickFAndQBtn(_ sender: Any) {
        guard !fandQItems.isEmpty else { return }
        AppHaptic.selectionChanged()
        isFAndQExpanded.toggle()
        updateFAndQSection(animated: true)
    }
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        AppHaptic.navigation()
        switch presentationMode {
        case .modal:
            dismiss(animated: true)

        case .pushedFromPurchase:
            returnToEventDetails()
        }
    }

    private func returnToEventDetails() {
        guard let navigationController else {
            dismiss(animated: true)
            return
        }

        if let eventDetailsVC = navigationController.viewControllers
            .last(where: { $0 is EventDetailsVC }) {
            navigationController.popToViewController(
                eventDetailsVC,
                animated: true
            )
            return
        }

        showEventDetailsFromBooking(
            in: navigationController,
            animated: true
        )
    }
}

// MARK: - WebSocketCallBackDelegate
extension EventQRTicketVC: WebSocketCallBackDelegate {
    func checkInTicket(checkIndata: [BookingHasCheckIn], bookingId: String) {
        guard booking?.id == bookingId else { return }
        DispatchQueue.main.async {
            self.booking?.bookingHasCheckIn = checkIndata
            self.renderTicketRows()
        }
    }

    func unCheckTicket(checkIndata: [BookingHasCheckIn], bookingId: String) {
        guard booking?.id == bookingId else { return }
        DispatchQueue.main.async {
            self.booking?.bookingHasCheckIn = checkIndata
            self.renderTicketRows()
        }
    }
}

// MARK: - FSPagerView
extension EventQRTicketVC: FSPagerViewDataSource, FSPagerViewDelegate {

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        tickets.count
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(
            withReuseIdentifier: EventQRPagerViewCell.identifier,
            at: index
        ) as! EventQRPagerViewCell

        cell.configure(with: tickets[index], index: index, total: tickets.count)
        return cell
    }

    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        guard currentPage != pagerView.currentIndex else { return }
        currentPage = pagerView.currentIndex
        AppHaptic.selectionChanged()
    }

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        AppHaptic.selectionChanged()
        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
    }
}

// MARK: - UITableView
extension EventQRTicketVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView === self.tableView ? faqs.count : fandQItems.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as! FAQsTableViewCell

        let isFandQ = tableView === fandQtableView
        let item = isFandQ
            ? (
                question: fandQItems[indexPath.row].title ?? "",
                answer: fandQItems[indexPath.row].content?.fromHTML ?? ""
            )
            : faqs[indexPath.row]
        let expandedIndex = isFandQ ? expandedFandQIndex : expandedFAQIndex

        cell.selectionStyle = .none
        cell.configure(
            title: item.question,
            content: item.answer,
            isExpanded: expandedIndex == indexPath.row,
            answerBottomPadding: isFandQ ? nil : 12
        )

        cell.onToggle = { [weak self] in
            guard let self = self else { return }
            
            if indexPath.row == 0 {
                openEventDetails()
                return
            }

            if isFandQ {
                let previous = self.expandedFandQIndex
                self.expandedFandQIndex = self.expandedFandQIndex == indexPath.row ? nil : indexPath.row

                var indexPaths: [IndexPath] = [indexPath]

                if let previous, previous != indexPath.row {
                    indexPaths.append(IndexPath(row: previous, section: 0))
                }

                UIView.performWithoutAnimation {
                    self.fandQtableView.reloadRows(at: indexPaths, with: .none)
                }

                self.fandQtableView.beginUpdates()
                self.fandQtableView.endUpdates()
            } else {
                let previous = self.expandedFAQIndex
                self.expandedFAQIndex = self.expandedFAQIndex == indexPath.row ? nil : indexPath.row

                var indexPaths: [IndexPath] = [indexPath]

                if let previous, previous != indexPath.row {
                    indexPaths.append(IndexPath(row: previous, section: 0))
                }

                UIView.performWithoutAnimation {
                    self.tableView.reloadRows(at: indexPaths, with: .none)
                }

                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        if indexPath.row == 0 {
            AppHaptic.cardOpen()
            openEventDetails()
            return
        }
        
        if tableView === fandQtableView {
            AppHaptic.selectionChanged()
            expandedFandQIndex = expandedFandQIndex == indexPath.row ? nil : indexPath.row
            fandQtableView.reloadData()
        } else {
            AppHaptic.selectionChanged()
            expandedFAQIndex = expandedFAQIndex == indexPath.row ? nil : indexPath.row
            self.tableView.reloadData()
        }
    }
}

extension EventQRTicketVC: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self,
                  let pass = self.pass,
                  PKPassLibrary().containsPass(pass) else {
                return
            }
            AppHaptic.success()
            Alert.showToast("Ticket added to Wallet", vc: self)
        }
    }
}

private extension EventQRTicketVC {
    func openEventDetails() {
        
        var event = self.booking?.event
        guard event != nil else {
            Alert.showToast("Event details not available")
            return
        }
        event?.venue = self.booking?.venueObject

        if let eventDetailsVC = navigationController?.viewControllers
            .last(where: { $0 is EventDetailsVC }) {
            navigationController?.popToViewController(
                eventDetailsVC,
                animated: true
            )
            return
        }

        if let navigationController {
            showEventDetailsFromBooking(
                in: navigationController,
                animated: true
            )
            return
        }
        
        Navigate.eventDetailsVC(
            self,
            event: event
        )
    }

    func showEventDetailsFromBooking(
        in navigationController: UINavigationController,
        animated: Bool
    ) {
        var event = booking?.event ?? sourceEvent

        guard event != nil else {
            navigationController.popViewController(animated: animated)
            return
        }

        if let venue = booking?.venueObject {
            event?.venue = venue
        }

        let vc = EventDetailsVC(nibName: "EventDetailsVC", bundle: nil)
        vc.event = event
        vc.venueDetails = event?.venue

        var stack = navigationController.viewControllers
        if let currentIndex = stack.firstIndex(of: self) {
            stack = Array(stack.prefix(currentIndex))
        }

        stack.removeAll {
            $0 is OrderListViewController ||
            $0 is TicketCheckoutVC ||
            $0 is TicketConfirmationVC
        }

        stack.append(vc)
        navigationController.setViewControllers(
            stack,
            animated: animated
        )
    }
}

private final class EventQRLoadingShimmerView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLine = ShimmerViewV3()
    private let subtitleLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let timeLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let qrCard = UIView()
    private let accountLine = ShimmerViewV3()
    private let purchaseLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let qrSquare = ShimmerViewV3()
    private let helperLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let ticketLineOne = ShimmerViewV3()
    private let ticketCountOne = ShimmerViewV3(frame: .zero, lighter: true)
    private let ticketLineTwo = ShimmerViewV3()
    private let ticketCountTwo = ShimmerViewV3(frame: .zero, lighter: true)
    private let walletLine = ShimmerViewV3()
    private let actionLine = ShimmerViewV3(frame: .zero, lighter: true)

    private var shimmerViews: [ShimmerViewV3] {
        [
            titleLine,
            subtitleLine,
            timeLine,
            accountLine,
            purchaseLine,
            qrSquare,
            helperLine,
            ticketLineOne,
            ticketCountOne,
            ticketLineTwo,
            ticketCountTwo,
            walletLine,
            actionLine
        ]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func show(animated: Bool) {
        isHidden = false
        shimmerViews.forEach { $0.startShimmer() }

        guard animated else {
            alpha = 1
            return
        }

        alpha = 0
        UIView.animate(withDuration: 0.18) {
            self.alpha = 1
        }
    }

    func hide(animated: Bool) {
        let completion: (Bool) -> Void = { _ in
            self.shimmerViews.forEach { $0.stopShimmer() }
            self.isHidden = true
            self.alpha = 1
        }

        guard animated else {
            completion(true)
            return
        }

        UIView.animate(
            withDuration: 0.22,
            animations: {
                self.alpha = 0
            },
            completion: completion
        )
    }

    private func setupUI() {
        isHidden = true
        alpha = 0
        backgroundColor = UIColor.black.withAlphaComponent(0.72)
        isUserInteractionEnabled = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        qrCard.translatesAutoresizingMaskIntoConstraints = false
        qrCard.backgroundColor = UIColor.white.withAlphaComponent(0.075)
        qrCard.layer.cornerRadius = 22
        qrCard.layer.borderWidth = 1
        qrCard.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        qrCard.clipsToBounds = true
        addSubview(qrCard)

        [
            titleLine,
            subtitleLine,
            timeLine,
            walletLine,
            actionLine
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 8
            addSubview($0)
        }

        [
            accountLine,
            purchaseLine,
            qrSquare,
            helperLine,
            ticketLineOne,
            ticketCountOne,
            ticketLineTwo,
            ticketCountTwo
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 8
            qrCard.addSubview($0)
        }

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLine.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 42),
            titleLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.62),
            titleLine.heightAnchor.constraint(equalToConstant: 22),

            subtitleLine.topAnchor.constraint(equalTo: titleLine.bottomAnchor, constant: 12),
            subtitleLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.38),
            subtitleLine.heightAnchor.constraint(equalToConstant: 14),

            timeLine.topAnchor.constraint(equalTo: subtitleLine.bottomAnchor, constant: 10),
            timeLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.46),
            timeLine.heightAnchor.constraint(equalToConstant: 14),

            qrCard.topAnchor.constraint(equalTo: timeLine.bottomAnchor, constant: 28),
            qrCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            qrCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            qrCard.heightAnchor.constraint(equalToConstant: 452),

            accountLine.topAnchor.constraint(equalTo: qrCard.topAnchor, constant: 24),
            accountLine.centerXAnchor.constraint(equalTo: qrCard.centerXAnchor),
            accountLine.widthAnchor.constraint(equalTo: qrCard.widthAnchor, multiplier: 0.42),
            accountLine.heightAnchor.constraint(equalToConstant: 18),

            purchaseLine.topAnchor.constraint(equalTo: accountLine.bottomAnchor, constant: 12),
            purchaseLine.centerXAnchor.constraint(equalTo: qrCard.centerXAnchor),
            purchaseLine.widthAnchor.constraint(equalTo: qrCard.widthAnchor, multiplier: 0.60),
            purchaseLine.heightAnchor.constraint(equalToConstant: 14),

            qrSquare.topAnchor.constraint(equalTo: purchaseLine.bottomAnchor, constant: 24),
            qrSquare.centerXAnchor.constraint(equalTo: qrCard.centerXAnchor),
            qrSquare.widthAnchor.constraint(equalToConstant: 214),
            qrSquare.heightAnchor.constraint(equalTo: qrSquare.widthAnchor),

            helperLine.topAnchor.constraint(equalTo: qrSquare.bottomAnchor, constant: 22),
            helperLine.centerXAnchor.constraint(equalTo: qrCard.centerXAnchor),
            helperLine.widthAnchor.constraint(equalTo: qrCard.widthAnchor, multiplier: 0.56),
            helperLine.heightAnchor.constraint(equalToConstant: 14),

            ticketLineOne.topAnchor.constraint(equalTo: helperLine.bottomAnchor, constant: 28),
            ticketLineOne.leadingAnchor.constraint(equalTo: qrCard.leadingAnchor, constant: 26),
            ticketLineOne.widthAnchor.constraint(equalTo: qrCard.widthAnchor, multiplier: 0.46),
            ticketLineOne.heightAnchor.constraint(equalToConstant: 16),

            ticketCountOne.centerYAnchor.constraint(equalTo: ticketLineOne.centerYAnchor),
            ticketCountOne.trailingAnchor.constraint(equalTo: qrCard.trailingAnchor, constant: -26),
            ticketCountOne.widthAnchor.constraint(equalToConstant: 38),
            ticketCountOne.heightAnchor.constraint(equalToConstant: 16),

            ticketLineTwo.topAnchor.constraint(equalTo: ticketLineOne.bottomAnchor, constant: 24),
            ticketLineTwo.leadingAnchor.constraint(equalTo: ticketLineOne.leadingAnchor),
            ticketLineTwo.widthAnchor.constraint(equalTo: qrCard.widthAnchor, multiplier: 0.36),
            ticketLineTwo.heightAnchor.constraint(equalToConstant: 16),

            ticketCountTwo.centerYAnchor.constraint(equalTo: ticketLineTwo.centerYAnchor),
            ticketCountTwo.trailingAnchor.constraint(equalTo: ticketCountOne.trailingAnchor),
            ticketCountTwo.widthAnchor.constraint(equalToConstant: 32),
            ticketCountTwo.heightAnchor.constraint(equalToConstant: 16),

            walletLine.topAnchor.constraint(equalTo: qrCard.bottomAnchor, constant: 22),
            walletLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            walletLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            walletLine.heightAnchor.constraint(equalToConstant: 50),

            actionLine.topAnchor.constraint(equalTo: walletLine.bottomAnchor, constant: 14),
            actionLine.leadingAnchor.constraint(equalTo: walletLine.leadingAnchor),
            actionLine.trailingAnchor.constraint(equalTo: walletLine.trailingAnchor),
            actionLine.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}

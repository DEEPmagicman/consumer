import UIKit
import PassKit
import FSPagerView

class EventQRTicketVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var progressBarView: UIView!
    @IBOutlet weak var pagerView: FSPagerView!
    @IBOutlet weak var fandQtableView: UITableView!
    @IBOutlet weak var fandQtableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var fAndQDropDownImage: UIImageView!
    @IBOutlet weak var fandQtableHiddenView: UIView!
    @IBOutlet weak var eventTitle: UILabel!
    
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
    var type: PaymentIntentType = .singleTickedEvent

    private var pass: PKPass?
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var isUpdatingTableHeight = false
    private var pagerViewConfigured = false
    private let posterHeaderView = EventPosterHeaderView()
    private let eventService = EventService()
    private let loadingShimmerView = EventQRLoadingShimmerView()
    private var hasSetupPosterBackground = false

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
        setupPagerView()
        setupTableView()
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

    private func setQRLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.view.bringSubviewToFront(self.loadingShimmerView)
                self.loadingShimmerView.show()
            } else {
                self.loadingShimmerView.hide()
            }
        }
    }

    private func refreshPosterBackground() {
        let imageURLString = (booking?.event?.flyer?.key ?? "").imageURL
        posterHeaderView.loadImage(from: imageURLString)
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

    private func setupTickets() {
        guard let booking else { return }

        tickets.removeAll()

        booking.uniqueTickets.forEach { ticket in
            let qrString = """
            {
                "id": "\(booking.id)",
                "type": "BOOKING"
            }
            """

            tickets.append(
                EventTicketQR(
                    ticketName: ticket.ticketName ?? "",
                    qrString: qrString
                )
            )
        }

        setupProgressDots(count: tickets.count)
    }

    private func loadBookingData() {
        tableView.isHidden = true
        fandQtableHiddenView.superview?.superview?.isHidden = true
        setupProgressDots(count: 0)

        if let booking {
            applyBooking(booking)
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
        self.eventTitle.text = booking.event?.title
        if bookingId.isEmpty {
            bookingId = booking.id
        }

        configureEventRows()
        refreshPosterBackground()
        setupTickets()
        getEventFAQs()

        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.pagerView.reloadData()
            self.view.layoutIfNeeded()
        }
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
        tableView.isHidden = false
    }

    // MARK: - Progress Dots
    private func setupProgressDots(count: Int) {
        progressBarView.subviews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        progressBarView.isHidden = count <= 1

        guard count > 1 else { return }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        progressBarView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: progressBarView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: progressBarView.centerYAnchor)
        ])

        for _ in 0..<count {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 5

            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 10),
                dot.heightAnchor.constraint(equalToConstant: 10)
            ])

            stackView.addArrangedSubview(dot)
            dotViews.append(dot)
        }

        updateProgressDots()
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

        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.setQRLoading(false)
                guard isSuccess, let booking else {
                    self.updateFAndQAvailability()
                    return
                }

                self.applyBooking(booking)
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
    
    @IBAction func onClickFAndQBtn(_ sender: Any) {
        guard !fandQItems.isEmpty else { return }
        isFAndQExpanded.toggle()
        updateFAndQSection(animated: true)
    }
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        returnToDiscoverScreen()
    }

    private func returnToDiscoverScreen() {
        let presenter = presentingViewController

        dismiss(animated: false) {
            if let navigationController = presenter as? UINavigationController {
                navigationController.tabBarController?.selectedIndex = 0
                navigationController.popToRootViewController(animated: false)
            } else if let navigationController = presenter?.navigationController {
                navigationController.tabBarController?.selectedIndex = 0
                navigationController.popToRootViewController(animated: false)
            } else if let tabBarController = presenter?.tabBarController {
                tabBarController.selectedIndex = 0
            }
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
    }

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
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
            openEventDetails()
            return
        }
        
        if tableView === fandQtableView {
            expandedFandQIndex = expandedFandQIndex == indexPath.row ? nil : indexPath.row
            fandQtableView.reloadData()
        } else {
            expandedFAQIndex = expandedFAQIndex == indexPath.row ? nil : indexPath.row
            self.tableView.reloadData()
        }
    }
}

private extension EventQRTicketVC {
    func openEventDetails() {
        
        var event = self.booking?.event
        event?.venue = self.booking?.venueObject
        
        Navigate.eventDetailsVC(
            self,
            event: event
        )
    }
}

private final class EventQRLoadingShimmerView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let posterBlock = ShimmerViewV3()
    private let titleLine = ShimmerViewV3()
    private let subtitleLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let qrCard = UIView()
    private let qrSquare = ShimmerViewV3()
    private let qrLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let pillLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let detailLineOne = ShimmerViewV3()
    private let detailLineTwo = ShimmerViewV3(frame: .zero, lighter: true)

    private var shimmerViews: [ShimmerViewV3] {
        [
            posterBlock,
            titleLine,
            subtitleLine,
            qrSquare,
            qrLine,
            pillLine,
            detailLineOne,
            detailLineTwo
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

    func show() {
        isHidden = false
        shimmerViews.forEach { $0.startShimmer() }
        alpha = 0
        UIView.animate(withDuration: 0.18) {
            self.alpha = 1
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.22, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.shimmerViews.forEach { $0.stopShimmer() }
            self.isHidden = true
            self.alpha = 1
        })
    }

    private func setupUI() {
        isHidden = true
        alpha = 0
        backgroundColor = UIColor.black.withAlphaComponent(0.58)
        isUserInteractionEnabled = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        qrCard.translatesAutoresizingMaskIntoConstraints = false
        qrCard.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        qrCard.layer.cornerRadius = 24
        qrCard.layer.borderWidth = 1
        qrCard.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        qrCard.clipsToBounds = true
        addSubview(qrCard)

        [posterBlock, titleLine, subtitleLine, detailLineOne, detailLineTwo].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 8
            addSubview($0)
        }

        [qrSquare, qrLine, pillLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 10
            qrCard.addSubview($0)
        }

        posterBlock.layer.cornerRadius = 22
        qrSquare.layer.cornerRadius = 18
        pillLine.layer.cornerRadius = 18

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            posterBlock.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 112),
            posterBlock.centerXAnchor.constraint(equalTo: centerXAnchor),
            posterBlock.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.52),
            posterBlock.heightAnchor.constraint(equalTo: posterBlock.widthAnchor, multiplier: 1.15),

            titleLine.topAnchor.constraint(equalTo: posterBlock.bottomAnchor, constant: 28),
            titleLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.58),
            titleLine.heightAnchor.constraint(equalToConstant: 18),

            subtitleLine.topAnchor.constraint(equalTo: titleLine.bottomAnchor, constant: 12),
            subtitleLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.34),
            subtitleLine.heightAnchor.constraint(equalToConstant: 12),

            qrCard.topAnchor.constraint(equalTo: subtitleLine.bottomAnchor, constant: 34),
            qrCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            qrCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            qrCard.heightAnchor.constraint(equalToConstant: 176),

            qrSquare.leadingAnchor.constraint(equalTo: qrCard.leadingAnchor, constant: 22),
            qrSquare.centerYAnchor.constraint(equalTo: qrCard.centerYAnchor),
            qrSquare.widthAnchor.constraint(equalToConstant: 112),
            qrSquare.heightAnchor.constraint(equalTo: qrSquare.widthAnchor),

            qrLine.leadingAnchor.constraint(equalTo: qrSquare.trailingAnchor, constant: 22),
            qrLine.trailingAnchor.constraint(equalTo: qrCard.trailingAnchor, constant: -24),
            qrLine.topAnchor.constraint(equalTo: qrSquare.topAnchor, constant: 16),
            qrLine.heightAnchor.constraint(equalToConstant: 18),

            pillLine.leadingAnchor.constraint(equalTo: qrLine.leadingAnchor),
            pillLine.trailingAnchor.constraint(equalTo: qrLine.trailingAnchor, constant: -36),
            pillLine.bottomAnchor.constraint(equalTo: qrSquare.bottomAnchor, constant: -8),
            pillLine.heightAnchor.constraint(equalToConstant: 42),

            detailLineOne.topAnchor.constraint(equalTo: qrCard.bottomAnchor, constant: 34),
            detailLineOne.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            detailLineOne.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),
            detailLineOne.heightAnchor.constraint(equalToConstant: 14),

            detailLineTwo.topAnchor.constraint(equalTo: detailLineOne.bottomAnchor, constant: 16),
            detailLineTwo.leadingAnchor.constraint(equalTo: detailLineOne.leadingAnchor),
            detailLineTwo.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.52),
            detailLineTwo.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
}

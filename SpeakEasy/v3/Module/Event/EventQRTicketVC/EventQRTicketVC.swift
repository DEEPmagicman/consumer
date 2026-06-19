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
    private var hasSetupPosterBackground = false

    private var faqs: [(question: String, answer: String)] = [
        (
            question: "Event details.",
            answer: "View all event information including venue, date, time, and other event-related details."
        ),
        (
            question: "How to use my tickets",
            answer: "This code will be your way in. Show it upon arrival"
        )
    ]

    private var fandQItems: [EventFAQ] = []

    private var expandedFandQIndex: Int?
    private var expandedFAQIndex: Int?
    private var isFAndQExpanded = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupPosterBackground()
        setupPagerView()
        setupProgressDots(count: tickets.count)
        setupTableView()
        setupKVO()
//        setupData()
        getBooking(id: bookingId)

        tableView.register(
            UINib(nibName: "TicketDetailTVC", bundle: nil),
            forCellReuseIdentifier: "TicketDetailTVC"
        )

        ticketListHeightObservation = tableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.tableView.contentSize.height
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
        Loader.show()

        PaymentPresenter.getBooking(bookingId: id) { [weak self] isSuccess, errMsg, booking in
            Loader.hide()

            guard let self = self else { return }

            if isSuccess {
                self.booking = booking
//                self.setupData()
                self.refreshPosterBackground()
                self.setupTickets()
                self.getEventFAQs()
                self.tableView.reloadData()
                self.pagerView.reloadData()
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
        if tableView === fandQtableView {
            expandedFandQIndex = expandedFandQIndex == indexPath.row ? nil : indexPath.row
            fandQtableView.reloadData()
        } else {
            expandedFAQIndex = expandedFAQIndex == indexPath.row ? nil : indexPath.row
            self.tableView.reloadData()
        }
    }
}

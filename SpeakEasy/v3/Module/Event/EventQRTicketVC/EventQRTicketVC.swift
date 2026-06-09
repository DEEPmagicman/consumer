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

    // MARK: - Data
    var tickets: [EventTicketQR] = [
        EventTicketQR(ticketName: "General Admission", qrString: "SPEAKEASY-GA-001-2026"),
        EventTicketQR(ticketName: "VIP Access", qrString: "SPEAKEASY-VIP-002-2026"),
        EventTicketQR(ticketName: "Backstage Pass", qrString: "SPEAKEASY-BSP-003-2026")
    ]

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

    private var faqs: [(question: String, answer: String)] = [
        (
            question: "Event details.",
            answer: "View all event information including venue, date, time, and other event-related details."
        ),
        (
            question: "How to use my tickets",
            answer: "Show your QR ticket at the venue entrance for scanning and entry."
        )
    ]

    private var fandQItems: [(question: String, answer: String)] = [
        (
            question: "Can I transfer my ticket?",
            answer: "Yes, tickets can be transferred to another user via the app up to 2 hours before the event starts."
        ),
        (
            question: "What if I lose my QR code?",
            answer: "Your QR code is always available in the app under My Tickets. Simply reopen the screen to retrieve it."
        ),
        (
            question: "Is there a dress code?",
            answer: "Smart casual is recommended. The venue reserves the right to refuse entry if the dress code is not met."
        ),
        (
            question: "Can I get a refund?",
            answer: "Tickets are non-refundable within 48 hours of the event. Please contact support for exceptions."
        )
    ]

    private var expandedFandQIndex: Int?
    private var expandedFAQIndex: Int?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

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

        guard !pagerViewConfigured,
              pagerView.bounds.height > 0 else {
            return
        }

        pagerViewConfigured = true
        pagerView.itemSize = CGSize(
            width: view.bounds.width - 32,
            height: pagerView.bounds.height
        )
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
                "id": "\(booking.id ?? "")",
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
                self.setupTickets()
                self.tableView.reloadData()
                self.pagerView.reloadData()
            }
        }
    }

    // MARK: - Table Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FAQsTableViewCell.nib, forCellReuseIdentifier: FAQsTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false

        fandQtableView.delegate = self
        fandQtableView.dataSource = self
        fandQtableView.register(FAQsTableViewCell.nib, forCellReuseIdentifier: FAQsTableViewCell.identifier)
        fandQtableView.rowHeight = UITableView.automaticDimension
        fandQtableView.estimatedRowHeight = 80
        fandQtableView.separatorStyle = .none
        fandQtableView.isScrollEnabled = false
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
        let item = isFandQ ? fandQItems[indexPath.row] : faqs[indexPath.row]
        let expandedIndex = isFandQ ? expandedFandQIndex : expandedFAQIndex

        cell.questionLbl.text = item.question
        cell.ansLbl.text = item.answer
        cell.selectionStyle = .none
        cell.ansView.isHidden = expandedIndex != indexPath.row

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

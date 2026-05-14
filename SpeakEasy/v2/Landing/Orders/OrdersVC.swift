import UIKit

final class OrdersVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyTitleLbl: UILabel!
    @IBOutlet weak var emptySubTitleLbl: UILabel!
    
    private let segmentControl = SSSegmentedControl()
    
    enum OrderSegment: Int {
        case upcoming = 0
        case past = 1
    }
    
    private var selectedType: OrderSegment = .upcoming
    
    private var upcomingBookings: [Booking] = []
    private var pastBookings: [Booking] = []
    
    private var upcomingSkip = 0
    private var pastSkip = 0
    
    private var upcomingHasMany = false
    private var pastHasMany = false
    
    private var isLoading = false
    private var isInitialLoading = true
    
    private var currentBookings: [Booking] {
        switch selectedType {
        case .upcoming: return upcomingBookings
        case .past: return pastBookings
        }
    }
    
    private var currentHasMany: Bool {
        switch selectedType {
        case .upcoming: return upcomingHasMany
        case .past: return pastHasMany
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentControl()
        setupTableView()
        if UserDefault.shared.isGuest == false {
            loadCurrentSegment(reset: false)
        }
    }
    
    // MARK: - Setup
    private func setupSegmentControl() {
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)
        
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),
            tableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16)
        ])
        
        segmentControl.numberOfSegments    = 2
        segmentControl.segmentsTitle       = "Upcoming,Past"
        segmentControl.currentIndex        = 0
        segmentControl.buttonPadding       = 4
        segmentControl.backgroundColor     = UIColor.white.withAlphaComponent(0.1)
        segmentControl.currentIndexBackgroundColor = UIColor.white.withAlphaComponent(0.2)
        segmentControl.currentIndexTitleColor      = .white
        segmentControl.otherIndexTitleColor        = .lightGray
        segmentControl.layer.cornerRadius          = 18
        segmentControl.layer.borderWidth           = 0
        segmentControl.clipsToBounds               = true
        
        segmentControl.didTapSegment = { [weak self] index in
            guard let self = self else { return }
            self.selectedType = OrderSegment(rawValue: index) ?? .upcoming
            
            switch self.selectedType {
            case .upcoming:
                if !self.upcomingBookings.isEmpty {
                    self.isInitialLoading = false
                    self.tableView.reloadData()
                    self.updateEmptyState()
                } else {
                    self.loadCurrentSegment(reset: true)
                }
            case .past:
                if !self.pastBookings.isEmpty {
                    self.isInitialLoading = false
                    self.tableView.reloadData()
                    self.updateEmptyState()
                } else {
                    self.loadCurrentSegment(reset: true)
                }
            }
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(
            OrdersTableViewCell.nib,
            forCellReuseIdentifier: OrdersTableViewCell.identifier
        )
    }
    
    private func updateEmptyState() {
        let isEmpty = currentBookings.isEmpty && !isInitialLoading
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        guard isEmpty else { return }
        
        switch selectedType {
        case .upcoming:
            emptyTitleLbl.text = "No upcoming events"
            emptySubTitleLbl.text = "Keep an eye out for upcoming events!"
        case .past:
            emptyTitleLbl.text = "No past events"
            emptySubTitleLbl.text = "Your past bookings will appear here."
        }
    }
    
    private func loadCurrentSegment(reset: Bool) {
        guard !isLoading else { return }
        isLoading = true
        
        if reset {
            isInitialLoading = true
            switch selectedType {
            case .upcoming:
                upcomingSkip = 0
                upcomingHasMany = false
                upcomingBookings.removeAll()
            case .past:
                pastSkip = 0
                pastHasMany = false
                pastBookings.removeAll()
            }
            updateEmptyState()
            tableView.reloadData()
        }
        
        switch selectedType {
            
        case .upcoming:
            PaymentPresenter.getUpcomingTicket(skip: upcomingSkip) { [weak self] isSuccess, errMsg, bookings, hasMany in
                guard let self = self else { return }
                self.isLoading = false
                self.isInitialLoading = false
                
                if isSuccess {
                    self.upcomingBookings = reset ? bookings : self.upcomingBookings + bookings
                    self.upcomingHasMany = hasMany
                    if hasMany { self.upcomingSkip = self.upcomingBookings.count }
                } else {
                    if reset { self.upcomingBookings.removeAll() }
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
                
                if self.selectedType == .upcoming {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
            
        case .past:
            PaymentPresenter.getPastTicket(skip: pastSkip) { [weak self] isSuccess, errMsg, bookings, hasMany in
                guard let self = self else { return }
                self.isLoading = false
                self.isInitialLoading = false
                
                if isSuccess {
                    self.pastBookings = reset ? bookings : self.pastBookings + bookings
                    self.pastHasMany = hasMany
                    if hasMany { self.pastSkip = self.pastBookings.count }
                } else {
                    if reset { self.pastBookings.removeAll() }
                    Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
                }
                
                if self.selectedType == .past {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }
}

// MARK: - TableView
extension OrdersVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isInitialLoading {
            emptyView.isHidden = true
            return 5
        }
        return currentBookings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrdersTableViewCell = tableView.dequeue(
            withIdentifier: OrdersTableViewCell.identifier,
            for: indexPath
        )
        cell.selectionStyle = .none
        if isInitialLoading {
            cell.showShimmer()
        } else {
            let booking = currentBookings[indexPath.row]
            cell.configure(with: booking, isUpcoming: selectedType == .upcoming)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isInitialLoading else { return }
        let booking = currentBookings[indexPath.row]
        
        if booking.eventId != nil {
            Navigate.to.showQRCode(self, booking: booking, bookingId: booking.id, type: .singleTickedEvent)
        } else if booking.inviteLink != nil {
            Navigate.to.showQRCode(self, booking: booking, bookingId: booking.id, type: .appClip)
        } else {
            Navigate.to.scanQR(self, bookingId: booking.id, booking: booking, addOnsBookingId: "")
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isInitialLoading else { return }
        guard !isLoading else { return }
        guard currentHasMany else { return }
        if indexPath.row == currentBookings.count - 1 {
            loadCurrentSegment(reset: false)
        }
    }
}


import UIKit

class SSSegmentedControl: UIView {
    
    // MARK: - Properties
    var stackView: UIStackView = UIStackView()
    var buttonsCollection: [UIButton] = []
    var currentIndexView: UIView = UIView(frame: .zero)
    
    var buttonPadding: CGFloat = 5
    var stackViewSpacing: CGFloat = 0
    
    // MARK: - Callback
    var didTapSegment: ((Int) -> ())?
    
    // MARK: - Inspectable Properties
    @IBInspectable var currentIndex: Int = 0 {
        didSet { setCurrentIndex() }
    }
    
    @IBInspectable var currentIndexTitleColor: UIColor = .white {
        didSet { updateTextColors() }
    }
    
    @IBInspectable var currentIndexBackgroundColor: UIColor = .systemTeal {
        didSet { setCurrentViewBackgroundColor() }
    }
    
    @IBInspectable var otherIndexTitleColor: UIColor = .gray {
        didSet { updateTextColors() }
    }
    
    // ✅ Removed @IBInspectable — already in UIView extension
    var buttonCornerRadius: CGFloat = 10 {
        didSet { setButtonCornerRadius() }
    }
    
    @IBInspectable var numberOfSegments: Int = 2 {
        didSet { addSegments() }
    }
    
    @IBInspectable var segmentsTitle: String = "Segment 1,Segment 2" {
        didSet { updateSegmentTitles() }
    }
    
    // MARK: - Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setCurrentIndex(animated: false)
    }
    
    // MARK: - Functions
    private func commonInit() {
        backgroundColor = .clear
        setupStackView()
        addSegments()
        setCurrentIndexView()
        setCurrentIndex(animated: false)
        setButtonCornerRadius()
    }
    
    private func setCurrentIndexView() {
        setCurrentViewBackgroundColor()
        addSubview(currentIndexView)
        sendSubviewToBack(currentIndexView)
    }
    
    private func setCurrentIndex(animated: Bool = true) {
        stackView.subviews.enumerated().forEach { (index, view) in
            let button = view as? UIButton
            
            if index == currentIndex {
                let buttonWidth = (frame.width - (buttonPadding * 2)) / CGFloat(numberOfSegments)
                
                if animated {
                    UIView.animate(withDuration: 0.3) {
                        self.currentIndexView.frame = CGRect(
                            x: self.buttonPadding + (buttonWidth * CGFloat(index)),
                            y: self.buttonPadding,
                            width: buttonWidth,
                            height: self.frame.height - (self.buttonPadding * 2)
                        )
                        // ✅ corner radius updated on animation
                        self.currentIndexView.layer.cornerRadius = self.currentIndexView.frame.height / 2
                    }
                } else {
                    self.currentIndexView.frame = CGRect(
                        x: self.buttonPadding + (buttonWidth * CGFloat(index)),
                        y: self.buttonPadding,
                        width: buttonWidth,
                        height: self.frame.height - (self.buttonPadding * 2)
                    )
                    self.currentIndexView.layer.cornerRadius = self.currentIndexView.frame.height / 2
                }
                
                button?.setTitleColor(currentIndexTitleColor, for: .normal)
            } else {
                button?.setTitleColor(otherIndexTitleColor, for: .normal)
            }
        }
    }
    
    private func updateTextColors() {
        stackView.subviews.enumerated().forEach { (index, view) in
            let button = view as? UIButton
            button?.setTitleColor(index == currentIndex ? currentIndexTitleColor : otherIndexTitleColor, for: .normal)
        }
    }
    
    private func setCurrentViewBackgroundColor() {
        currentIndexView.backgroundColor = currentIndexBackgroundColor
    }
    
    private func setupStackView() {
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = stackViewSpacing
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: buttonPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -buttonPadding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: buttonPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -buttonPadding)
        ])
    }
    
    private func addSegments() {
        buttonsCollection.removeAll()
        stackView.subviews.forEach { ($0 as? UIButton)?.removeFromSuperview() }
        
        let titles = segmentsTitle.split(separator: ",")
        
        for index in 0 ..< numberOfSegments {
            let button = UIButton()
            button.tag = index
            button.setTitle(titles.indices.contains(index) ? String(titles[index]) : "<Segment>", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttonsCollection.append(button)
        }
    }
    
    private func updateSegmentTitles() {
        let titles = segmentsTitle.split(separator: ",")
        stackView.subviews.enumerated().forEach { (index, view) in
            (view as? UIButton)?.setTitle(titles.indices.contains(index) ? String(titles[index]) : "<Segment>", for: .normal)
        }
    }
    
    private func setButtonCornerRadius() {
        currentIndexView.layer.cornerRadius = buttonCornerRadius
        currentIndexView.clipsToBounds = true
    }
    
    // MARK: - IBActions
    @objc func segmentTapped(_ sender: UIButton) {
        didTapSegment?(sender.tag)
        currentIndex = sender.tag
    }
}

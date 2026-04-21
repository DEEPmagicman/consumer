import UIKit

final class OrdersVC: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyTitleLbl: UILabel!
    @IBOutlet weak var emptySubTitleLbl: UILabel! 
    
    enum OrderSegment: Int {
        case upcoming = 0
        case past = 1
    }
    
    private var selectedType: OrderSegment = .upcoming
    
    // MARK: - Separate Data Source
    private var upcomingBookings: [Booking] = []
    private var pastBookings: [Booking] = []
    
    // MARK: - Separate Paging State
    private var upcomingSkip = 0
    private var pastSkip = 0
    
    private var upcomingHasMany = false
    private var pastHasMany = false
    
    private var isLoading = false
    private var isInitialLoading = true
    
    private var currentBookings: [Booking] {
        switch selectedType {
        case .upcoming:
            return upcomingBookings
        case .past:
            return pastBookings
        }
    }
    
    private var currentHasMany: Bool {
        switch selectedType {
        case .upcoming:
            return upcomingHasMany
        case .past:
            return pastHasMany
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSegmentedControl()
        setupTableView()
        loadCurrentSegment(reset: true)
    }
    
    private func setupSegmentedControl() {
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white
        ], for: .normal)
        
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white
        ], for: .selected)
        
        segmentedControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.15)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        segmentedControl.layer.cornerRadius = segmentedControl.frame.height / 2
        segmentedControl.clipsToBounds = true
        segmentedControl.layer.masksToBounds = true
    }
    
    @IBAction func onChangeSegment(_ sender: UISegmentedControl) {
        selectedType = OrderSegment(rawValue: sender.selectedSegmentIndex) ?? .upcoming
        
        switch selectedType {
        case .upcoming:
            if !upcomingBookings.isEmpty {
                isInitialLoading = false
                tableView.reloadData()
                updateEmptyState()
            } else {
                loadCurrentSegment(reset: true)
            }
            
        case .past:
            if !pastBookings.isEmpty {
                isInitialLoading = false
                tableView.reloadData()
                updateEmptyState()
            } else {
                loadCurrentSegment(reset: true)
            }
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
            
            updateEmptyState() // 👈 hide empty while loading
            tableView.reloadData()
        }
        
        switch selectedType {
            
        // =========================
        // MARK: - Upcoming
        // =========================
        case .upcoming:
            PaymentPresenter.getUpcomingTicket(skip: upcomingSkip) { [weak self] isSuccess, errMsg, bookings, hasMany in
                guard let self = self else { return }
                
                self.isLoading = false
                self.isInitialLoading = false
                
                if isSuccess {
                    
                    if reset {
                        self.upcomingBookings = bookings
                    } else {
                        self.upcomingBookings.append(contentsOf: bookings)
                    }
                    
                    self.upcomingHasMany = hasMany
                    if hasMany {
                        self.upcomingSkip = self.upcomingBookings.count
                    }
                    
                } else {
                    
                    // ❗ important: only clear on reset
                    if reset {
                        self.upcomingBookings.removeAll()
                    }
                    
                    Alert.showAlertSheet(
                        style: .alert,
                        title: errMsg ?? Constant.String.somethingWrong,
                        message: ""
                    )
                }
                
                // ❗ update UI only if current tab
                if self.selectedType == .upcoming {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
            
        // =========================
        // MARK: - Past
        // =========================
        case .past:
            PaymentPresenter.getPastTicket(skip: pastSkip) { [weak self] isSuccess, errMsg, bookings, hasMany in
                guard let self = self else { return }
                
                self.isLoading = false
                self.isInitialLoading = false
                
                if isSuccess {
                    
                    if reset {
                        self.pastBookings = bookings
                    } else {
                        self.pastBookings.append(contentsOf: bookings)
                    }
                    
                    self.pastHasMany = hasMany
                    if hasMany {
                        self.pastSkip = self.pastBookings.count
                    }
                    
                } else {
                    
                    if reset {
                        self.pastBookings.removeAll()
                    }
                    
                    Alert.showAlertSheet(
                        style: .alert,
                        title: errMsg ?? Constant.String.somethingWrong,
                        message: ""
                    )
                }
                
                if self.selectedType == .past {
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }}

extension OrdersVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isInitialLoading {
            emptyView.isHidden = true
            return 5
        }
        return currentBookings.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
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
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        
        let booking = currentBookings[indexPath.row]
        
        if booking.eventId != nil {
            Navigate.to.showQRCode(
                self,
                booking: booking,
                bookingId: booking.id,
                type: .singleTickedEvent
            )
        } else if booking.inviteLink != nil {
            Navigate.to.showQRCode(
                self,
                booking: booking,
                bookingId: booking.id,
                type: .appClip
            )
        } else {
            Navigate.to.scanQR(
                self,
                bookingId: booking.id,
                booking: booking,
                addOnsBookingId: ""
            )
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard !isLoading else { return }
        guard currentHasMany else { return }
        
        if indexPath.row == currentBookings.count - 1 {
            loadCurrentSegment(reset: false)
        }
    }
}

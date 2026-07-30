import UIKit

class PremiumExperiencesVC: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backGroundVideoView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var permuimExperiencesHiddenView: UIView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var navTitleLbl: UILabel!
    @IBOutlet weak var navTitleBgView: UIView!
    @IBOutlet weak var bgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var premuimExperiencesView: UIView!
    @IBOutlet weak var rightBtn: UIButton!
    
    private var shimmerView: VenueEventsShimmerView?
    private var appliedPremiumGradientBounds: CGRect = .zero

    var isShimmerLoading: Bool = true
    var events: [String] = []
    private var isPremiumOpen = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPremiumBackground()
        scrollView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
        scrollView.contentInsetAdjustmentBehavior = .never

        showShimmer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopShimmer()
            self.isShimmerLoading = false
            self.events = Array(repeating: "Demo", count: 10)
            self.tableView.reloadData()
            
            self.updateTableHeight()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyPremiumBackgroundIfNeeded()
        shimmerView?.frame = tableView.bounds
        updateTableHeight()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var isCollapsed = false
    private let collapseThreshold: CGFloat = 120

    func applyNavAppearance(collapsed: Bool) {
        self.navTitleLbl.alpha = collapsed ? 1 : 0
        self.navTitleLbl.isHidden = collapsed ? false : true
            self.premuimExperiencesView.alpha = collapsed ? 0 : 1
            self.backGroundVideoView.alpha = collapsed ? 0 : 1
            
            self.bgViewHeight.constant = collapsed ? 0 : 298
            self.navTitleBgView.backgroundColor = collapsed
            ? UIColor(hex: "#282828")
            : .clear
    }

    // MARK: - Premium Background

    private func setupPremiumBackground() {
        view.backgroundColor = UIColor(hex: "#070808")
        scrollView.backgroundColor = .clear
        backGroundVideoView.backgroundColor = .clear
    }

    private func applyPremiumBackgroundIfNeeded() {
        guard appliedPremiumGradientBounds != view.bounds else { return }
        appliedPremiumGradientBounds = view.bounds
        view.applyPremiumScreenBgGradient()
    }

    private func showShimmer() {
        let shimmer = VenueEventsShimmerView(frame: tableView.bounds)
        tableView.addSubview(shimmer)
        shimmer.start()
        shimmerView = shimmer
    }
    
    func stopShimmer() {
        shimmerView?.stop()
        shimmerView?.removeFromSuperview()
        shimmerView = nil
    }
    
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        tableView
    }

    // MARK: - Table Height

    func updateTableHeight() {
        tableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = tableView.contentSize.height
    }

    // MARK: - Actions

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickPremiumExperiences(_ sender: Any) {
        isPremiumOpen.toggle()
        permuimExperiencesHiddenView.isHidden = !isPremiumOpen

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            self.rightBtn.transform = self.isPremiumOpen
            ? CGAffineTransform(rotationAngle: .pi / 2)
            : .identity
        }
    }
}

// MARK: - ScrollView Delegate ✅ Only logic needed

extension PremiumExperiencesVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        
        let shouldCollapse = scrollView.contentOffset.y > collapseThreshold
        
        if shouldCollapse != isCollapsed {
            isCollapsed = shouldCollapse
            applyNavAppearance(collapsed: shouldCollapse)
        }
    }
}

// MARK: - TableView

extension PremiumExperiencesVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isShimmerLoading ? 5 : events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: VenueEventTVC = tableView.dequeue(
            withIdentifier: VenueEventTVC.identifier,
            for: indexPath
        )
        cell.setScreenType(screenType: .premiumExperience)
        
        cell.selectionStyle = .none

        if isShimmerLoading {
            cell.contentView.alpha = 0
            cell.backgroundColor = .clear
        } else {
            cell.contentView.alpha = 1
//            cell.configure(with: events[indexPath.row]) // your actual method
        }

        return cell
    }
}

import UIKit
import AVFoundation

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
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    private var shimmerView: VenueEventsShimmerView?

    var isShimmerLoading: Bool = true
    var events: [String] = Array(repeating: "Demo", count: 10)

    private let navTitleText = "Premium Experiences"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupBackgroundVideo()
        setupLoop()

        scrollView.delegate = self  // ✅ Must have this

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)

        showShimmer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopShimmer()
            self.isShimmerLoading = false
            self.tableView.reloadData()
            self.updateTableHeight()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = backGroundVideoView.bounds
        shimmerView?.frame = tableView.bounds
        updateTableHeight()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Nav Bar

    func setupNavigationBar() {
        navigationItem.title = navTitleText
        navigationController?.navigationBar.tintColor = .white
        applyNavAppearance(scrolledDown: false) // start transparent
    }

    func applyNavAppearance(scrolledDown: Bool) {
        let appearance = UINavigationBarAppearance()

        if scrolledDown {
            navTitleLbl.isHidden = false
            premuimExperiencesView.isHidden = true
            backGroundVideoView.isHidden = true
            bgViewHeight.constant = 0
            navTitleBgView.backgroundColor = UIColor(hex: "#282828")
            
        } else {
            navTitleLbl.isHidden = true
            premuimExperiencesView.isHidden = false
            backGroundVideoView.isHidden = false
            bgViewHeight.constant = 298
            navTitleBgView.backgroundColor = .clear
          
        }
    }

    // MARK: - Video

    func setupBackgroundVideo() {
        guard let path = Bundle.main.path(forResource: "PremiumExperience", ofType: "mp4") else { return }
        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = backGroundVideoView.bounds
        if let layer = playerLayer {
            backGroundVideoView.layer.insertSublayer(layer, at: 0)
        }
        player?.isMuted = true
        player?.play()
    }

    func setupLoop() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(loopVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }

    @objc func loopVideo() {
        player?.seek(to: .zero)
        player?.play()
    }

    // MARK: - Shimmer

    func showShimmer() {
        let shimmer = VenueEventsShimmerView(frame: tableView.bounds)
        tableView.addSubview(shimmer)
        shimmer.start()
        shimmerView = shimmer
    }

    func stopShimmer() {
        shimmerView?.stop()
        shimmerView = nil
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
        permuimExperiencesHiddenView.isHidden.toggle()
    }
}

// MARK: - ScrollView Delegate ✅ Only logic needed

extension PremiumExperiencesVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        applyNavAppearance(scrolledDown: scrollView.contentOffset.y > 0)
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
        cell.selectionStyle = .none
        return cell
    }
}

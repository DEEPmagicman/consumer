//
//  VenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

import UIKit

final class VenueVC: UIViewController {
    
    @IBOutlet weak var venueView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var venueLogo: UIImageView!
    @IBOutlet weak var bgImage: UIImageView!
    
    var header: VenueHeaderVC?
    var segmentedScrollView = SJSegmentedViewController()
    var presenter = MVPPresenter()
    private var shimmerView: VenueShimmerView?

    private let glassSegment = GlassSegmentView(titles: ["Events", "Details", "Artists"])

    var venueDetails: ClipVenue?
    var uniqueId: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpData()
        showShimmer()
        getVenueDetails()
    }
    
    // Instead of cornerRadius: 999, let layoutSubviews set it dynamically
   
    
    private func showShimmer() {
        let shimmer = VenueShimmerView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shimmer)
        NSLayoutConstraint.activate([
            shimmer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shimmer.topAnchor.constraint(equalTo: view.topAnchor),
            shimmer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.shimmerView = shimmer
        shimmer.start()
    }
    
    private func getVenueDetails() {
        presenter.getVenuesDetailForaMVP(
            venueId: (venueDetails?.uniqueId ?? uniqueId) ?? "",
            venueTimeZone: venueDetails?.useTimezone ?? "",
            doormanId: ""
        ) { [weak self] isSuccess, errMsg, venueDetail in
            guard let self = self else { return }
            if isSuccess, let venue = venueDetail {
                self.venueDetails = venue
                self.shimmerView?.stop()
                self.setUpData()
                self.setUpSegmentVC()
            } else {
                self.shimmerView?.stop()
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? "Something went wrong",
                    message: ""
                )
            }
        }
    }
    
    private func setUpData() {
        venueName.text = venueDetails?.name ?? "Venue"
        let logoUrl = "\(SharedURL.amazonStorage)\(venueDetails?.logo?.key ?? "")"
        self.venueLogo.sd_setImage(with: URL(string: logoUrl), completed: nil)
        let imageUrlString = "\(SharedURL.amazonStorage)\(venueDetails?.venueAttachment?.first?.key ?? "")"
        if let url = URL(string: imageUrlString) {
            bgImage.sd_setImage(with: url, placeholderImage: UIImage(named: "newSpeakeasy"))
        } else {
            bgImage.image = UIImage(named: "newSpeakeasy")
        }
    }
    
    private func setUpSegmentVC() {
        let header = VenueHeaderVC(nibName: "VenueHeaderVC", bundle: nil)
        header.venueDetails = self.venueDetails
        self.header = header
        segmentedScrollView.headerViewHeight = header.headerHeight
        
        segmentedScrollView.delegate = self
        segmentedScrollView.segmentBounces = false
        segmentedScrollView.scrollCallBackDelegate = self

        if let font = UIFont(name: "poppins-medium", size: 15) {
            segmentedScrollView.segmentTitleFont = font
        }

        // ── Hide the built-in SJSegment tab bar ──────────────────────────────
        segmentedScrollView.selectedSegmentViewHeight = 0
        segmentedScrollView.segmentTitleColor = .clear
        segmentedScrollView.segmentSelectedTitleColor = .clear
        segmentedScrollView.segmentBackgroundColor = .clear
        segmentedScrollView.selectedSegmentViewColor = .clear
        
        // ────────────────────────────────────────────────────────────────────

        segmentedScrollView.headerViewController = header
        
        let vc1 = VenueEventsVC(nibName: "VenueEventsVC", bundle: nil)
        vc1.title = "Events"
        vc1.venueId = venueDetails?.id ?? ""
        
        let vc2 = VenueDetailsVC(nibName: "VenueDetailsVC", bundle: nil)
        vc2.venueDetails = venueDetails
        vc2.title = "Details"
        
        let vc3 = ArtistsVC(nibName: "ArtistsVC", bundle: nil)
        vc3.title = "Artists"
        
        segmentedScrollView.segmentControllers = [vc1, vc2, vc3]

        segmentedScrollView.headerViewOffsetHeight = 0
        segmentedScrollView.segmentedScrollView.backgroundColor = .clear

        venueView.addSubview(segmentedScrollView.view)
        addChild(segmentedScrollView)
        segmentedScrollView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedScrollView.view.leadingAnchor.constraint(equalTo: venueView.leadingAnchor),
            segmentedScrollView.view.trailingAnchor.constraint(equalTo: venueView.trailingAnchor),
            segmentedScrollView.view.topAnchor.constraint(equalTo: venueView.topAnchor),
            segmentedScrollView.view.bottomAnchor.constraint(equalTo: venueView.bottomAnchor)
        ])
        segmentedScrollView.segmentedScrollView.backgroundColor = .clear
        segmentedScrollView.didMove(toParent: self)

        setupGlassSegment()
    }

    // MARK: - GlassSegmentView

    private func setupGlassSegment() {
        glassSegment.translatesAutoresizingMaskIntoConstraints = false
        glassSegment.setSelectedIndex(0, animated: false)
        
        venueView.clipsToBounds = false          // ← add this
            segmentedScrollView.view.clipsToBounds = false  // ← and this

        // Add on top of segmentedScrollView so it overlays the hidden SJ tab row
        venueView.addSubview(glassSegment)
        venueView.bringSubviewToFront(glassSegment)

        NSLayoutConstraint.activate([
            glassSegment.heightAnchor.constraint(equalToConstant: 44),
            glassSegment.leadingAnchor.constraint(equalTo: venueView.leadingAnchor, constant: 16),
            glassSegment.trailingAnchor.constraint(equalTo: venueView.trailingAnchor, constant: -16),
            // Sits exactly where SJSegment renders its tab bar (just below the header)
            glassSegment.topAnchor.constraint(
                equalTo: venueView.topAnchor,
                constant: header?.headerHeight ?? 0
            ),
        ])

        // User taps a glass tab → scroll SJSegment to that page
        glassSegment.onIndexChanged = { [weak self] index in
            guard let self = self else { return }
            // Scroll the underlying UIScrollView to the correct page
            let pageWidth = self.segmentedScrollView.segmentedScrollView.bounds.width
            self.segmentedScrollView.segmentedScrollView.setContentOffset(
                CGPoint(x: pageWidth * CGFloat(index), y: 0),
                animated: true
            )
        }
    }

    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickShare(_ sender: Any) {
        let msgText = "Check out \(venueDetails?.name ?? "Venue") on Speakeasy. \(String(format: APIBuilder.venueWebURL, venueDetails?.name.lowercased().replacingOccurrences(of: " ", with: "-") ?? "Venue", venueDetails?.uniqueId ?? "")) Download the app to directly connect with your favorite venues & never miss out! \(SharedURL.appStoreURL)"
        Utility.main.shareSocialWith(text: msgText)
    }
}

// MARK: - SJSegmentedViewControllerDelegate, ScrollCallBackDelegate

extension VenueVC: SJSegmentedViewControllerDelegate, ScrollCallBackDelegate {

    func didMoveToPage(_ controller: UIViewController, segment: SJSegmentTab?, index: Int) {
        // Keep glass segment in sync when user swipes between pages
        glassSegment.setSelectedIndex(index, animated: true)
    }
    
    func onChangeScrollListener(lastContentOffset: CGFloat, offSet: CGFloat) {}
}

// MARK: - VenueShimmerView

final class VenueShimmerView: UIView {
    
    private var shimmerViews: [ShimmerView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func makeShimmer(_ frame: CGRect, corner: CGFloat = 8) -> ShimmerView {
        let view = ShimmerView(frame: frame)
        view.layer.cornerRadius = corner
        view.clipsToBounds = true
        addSubview(view)
        shimmerViews.append(view)
        return view
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        let width = UIScreen.main.bounds.width

        // Follow button
        makeShimmer(CGRect(x: width/2 - 60, y: 240, width: 120, height: 36), corner: 18)
        
        // Ticket card
        makeShimmer(CGRect(x: 16, y: 300, width: width - 32, height: 60), corner: 12)
        
        // Glass segment shimmer (full pill shape)
        makeShimmer(CGRect(x: 16, y: 375, width: width - 32, height: 44), corner: 22)

        // Event list (5 rows)
        var y: CGFloat = 440
        for _ in 0..<5 {
            makeShimmer(CGRect(x: 16, y: y, width: 80, height: 80), corner: 12)
            makeShimmer(CGRect(x: 110, y: y + 10, width: width - 140, height: 16))
            makeShimmer(CGRect(x: 110, y: y + 35, width: width - 180, height: 14))
            makeShimmer(CGRect(x: 110, y: y + 55, width: width - 200, height: 14))
            y += 100
        }
    }
    
    func start() {
        shimmerViews.forEach { $0.startAnimating() }
    }
    
    func stop() {
        shimmerViews.forEach { $0.stopAnimating() }
        removeFromSuperview()
    }
}

// MARK: - GlassSegmentView

final class GlassSegmentView: UIControl {

    var onIndexChanged: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    // ── LiquidGlassBackgroundView replaces all CAGradientLayer background/border ──
    private let glassBackground = LiquidGlassBackgroundView()

    // Selected pill — still uses LiquidGlassBackgroundView for the highlight
    private let selectedView = LiquidGlassBackgroundView()

    private var labels:          [UILabel] = []
    private var selectedLeading: NSLayoutConstraint!
    private var selectedWidth:   NSLayoutConstraint!
    private var titles:          [String]  = []

    // MARK: Init

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        setupUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSelectedPosition(animated: false)
        glassBackground.layer.cornerRadius = bounds.height / 2
        selectedView.layer.cornerRadius    = selectedView.bounds.height / 2
        updateSelectedPosition(animated: false)
    }
    // MARK: Setup

    private func setupUI() {
        // ── Outer glass background (lowest layer) ────────────────────────────
        glassBackground.translatesAutoresizingMaskIntoConstraints = false
        glassBackground.isUserInteractionEnabled = false
        glassBackground.cornerRadius = 25
        insertSubview(glassBackground, at: 0)
        NSLayoutConstraint.activate([
            glassBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassBackground.topAnchor.constraint(equalTo: topAnchor),
            glassBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // ── Selected pill (above background, below labels) ───────────────────
        selectedView.translatesAutoresizingMaskIntoConstraints = false
        selectedView.cornerRadius = 25
        selectedView.isUserInteractionEnabled = false
        addSubview(selectedView)

        // ── Labels ───────────────────────────────────────────────────────────
        setupLabels()
        setupConstraints()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
    }

    private func setupLabels() {
        for title in titles {
            let lbl = UILabel()
            lbl.text                    = title
            lbl.textAlignment           = .center
            lbl.font                    = Constant.Font.geistMedium(size: 14)
            lbl.textColor               = .white
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.isUserInteractionEnabled = false
            addSubview(lbl)
            labels.append(lbl)
        }
    }

    private func setupConstraints() {
        guard !labels.isEmpty else { return }
        let count = CGFloat(labels.count)

        selectedLeading = selectedView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        selectedWidth = selectedView.widthAnchor.constraint(
            equalTo: widthAnchor,
            multiplier: 1 / count,
            constant: -2   // will be overridden by updateSelectedPosition
        )

        NSLayoutConstraint.activate([
            selectedLeading,
            selectedWidth,
            selectedView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            selectedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])

        for (i, lbl) in labels.enumerated() {
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: topAnchor),
                lbl.bottomAnchor.constraint(equalTo: bottomAnchor),
                lbl.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / count),
            ])
            if i == 0 {
                lbl.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            } else {
                lbl.leadingAnchor.constraint(equalTo: labels[i - 1].trailingAnchor).isActive = true
            }
        }

        updateLabelAlpha()
    }

    // MARK: Public API

    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0, index < labels.count else { return }
        selectedIndex = index
        updateSelectedPosition(animated: animated)
        updateLabelAlpha()
    }

    // MARK: Private

    private func updateSelectedPosition(animated: Bool) {
        guard bounds.width > 0, !labels.isEmpty else { return }
        let count  = CGFloat(labels.count)
        let slot   = bounds.width / count
        let isFirst = selectedIndex == 0
        let isLast  = selectedIndex == labels.count - 1

        // 4pt inset from leading on first, 4pt inset from trailing on last, centered otherwise
        selectedLeading.constant = slot * CGFloat(selectedIndex) + 4
        selectedWidth.constant   = isLast ? -8 : isFirst ? -2 : -2

        let animate = { self.layoutIfNeeded() }
        if animated {
            UIView.animate(
                withDuration: 0.32,
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.48,
                options: [.curveEaseOut, .beginFromCurrentState],
                animations: animate
            )
        } else {
            animate()
        }
    }
    
    private func updateLabelAlpha() {
        for (i, lbl) in labels.enumerated() {
            lbl.alpha = i == selectedIndex ? 1.0 : 0.45
        }
    }

    @objc private func onTap(_ gesture: UITapGestureRecognizer) {
        guard bounds.width > 0 else { return }
        let x       = gesture.location(in: self).x
        let index   = Int(x / (bounds.width / CGFloat(labels.count)))
        let clamped = max(0, min(index, labels.count - 1))
        guard clamped != selectedIndex else { return }
        setSelectedIndex(clamped, animated: true)
        sendActions(for: .valueChanged)
        onIndexChanged?(clamped)
    }
}

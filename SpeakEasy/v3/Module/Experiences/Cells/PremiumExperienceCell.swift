//
//  PremiumExperienceCell.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 15/06/26.
//

import UIKit
import SDWebImage

final class PremiumExperienceCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let venueLabel = UILabel()
    private let dateLabel = UILabel()

    private let guestIconView = UIImageView()
    private let guestLabel = UILabel()
    private let pricePillView = LiquidGlassBackgroundView(
        cornerRadius: 14,
        fillColor: UIColor(hex: "#D99935").withAlphaComponent(0.5),
        borderColor: UIColor.white.withAlphaComponent(0.4),
        borderWidth: 0.8
    )
    private let priceLabel = UILabel()
    private var priceWidthConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        releaseResources()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        releaseResources()
        titleLabel.text = nil
        venueLabel.text = nil
        dateLabel.text = nil
        guestLabel.text = nil
        priceLabel.text = nil
    }

    func releaseResources() {
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        pricePillView.releaseResources()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.layer.cornerRadius = 10
        pricePillView.cornerRadius = 14
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.06)
        imageView.translatesAutoresizingMaskIntoConstraints = false
//        pricePillView.overrideBackgroundColor = UIColor(hex: "#FF9B00").withAlphaComponent(0.18)
        contentView.addSubview(imageView)

        titleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.96)
        titleLabel.font = Constant.Font.geistMedium(size: 15)
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        venueLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.86)
        venueLabel.font = Constant.Font.geistSemiBold(size: 10)
        venueLabel.numberOfLines = 1
        venueLabel.lineBreakMode = .byTruncatingTail
        venueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(venueLabel)

        dateLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.62)
        dateLabel.font = Constant.Font.geistRegular(size: 12)
        dateLabel.numberOfLines = 1
        dateLabel.lineBreakMode = .byTruncatingTail
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)

        guestIconView.image = UIImage(resource: .guestIcon)
        guestIconView.tintColor = AppColor.primaryWhiteColor
        guestIconView.contentMode = .scaleAspectFit
        guestIconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(guestIconView)

        guestLabel.textColor = AppColor.primaryWhiteColor
        guestLabel.font = Constant.Font.geistRegular(size: 9)
        guestLabel.numberOfLines = 1
        guestLabel.adjustsFontSizeToFitWidth = true
        guestLabel.minimumScaleFactor = 0.82
        guestLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(guestLabel)
        
        pricePillView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pricePillView)

        priceLabel.textColor = AppColor.primaryWhiteColor
        priceLabel.font = Constant.Font.geistMedium(size: 10)
        priceLabel.textAlignment = .center
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.78
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        pricePillView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.08),

            venueLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            venueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            venueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),

            titleLabel.topAnchor.constraint(equalTo: venueLabel.bottomAnchor, constant: 3),
            titleLabel.leadingAnchor.constraint(equalTo: venueLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: venueLabel.trailingAnchor),

            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            dateLabel.leadingAnchor.constraint(equalTo: venueLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: venueLabel.trailingAnchor),

            guestIconView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            guestIconView.leadingAnchor.constraint(equalTo: venueLabel.leadingAnchor),
            guestIconView.widthAnchor.constraint(equalToConstant: 10),
            guestIconView.heightAnchor.constraint(equalToConstant: 10),

            guestLabel.centerYAnchor.constraint(equalTo: guestIconView.centerYAnchor),
            guestLabel.leadingAnchor.constraint(equalTo: guestIconView.trailingAnchor, constant: 4),
            guestLabel.trailingAnchor.constraint(lessThanOrEqualTo: pricePillView.leadingAnchor, constant: -8),

            pricePillView.centerYAnchor.constraint(equalTo: guestIconView.centerYAnchor),
            pricePillView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            pricePillView.heightAnchor.constraint(equalToConstant: 28),
            pricePillView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            
            priceLabel.topAnchor.constraint(equalTo: pricePillView.topAnchor, constant: 2),
            priceLabel.leadingAnchor.constraint(equalTo: pricePillView.leadingAnchor, constant: 10),
            priceLabel.trailingAnchor.constraint(equalTo: pricePillView.trailingAnchor, constant: -10),
            priceLabel.bottomAnchor.constraint(equalTo: pricePillView.bottomAnchor, constant: -2)
        ])
        
        priceWidthConstraint = pricePillView.widthAnchor.constraint(equalToConstant: 70)
        priceWidthConstraint.isActive = true
    }
    
    func configure(_ item: PremiumExperienceItem) {
        titleLabel.text = item.title
        venueLabel.text = item.venueName.uppercased()
        dateLabel.text = item.dateText
        guestLabel.text = item.guestText
        guestIconView.isHidden = item.isInquiryAction
        guestLabel.isHidden = item.isInquiryAction

        if item.isInquiryAction {

            priceLabel.text = item.primaryActionTitle

            // iOS 26 Glass
            pricePillView.overrideBackgroundColor = nil

            // iOS <26 fallback
            pricePillView.fillColor = UIColor(
                white: 1,
                alpha: 0.12
            )

            pricePillView.borderColor = UIColor.white.withAlphaComponent(0.25)
            priceWidthConstraint.constant = 70

        } else {

            priceLabel.text = item.primaryActionTitle

            // Gold glass
            pricePillView.overrideBackgroundColor = nil

            pricePillView.fillColor = UIColor(
                hex: "#D99935"
            ).withAlphaComponent(0.5)

            pricePillView.borderColor = UIColor.white.withAlphaComponent(0.25)
            priceWidthConstraint.constant = 70
        }

        if let url = URL(string: item.imageUrl), !item.imageUrl.isEmpty {
            let screenScale = UIScreen.main.scale
            let targetPixelSize = CGSize(
                width: max(bounds.width, 180) * screenScale,
                height: max(bounds.width * 1.08, 200) * screenScale
            )

            imageView.sd_setImage(
                with: url,
                placeholderImage: Constant.Icon.uploadImage,
                options: [
                    
                    .continueInBackground,
                    .scaleDownLargeImages
                ],
                context: [
                    .imageThumbnailPixelSize: NSValue(cgSize: targetPixelSize)
                ]
            )
        } else {
            imageView.image = Constant.Icon.uploadImage
        }
    }
}

final class PremiumExperienceShimmerCell: UICollectionViewCell {

    private var shimmerContentView: PremiumExperienceShimmerContentView?
    private var shimmerConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        releaseResources()
    }

    override var isHidden: Bool {
        didSet {
            updateShimmerState()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmerState()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseResources()
        updateShimmerState()
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func updateShimmerState() {
        guard window != nil,
              !isHidden else {
            releaseResources()
            return
        }

        ensureShimmerContentView().setShimmeringEnabled(true)
    }

    private func ensureShimmerContentView() -> PremiumExperienceShimmerContentView {
        if let shimmerContentView {
            return shimmerContentView
        }

        let shimmerContentView = PremiumExperienceShimmerContentView()
        shimmerContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shimmerContentView)

        shimmerConstraints = [
            shimmerContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmerContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmerContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(shimmerConstraints)

        self.shimmerContentView = shimmerContentView
        return shimmerContentView
    }

    func releaseResources() {
        shimmerContentView?.releaseResources()
        NSLayoutConstraint.deactivate(shimmerConstraints)
        shimmerConstraints.removeAll()
        shimmerContentView?.removeFromSuperview()
        shimmerContentView = nil
    }
}

final class PremiumExperiencePaginationFooterView: UICollectionReusableView {

    private var leftCard: PremiumExperienceShimmerContentView?
    private var rightCard: PremiumExperienceShimmerContentView?
    private var shimmerConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        releaseResources()
    }

    override var isHidden: Bool {
        didSet {
            updateShimmerState()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmerState()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseResources()
        updateShimmerState()
    }

    private func setupUI() {
        backgroundColor = .clear
    }

    func releaseResources() {
        leftCard?.releaseResources()
        rightCard?.releaseResources()
        NSLayoutConstraint.deactivate(shimmerConstraints)
        shimmerConstraints.removeAll()
        leftCard?.removeFromSuperview()
        rightCard?.removeFromSuperview()
        leftCard = nil
        rightCard = nil
    }

    private func updateShimmerState() {
        guard window != nil,
              !isHidden else {
            releaseResources()
            return
        }

        let cards = ensureCards()
        cards.left.setShimmeringEnabled(true)
        cards.right.setShimmeringEnabled(true)
    }

    private func ensureCards() -> (
        left: PremiumExperienceShimmerContentView,
        right: PremiumExperienceShimmerContentView
    ) {
        if let leftCard,
           let rightCard {
            return (leftCard, rightCard)
        }

        releaseResources()

        let leftCard = PremiumExperienceShimmerContentView()
        let rightCard = PremiumExperienceShimmerContentView()

        [leftCard, rightCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        shimmerConstraints = [
            leftCard.topAnchor.constraint(equalTo: topAnchor),
            leftCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            rightCard.topAnchor.constraint(equalTo: topAnchor, constant: 36),
            rightCard.leadingAnchor.constraint(equalTo: leftCard.trailingAnchor, constant: 14),
            rightCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            rightCard.widthAnchor.constraint(equalTo: leftCard.widthAnchor),
            rightCard.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(shimmerConstraints)

        self.leftCard = leftCard
        self.rightCard = rightCard
        return (leftCard, rightCard)
    }
}

private final class PremiumExperienceShimmerContentView: UIView {

    private let imageView = ShimmerViewV3()
    private let titleView = ShimmerViewV3()
    private let venueView = ShimmerViewV3()
    private let dateView = ShimmerViewV3()
    private let guestView = ShimmerViewV3(frame: .zero, lighter: true)
    private let priceView = ShimmerViewV3(frame: .zero, lighter: true)

    private var shimmerViews: [ShimmerViewV3] {
        [
            imageView,
            titleView,
            venueView,
            dateView,
            guestView,
            priceView
        ]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        releaseResources()
    }

    private func setupUI() {
        backgroundColor = .clear

        imageView.cornerRadius = 10
        priceView.cornerRadius = 16

        shimmerViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.08),

            titleView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            titleView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.86),
            titleView.heightAnchor.constraint(equalToConstant: 17),

            venueView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 8),
            venueView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            venueView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.58),
            venueView.heightAnchor.constraint(equalToConstant: 12),

            dateView.topAnchor.constraint(equalTo: venueView.bottomAnchor, constant: 8),
            dateView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            dateView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.68),
            dateView.heightAnchor.constraint(equalToConstant: 13),

            guestView.topAnchor.constraint(equalTo: dateView.bottomAnchor, constant: 16),
            guestView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            guestView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.44),
            guestView.heightAnchor.constraint(equalToConstant: 14),

            priceView.centerYAnchor.constraint(equalTo: guestView.centerYAnchor),
            priceView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            priceView.widthAnchor.constraint(equalToConstant: 88),
            priceView.heightAnchor.constraint(equalToConstant: 32),
            priceView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        startShimmering()
    }

    private func startShimmering() {
        shimmerViews.forEach { $0.startShimmer() }
    }

    private func stopShimmering() {
        shimmerViews.forEach { $0.stopShimmer() }
    }

    func setShimmeringEnabled(_ isEnabled: Bool) {
        if isEnabled {
            startShimmering()
        } else {
            stopShimmering()
        }
    }

    func releaseResources() {
        shimmerViews.forEach { $0.releaseResources() }
        layer.removeAllAnimations()
    }

    override var isHidden: Bool {
        didSet {
            setShimmeringEnabled(!isHidden && window != nil)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setShimmeringEnabled(window != nil && !isHidden)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            releaseResources()
        } else {
            startShimmering()
        }
    }
}

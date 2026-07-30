//
//  ArtistVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit
import SDWebImage

struct ArtistDetailsContext {
    let id: String
    let venueId: String
    let name: String
    let imageKey: String?

    var imageURL: String? {
        guard let imageKey,
              !imageKey.isEmpty else { return nil }

        if imageKey.lowercased().hasPrefix("http://") ||
            imageKey.lowercased().hasPrefix("https://") {
            return imageKey
        }

        return imageKey.imageURL
    }

    init(
        id: String,
        venueId: String,
        name: String,
        imageKey: String?
    ) {
        self.id = id
        self.venueId = venueId
        self.name = name
        self.imageKey = imageKey
    }

    init(artist: Artists, venueId: String) {
        self.id = artist.id ?? ""
        self.venueId = venueId
        self.name = artist.name
        self.imageKey = artist.artistImage?.key
    }
}

final class ArtistDetailsVC: UIViewController {

    @IBOutlet weak var segmentView: UIView!

    var artist: ArtistDetailsContext?

    private let discoverService = DiscoverService()
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    )

    private weak var artistImageView: UIImageView?
    private weak var artistNameLabel: UILabel?
    private let posterHeaderView = EventPosterHeaderView()

    private var events: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true
    private var isPaginating = false
    private var lastCollectionLayoutWidth: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPosterBackground()
        captureHeaderViews()
        setupHeader()
        setupCollectionView()
        getEvents(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        artistImageView?.layer.cornerRadius = (artistImageView?.bounds.height ?? 0) / 2
        artistImageView?.clipsToBounds = true
        refreshCollectionLayoutIfNeeded()
    }

    private func captureHeaderViews() {
        artistImageView = view.findFirstImageView(
            where: { abs($0.bounds.width - 100) < 2 || $0.tag == 1001 }
        )
        artistNameLabel = view.findFirstLabel(where: { $0.text == "Katy Perry" })
    }

    private func setupHeader() {
        artistNameLabel?.text = artist?.name ?? "Artist"
        artistNameLabel?.font = Constant.Font.geistMedium(size: 22)
        artistNameLabel?.numberOfLines = 2

        artistImageView?.contentMode = .scaleAspectFill
        artistImageView?.sd_cancelCurrentImageLoad()

        guard let imageURL = artist?.imageURL,
              let url = URL(string: imageURL) else {
            artistImageView?.image = Constant.Icon.uploadImage
            posterHeaderView.setBackgroundImage(Constant.Icon.uploadImage)
            return
        }

        posterHeaderView.loadImage(from: imageURL)
        artistImageView?.sd_setImage(
            with: url,
            placeholderImage: Constant.Icon.uploadImage
        ) { [weak self] image, _, _, _ in
            guard image == nil else { return }
            self?.artistImageView?.image = Constant.Icon.uploadImage
        }
    }

    private func setupCollectionView() {
        guard let container = segmentView.superview else { return }

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = true
        collectionView.layer.masksToBounds = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )
        collectionView.register(
            OrderCardShimmerCell.self,
            forCellWithReuseIdentifier: OrderCardShimmerCell.identifier
        )
        collectionView.register(
            EmptyCollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EmptyCollectionReusableView.identifier
        )
        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(
            top: 10,
            left: 24,
            bottom: 34,
            right: 24
        )
        layout.interItemSpacing = 14
        layout.lineSpacing = 16
        layout.delegate = self
        collectionView.collectionViewLayout = layout

        container.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: segmentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func getEvents(reset: Bool = false) {
        guard !isLoading || reset else { return }
        guard hasMore || reset else { return }

        let artistId = artist?.id ?? ""
        let venueId = artist?.venueId ?? ""

        guard !artistId.isEmpty else {
            isInitialLoading = false
            events.removeAll()
            reloadUI()
            return
        }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            isPaginating = false
            events.removeAll()
            reloadUI()
        }

        discoverService.fetchArtistEvents(
            artistId: artistId,
            venueId: venueId,
            skip: skip,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in

            DispatchQueue.main.async {
                guard let self else { return }

                let oldCount = self.events.count
                self.isLoading = false

                guard isSuccess,
                      let page else {
                    let wasInitialLoading = self.isInitialLoading
                    self.isInitialLoading = false
                    self.isPaginating = false
                    self.hasMore = false
                    if wasInitialLoading || self.events.isEmpty {
                        self.reloadUI()
                    } else {
                        self.invalidateFooter()
                        self.updateEmptyState()
                    }
                    if let errMsg {
                        Alert.showToast(errMsg)
                    }
                    return
                }

                let incomingEvents = reset
                    ? page.list
                    : page.list.filter { newEvent in
                        !self.events.contains { $0.id == newEvent.id }
                    }

                if reset {
                    self.events = incomingEvents
                } else {
                    self.events.append(contentsOf: incomingEvents)
                }

                self.skip = self.events.count
                self.hasMore = page.hasMore

                let wasInitialLoading = self.isInitialLoading
                self.isInitialLoading = false

                if wasInitialLoading || reset {
                    self.isPaginating = false
                    self.reloadUI()
                    return
                }

                let newCount = self.events.count
                let indexPaths = (oldCount..<newCount).map {
                    IndexPath(item: $0, section: 0)
                }

                guard !indexPaths.isEmpty else {
                    self.isPaginating = false
                    self.invalidateFooter()
                    self.updateEmptyState()
                    return
                }

                self.insertEventItems(indexPaths)
            }
        }
    }

    private func reloadUI() {
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        updateEmptyState()
    }

    private func insertEventItems(_ indexPaths: [IndexPath]) {
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: indexPaths)
            } completion: { [weak self] _ in
                guard let self else { return }
                self.isPaginating = false
                self.invalidateFooter()
                self.updateEmptyState()
            }
        }
    }

    private func updateEmptyState() {
        collectionView.backgroundView = !isInitialLoading && events.isEmpty
            ? makeEmptyStateView()
            : nil
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView(frame: collectionView.bounds)
        container.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No events found"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 18)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "This artist does not have upcoming events here yet."
        subtitleLabel.textColor = AppColor.primaryWhiteColor.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 14)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        container.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -32)
        ])

        return container
    }

    private func invalidateFooter() {
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.invalidateFooter()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func refreshCollectionLayoutIfNeeded() {
        let width = collectionView.bounds.width

        guard width > 0,
              abs(width - lastCollectionLayoutWidth) > 0.5 else {
            return
        }

        lastCollectionLayoutWidth = width

        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
    }

    private func setupPosterBackground() {
        view.backgroundColor = AppColor.primaryBlackColor
        view.subviews.first?.backgroundColor = .clear

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

    private func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isPaginating else { return }
        guard !isLoading else { return }
        guard hasMore else { return }
        guard !events.isEmpty else { return }

        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()

        getEvents(reset: false)
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickShareBtn(_ sender: Any) {
        guard let artist else { return }
        Utility.main.shareSocialWith(text: artist.name)
    }
}

extension ArtistDetailsVC: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        if isInitialLoading {
            return 6
        }

        return events.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        if isInitialLoading {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: OrderCardShimmerCell.identifier,
                for: indexPath
            )
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        guard events.indices.contains(indexPath.item) else {
            return cell
        }

        cell.configureDiscoverEvent(events[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PaginationShimmerFooterView.identifier,
                for: indexPath
            ) as! PaginationShimmerFooterView

            footer.isHidden = !(isPaginating && hasMore)
            return footer
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: EmptyCollectionReusableView.identifier,
            for: indexPath
        )
        header.isHidden = true
        return header
    }
}

extension ArtistDetailsVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard !isInitialLoading else { return }
        guard events.indices.contains(indexPath.item) else { return }

        Navigate.eventDetailsVC(self, event: events[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        let threshold: CGFloat = 400

        guard offsetY > contentHeight - visibleHeight - threshold else {
            return
        }

        loadNextPageIfNeeded()
    }
}

extension ArtistDetailsVC: UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard !isInitialLoading else { return }

        if indexPaths.contains(where: { $0.item >= events.count - 4 }) {
            loadNextPageIfNeeded()
        }
    }
}

extension ArtistDetailsVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {

        if isInitialLoading {
            let imageHeight = width * 1.2
            return imageHeight + 90
        }

        guard events.indices.contains(indexPath.item) else {
            return 0.1
        }

        let event = events[indexPath.item]
        let imageHeight = width * 1.2
        let title = event.title
        let venue = event.venue?.name ?? ""
        let dateText = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .MMMDDATHMMA,
            useDayLightSavingTime: true,
            customTimeZone: event.venue?.useTimezone ?? ""
        )

        let titleFont = Constant.Font.geistMedium(size: 14)
        let venueFont = Constant.Font.geistMedium(size: 12)
        let dateFont = Constant.Font.geistMedium(size: 12)

        let titleHeight = ceil(titleFont.lineHeight * 2)
        let venueHeight = ceil(venueFont.lineHeight)
        let dateHeight = ceil(dateFont.lineHeight)

        let height = imageHeight
            + 16
            + titleHeight
            + 3
            + venueHeight
            + 4
            + dateHeight
        
        return height
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {
        return 0.1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        return isPaginating && hasMore ? 300 : 0
    }

    private func textHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        text.boundingRect(
            with: CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: [.font: font],
            context: nil
        ).height
    }
}

private extension UIView {

    func findFirstImageView(
        where predicate: (UIImageView) -> Bool
    ) -> UIImageView? {
        if let imageView = self as? UIImageView,
           predicate(imageView) {
            return imageView
        }

        for subview in subviews {
            if let imageView = subview.findFirstImageView(where: predicate) {
                return imageView
            }
        }

        return nil
    }

    func findFirstLabel(
        where predicate: (UILabel) -> Bool
    ) -> UILabel? {
        if let label = self as? UILabel,
           predicate(label) {
            return label
        }

        for subview in subviews {
            if let label = subview.findFirstLabel(where: predicate) {
                return label
            }
        }

        return nil
    }
}

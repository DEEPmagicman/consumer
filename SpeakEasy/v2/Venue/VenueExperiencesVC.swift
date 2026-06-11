//
//  VenueExperiencesVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/03/26.
//

import UIKit

final class VenueExperiencesVC: UIViewController,
                           SJSegmentedViewControllerViewSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!

    weak var scrollDelegate: ChildScrollDelegate?
    var venueId = ""

    private var events: [Event] = []

    private var skip = 0
    private var hasMore = true

    private var isLoading = false
    private var shimmerView: VenueEventsShimmerView?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        showShimmer()
        getEvents()
    }

    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        return collectionView
    }
    
    @IBAction func onClickPermuimExp(_ sender: Any) {
        Navigate.to.presentPremiumExpPopUp(self)
    }
    
}

// MARK: - Setup

extension VenueExperiencesVC {

    private func setupCollectionView() {

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self

        collectionView.backgroundColor = .clear
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

        let layout = PinterestLayout()

        layout.numberOfColumns = 2

        layout.sectionInsets = UIEdgeInsets(
            top: 10,
            left: 24,
            bottom: 24,
            right: 24
        )

        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.delegate = self

        collectionView.collectionViewLayout = layout
    }

    private func showShimmer() {

        let shimmer = VenueEventsShimmerView(
            frame: collectionView.bounds
        )

        collectionView.addSubview(shimmer)

        shimmer.start()

        shimmerView = shimmer
    }
}

// MARK: - API

extension VenueExperiencesVC {

    func getEvents() {

        guard !isLoading else { return }
        guard hasMore else { return }

        isLoading = true

        VenuePresenter.getEventVenues(
            venueId: venueId,
            skip: skip,
            time: "UPCOMING"
        ) { [weak self] isSuccess,
            errMsg,
            list,
            hasMore in

            guard let self = self else { return }

            DispatchQueue.main.async {

                self.isLoading = false

                self.shimmerView?.stop()

                if isSuccess {

                    let newItems = list.filter { newEvent in
                        !self.events.contains(where: {
                            $0.id == newEvent.id
                        })
                    }

                    self.events.append(contentsOf: newItems)

                    self.skip = self.events.count
                    self.hasMore = hasMore

                    self.emptyView.isHidden = !self.events.isEmpty
                    self.collectionView.isHidden = self.events.isEmpty

                    self.collectionView.reloadData()

                } else {

                    self.emptyView.isHidden = false
                    self.collectionView.isHidden = true

                    print(errMsg ?? "Error")
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension VenueExperiencesVC: UICollectionViewDataSource {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {

        return events.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        let event = events[indexPath.item]

        cell.configureDiscoverEvent(event)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension VenueExperiencesVC: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {

        let event = events[indexPath.item]

        Navigate.eventDetailsVC(
            self,
            event: event
        )
    }

    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {

        scrollDelegate?.childScrollViewDidScroll(scrollView)

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        let threshold: CGFloat = 400

        if offsetY > contentHeight - visibleHeight - threshold {
            getEvents()
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension VenueExperiencesVC:
    UICollectionViewDataSourcePrefetching {

    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {

        if indexPaths.contains(where: {
            $0.item >= self.events.count - 4
        }) {
            getEvents()
        }
    }
}

// MARK: - PinterestLayoutDelegate

extension VenueExperiencesVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {

        guard events.indices.contains(indexPath.item) else {
            return 0.1
        }

        let event = events[indexPath.item]

        let imageHeight = width * 1.2

        let title = event.title ?? ""
        let venue = event.venue?.name ?? ""

        let dateText = event.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .MMMDDATHMMA,
            useDayLightSavingTime: true,
            customTimeZone: event.venue?.useTimezone ?? ""
        )

        let titleFont = Constant.Font.geistMedium(size: 15)
        let venueFont = Constant.Font.geistMedium(size: 14)
        let dateFont = Constant.Font.geistMedium(size: 14)

        let titleHeight = title.boundingRect(
            with: CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: [
                .font: titleFont
            ],
            context: nil
        ).height

        let venueHeight = venue.boundingRect(
            with: CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: [
                .font: venueFont
            ],
            context: nil
        ).height

        let dateHeight = dateText.boundingRect(
            with: CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            ),
            options: [
                .usesLineFragmentOrigin,
                .usesFontLeading
            ],
            attributes: [
                .font: dateFont
            ],
            context: nil
        ).height

        let totalHeight =
            imageHeight +
            16 +
            titleHeight +
            3 +
            venueHeight +
            10 +
            dateHeight

        return ceil(totalHeight)
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

        return hasMore ? 120 : 0
    }
}

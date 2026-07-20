//
//  ArtistsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit

final class ArtistsVC: UIViewController, SJSegmentedViewControllerViewSource {

    @IBOutlet weak var tableView: UITableView!

    weak var scrollDelegate: ChildScrollDelegate?
    var venueId = ""

    private let discoverService = DiscoverService()
    private var artists: [ArtistDetailsContext] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var isInitialLoading = true
    private let take = 10
    private var didMoveFixedTitleIntoTable = false

    override func viewDidLoad() {
        super.viewDidLoad()
        moveFixedTitleIntoTableIfNeeded()
        setupTableView()
        fetchArtists(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderWidthIfNeeded()
    }

    // MARK: - Segmented Scroll Source
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        return tableView
    }

    // MARK: - Setup
    private func setupTableView() {

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .clear
        tableView.clipsToBounds = false
        tableView.layer.masksToBounds = false
        view.clipsToBounds = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = true

        tableView.register(
            UINib(nibName: "ArtistsTableViewCell", bundle: nil),
            forCellReuseIdentifier: "ArtistsTableViewCell"
        )
        tableView.register(
            ArtistListShimmerCell.self,
            forCellReuseIdentifier: ArtistListShimmerCell.identifier
        )

        tableView.tableHeaderView = makeHeaderView()
    }

    private func moveFixedTitleIntoTableIfNeeded() {
        guard !didMoveFixedTitleIntoTable else { return }
        didMoveFixedTitleIntoTable = true

        view.subviews.forEach { subview in
            guard subview !== tableView else { return }
            subview.isHidden = true
        }

        let tableConstraints = view.constraints.filter { constraint in
            constraint.firstItem === tableView ||
            constraint.secondItem === tableView
        }

        NSLayoutConstraint.deactivate(tableConstraints)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeHeaderView() -> UIView {
        let header = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: tableView.bounds.width,
                height: 55
            )
        )
        header.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.text = "Artists"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 21)
        ])

        return header
    }

    private func updateHeaderWidthIfNeeded() {
        guard let header = tableView.tableHeaderView,
              abs(header.frame.width - tableView.bounds.width) > 0.5
        else { return }

        header.frame.size.width = tableView.bounds.width
        tableView.tableHeaderView = header
    }

    private func fetchArtists(reset: Bool = false) {
        guard !isLoading || reset else { return }
        guard hasMore || reset else { return }

        let trimmedVenueId = venueId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedVenueId.isEmpty else {
            isInitialLoading = false
            artists.removeAll()
            reloadUI()
            return
        }

        isLoading = true

        if reset {
            skip = 0
            hasMore = true
            isInitialLoading = true
            artists.removeAll()
            reloadUI()
        } else {
            tableView.tableFooterView = makeFooterView()
        }

        discoverService.fetchArtists(
            venueId: trimmedVenueId,
            skip: skip,
            take: take,
            timeZone: TimeZone.current.identifier
        ) { [weak self] isSuccess, errMsg, page in

            DispatchQueue.main.async {
                guard let self else { return }

                self.isLoading = false
                self.isInitialLoading = false

                guard isSuccess,
                      let page else {
                    self.reloadUI()
                    if let errMsg {
                        Alert.showToast(errMsg)
                    }
                    return
                }

                let incoming = page.list.map {
                    ArtistDetailsContext(artist: $0, venueId: trimmedVenueId)
                }

                if reset {
                    self.artists = incoming
                } else {
                    self.artists.append(
                        contentsOf: incoming.filter { newArtist in
                            !self.artists.contains { $0.id == newArtist.id }
                        }
                    )
                }

                self.skip = self.artists.count
                self.hasMore = page.hasMore
                self.reloadUI()
            }
        }
    }

    private func reloadUI() {
        tableView.reloadData()
        updateEmptyState()
        tableView.tableFooterView = makeFooterView()
    }

    private func updateEmptyState() {
        let hasScrollableContent = isInitialLoading || !artists.isEmpty
        tableView.isScrollEnabled = hasScrollableContent
        tableView.alwaysBounceVertical = hasScrollableContent
        tableView.backgroundView =
        !isInitialLoading && artists.isEmpty
        ? makeEmptyStateView()
        : nil
    }

    private func makeEmptyStateView() -> UIView {
        let container = UIView(frame: tableView.bounds)
        container.backgroundColor = .clear

        let emptyStateView = V3EmptyStateView(style: .artists)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: container.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeFooterView() -> UIView? {
        guard isLoading && !isInitialLoading else { return nil }

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56))
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()

        footer.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
        ])

        return footer
    }

    private func loadNextPageIfNeeded(_ scrollView: UIScrollView) {
        guard !isInitialLoading,
              !isLoading,
              hasMore,
              !artists.isEmpty else {
            return
        }

        let threshold: CGFloat = 220
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height

        if offsetY > contentHeight - visibleHeight - threshold {
            fetchArtists(reset: false)
        }
    }
}

// MARK: - UITableViewDataSource
extension ArtistsVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if isInitialLoading {
            return 6
        }

        return artists.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if isInitialLoading {
            let shimmerCell =
            tableView.dequeueReusableCell(
                withIdentifier: ArtistListShimmerCell.identifier,
                for: indexPath
            ) as? ArtistListShimmerCell

            shimmerCell?.startShimmer()
            return shimmerCell ?? UITableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ArtistsTableViewCell",
            for: indexPath
        ) as? ArtistsTableViewCell else {
            return UITableViewCell()
        }

        let artist = artists[indexPath.row]

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.configure(
            name: artist.name,
            imageURL: artist.imageURL
        )
        cell.onViewEvents = { [weak self] in
            guard let self else { return }
            Navigate.to.gotoArtistDetailsVC(self, artist: artist)
        }

        return cell
    }
}

private final class ArtistListShimmerCell: UITableViewCell {

    private let avatarShimmer = ShimmerViewV3()
    private let titleShimmer = ShimmerViewV3()
    private let subtitleShimmer = ShimmerViewV3(frame: .zero, lighter: true)
    private let buttonShimmer = ShimmerViewV3()
    private var shimmerViews: [ShimmerViewV3] {
        [
            avatarShimmer,
            titleShimmer,
            subtitleShimmer,
            buttonShimmer
        ]
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        shimmerViews.forEach { $0.stopShimmer() }
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        avatarShimmer.layer.cornerRadius = 24
        buttonShimmer.layer.cornerRadius = 17

        shimmerViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            avatarShimmer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            avatarShimmer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarShimmer.widthAnchor.constraint(equalToConstant: 48),
            avatarShimmer.heightAnchor.constraint(equalToConstant: 48),

            titleShimmer.leadingAnchor.constraint(equalTo: avatarShimmer.trailingAnchor, constant: 14),
            titleShimmer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            titleShimmer.widthAnchor.constraint(equalToConstant: 150),
            titleShimmer.heightAnchor.constraint(equalToConstant: 16),

            subtitleShimmer.leadingAnchor.constraint(equalTo: titleShimmer.leadingAnchor),
            subtitleShimmer.topAnchor.constraint(equalTo: titleShimmer.bottomAnchor, constant: 10),
            subtitleShimmer.widthAnchor.constraint(equalToConstant: 92),
            subtitleShimmer.heightAnchor.constraint(equalToConstant: 12),

            buttonShimmer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonShimmer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buttonShimmer.widthAnchor.constraint(equalToConstant: 92),
            buttonShimmer.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    func startShimmer() {
        shimmerViews.forEach { $0.startShimmer() }
    }
}

// MARK: - UITableViewDelegate
extension ArtistsVC: UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.childScrollViewDidScroll(scrollView)
        loadNextPageIfNeeded(scrollView)
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        guard !isInitialLoading else { return }
        guard artists.indices.contains(indexPath.row) else { return }

        Navigate.to.gotoArtistDetailsVC(self, artist: artists[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 83
    }
}

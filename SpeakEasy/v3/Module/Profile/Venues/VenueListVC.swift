//
//  VenueListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 29/05/26.
//

import UIKit

final class VenueListVC: UIViewController {

    private let backBtn = AppIconButton()
    private let searchBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let collectionView: UICollectionView

    private let emptyView = UIView()
    private let emptyImageView = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptySubTitleLabel = UILabel()
    
    private let venueService = VenueService()
    
    var venues: [ClipVenue] = []

    private var skip = 0
    var hasMany = false

    var isLoading = false
    var isInitialLoading = true
    var isPaginating = false

    init() {

        let layout = PinterestLayout()

        layout.numberOfColumns = 2

        layout.sectionInsets = UIEdgeInsets(
            top: 0,
            left: 24,
            bottom: 40,
            right: 24
        )

        layout.interItemSpacing = 16
        layout.lineSpacing = 16

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )

        super.init(
            nibName: nil,
            bundle: nil
        )

        layout.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        getVenues(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.applyScreenBgGradient()
    }
    
    private func setupUI() {
        setupNav()
        setupCollectionView()
        setupEmptyView()
        setupConstraints()
    }

    private func setupNav() {
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        searchBtn.iconTypeValue = AppIconType.search.rawValue
        searchBtn.iconSize = 14
        searchBtn.buttonSize = 40
        searchBtn.iconTintColor = .white
        searchBtn.isHidden = true
        searchBtn.addTarget(self, action: #selector(onClickSearch), for: .touchUpInside)
        searchBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBtn)

        titleLabel.text = "Followed Venues"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.register(
            VenueGridCell.self,
            forCellWithReuseIdentifier: VenueGridCell.identifier
        )

        collectionView.register(
            VenueGridShimmerCell.self,
            forCellWithReuseIdentifier: VenueGridShimmerCell.identifier
        )

        collectionView.register(
            PaginationShimmerFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PaginationShimmerFooterView.identifier
        )

        view.addSubview(collectionView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            searchBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onClickSearch() {
        Navigate.to.searchVenueVC(self)
    }
}

extension VenueListVC {
    
    func handleFollowStateChange(
        venue: ClipVenue,
        isFollowing: Bool
    ) {
        guard !isFollowing else {
            getVenues(reset: true)
            return
        }

        guard let index = venues.firstIndex(where: {
            $0.id == venue.id ||
            $0.uniqueId == venue.uniqueId
        }) else {
            getVenues(reset: true)
            return
        }

        venues.remove(at: index)
        skip = venues.count

        collectionView.performBatchUpdates {
            collectionView.deleteItems(
                at: [IndexPath(item: index, section: 0)]
            )
        } completion: { [weak self] _ in
            self?.updateEmptyState()
        }
    }

    private func getVenues(reset: Bool) {
        guard !isLoading else { return }
        
        isLoading = true
        
        if reset {
            skip = 0
            hasMany = false
            venues.removeAll()
            isInitialLoading = true
            collectionView.reloadData()
        }
        
        venueService.fetchFollowedVenues(skip: skip) { [weak self] isSuccess, errMsg, venues, hasMany in
            guard let self else { return }
            
            self.isLoading = false
            self.isInitialLoading = false
            self.isPaginating = false
            
            if isSuccess {
                let oldCount = self.venues.count
                
                self.venues = reset ? venues : self.venues + venues
                self.hasMany = hasMany
                self.skip = self.venues.count
                
                if reset {
                    self.collectionView.reloadData()
                } else {
                    let newCount = self.venues.count
                    let indexPaths = (oldCount..<newCount).map {
                        IndexPath(item: $0, section: 0)
                    }
                    
                    self.insertItems(indexPaths)
                }
            } else {
                if reset { self.venues.removeAll() }
                
                self.collectionView.reloadData()
                
                Alert.showToast(errMsg ?? Constant.String.somethingWrong)
                
//                Alert.showAlertSheet(
//                    style: .alert,
//                    title: errMsg ?? Constant.String.somethingWrong,
//                    message: ""
//                )
            }
            self.updateEmptyState()
        }
    }
    
    private func insertItems(_ indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else {
            isPaginating = false
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }
        
        collectionView.performBatchUpdates {
            collectionView.insertItems(at: indexPaths)
        } completion: { [weak self] _ in
            guard let self else { return }
            
            self.isPaginating = false
            
            if let layout = self.collectionView.collectionViewLayout as? PinterestLayout {
                layout.invalidateFooter()
            } else {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    func venue(at indexPath: IndexPath) -> ClipVenue? {
        guard venues.indices.contains(indexPath.item) else { return nil }
        return venues[indexPath.item]
    }
    
    func loadNextPageIfNeeded() {
        guard !isInitialLoading else { return }
        guard !isLoading else { return }
        guard !isPaginating else { return }
        guard hasMany else { return }
        guard !venues.isEmpty else { return }
        
        isPaginating = true
        collectionView.collectionViewLayout.invalidateLayout()
        getVenues(reset: false)
    }
    
}

extension VenueListVC {
    private func setupEmptyView() {
        
        emptyView.isHidden = true
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)
        
        emptyImageView.image = UIImage(named: "ic_empty_venue")
        emptyImageView.contentMode = .scaleAspectFit
        emptyImageView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyTitleLabel.text = "No Followed Venues"
        emptyTitleLabel.textColor = .white
        emptyTitleLabel.font = Constant.Font.geistMedium(size: 18)
        emptyTitleLabel.textAlignment = .center
        
        emptySubTitleLabel.text = "Venues you follow will appear here."
        emptySubTitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        emptySubTitleLabel.font = Constant.Font.geistRegular(size: 15)
        emptySubTitleLabel.textAlignment = .center
        
        let stack = UIStackView(
            arrangedSubviews: [
                emptyImageView,
                emptyTitleLabel,
                emptySubTitleLabel
            ]
        )
        
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        emptyView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            
            emptyView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stack.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -70),
            
            emptyImageView.widthAnchor.constraint(equalToConstant: 120),
            emptyImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func updateEmptyState() {

        let isEmpty =
            !isInitialLoading &&
            venues.isEmpty

        emptyView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
}

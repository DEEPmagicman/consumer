//
//  EventDetailsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 05/02/26.
//

import UIKit
import MapKit

class EventDetailsVC: UIViewController {

    @IBOutlet weak var guestListCollectionView: UICollectionView!
    @IBOutlet weak var detailsLbl: UILabel!
    @IBOutlet weak var youTubePlayerView: UIView!
    @IBOutlet weak var imageListView: UIView!
    @IBOutlet weak var lineUpCollectionView: UICollectionView!
    @IBOutlet weak var policyLbl: UILabel!
    @IBOutlet weak var faqsTableView: UITableView!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var venueAddressLbl: UILabel!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var viewGuestListBtn: UIButton!
    
    private var imagePagerVC: ImagePagerVC?
    private let guestCount = 12
    private let lineUpCount = 6
    private let faqCount = 5

    override func viewDidLoad() {
        super.viewDidLoad()
//        setupCollectionViews()
//        setupTableView()
//        setupImagePager()
    }
}


import UIKit

class ImagePageVC: UIViewController {

    private let imageView = UIImageView()
    var imageURL: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
    }

    private func setupUI() {
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
    }

    private func loadImage() {
        guard let imageURL,
              let url = URL(string: imageURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }.resume()
    }
}


extension EventDetailsVC {

    func setupCollectionViews() {
        guestListCollectionView.delegate = self
        guestListCollectionView.dataSource = self
        guestListCollectionView.register(
            EventGuestListCVC.nib,
            forCellWithReuseIdentifier: EventGuestListCVC.identifier
        )

        if let layout = guestListCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }

        // Lineup
        lineUpCollectionView.delegate = self
        lineUpCollectionView.dataSource = self
        lineUpCollectionView.register(
            EventLineUpCVC.nib,
            forCellWithReuseIdentifier: EventLineUpCVC.identifier
        )

        if let layout = lineUpCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
    }

    func setupTableView() {
        faqsTableView.delegate = self
        faqsTableView.dataSource = self
        faqsTableView.register(
            FAQsTableViewCell.nib,
            forCellReuseIdentifier: FAQsTableViewCell.identifier
        )
        faqsTableView.tableFooterView = UIView()
        faqsTableView.estimatedRowHeight = 80
        faqsTableView.rowHeight = UITableView.automaticDimension
    }
}

extension EventDetailsVC: UICollectionViewDelegate,
                          UICollectionViewDataSource,
                          UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        if collectionView == guestListCollectionView {
            return guestCount
        } else {
            return lineUpCount
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if collectionView == guestListCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EventGuestListCVC.identifier,
                for: indexPath
            ) as! EventGuestListCVC
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EventLineUpCVC.identifier,
            for: indexPath
        ) as! EventLineUpCVC
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        if collectionView == guestListCollectionView {
            return CGSize(width: 40, height: 40)
        } else {
            return CGSize(width: 140, height: 180)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}

extension EventDetailsVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return faqCount
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as! FAQsTableViewCell
        return cell
    }
}

extension EventDetailsVC {

    func setupImagePager() {

        let images = [
            "https://picsum.photos/800/600?1",
            "https://picsum.photos/800/600?2",
            "https://picsum.photos/800/600?3"
        ]

        let pagerVC = ImagePagerVC(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pagerVC.imageURLs = images

        addChild(pagerVC)
        pagerVC.view.frame = imageListView.bounds
        pagerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageListView.addSubview(pagerVC.view)
        pagerVC.didMove(toParent: self)

        imagePagerVC = pagerVC
    }
}



import UIKit

class ImagePagerVC: UIPageViewController {

    var imageURLs: [String] = []
    private var pages: [ImagePageVC] = []
    private(set) var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setupPages()
    }

    private func setupPages() {
        pages = imageURLs.map { url in
            let vc = ImagePageVC()
            vc.imageURL = url
            return vc
        }

        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: false)
        }
    }

    func moveNext() {
        guard currentIndex < pages.count - 1 else { return }
        currentIndex += 1
        setViewControllers([pages[currentIndex]], direction: .forward, animated: true)
    }

    func movePrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        setViewControllers([pages[currentIndex]], direction: .reverse, animated: true)
    }
}

extension ImagePagerVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(of: vc),
              index > 0 else { return nil }

        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {

        guard let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(of: vc),
              index < pages.count - 1 else { return nil }

        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        guard completed,
              let visibleVC = viewControllers?.first,
              let index = pages.firstIndex(of: visibleVC as! ImagePageVC) else { return }

        currentIndex = index
    }
}


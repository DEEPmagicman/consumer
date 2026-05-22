//
//  NewLandingVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 21/05/26.
//

import UIKit
import SDWebImage

final class NewLandingVC: UIViewController {

    private let bgView = UIView()

    private let headerView = UIView()
    private let profileTapButton = UIButton(type: .system)
    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    private let pageTitleLbl = UILabel()
    private let mapButtonContainer = LiquidGlassBackgroundView()
    private let mapButton = UIButton(type: .system)
    private let mapIconView = UIImageView()

    private let contentContainer = UIView()
    private let customTabBar = FloatingCustomTabBar()

    private lazy var discoverVC: DiscoverVC = {
        StoryboardAndXibManager.StoryBoard.discover.instantiateVC(DiscoverVC.self)
    }()

    private lazy var experiencesVC: PhotosVC = {
        StoryboardAndXibManager.StoryBoard.photos.instantiateVC(PhotosVC.self)
    }()

    private lazy var searchVC: SearchVC = {
        StoryboardAndXibManager.StoryBoard.search.instantiateVC(SearchVC.self)
    }()

    private lazy var tabs: [UIViewController] = [
        discoverVC,
        experiencesVC,
        searchVC
    ]

    private var selectedIndex = 0
    private var currentVC: UIViewController?
    private var systemTabVC: UITabBarController?

    override func viewDidLoad() {
        super.viewDidLoad()

       if AppDesign.useModernIOS26Design {
           setupSystemLanding()
       } else {
           setupCustomLanding()
       }

        setupUserData()
        observeProfileUpdate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bgView.applyScreenBgGradient()
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
        firstNameLetter.clipsToBounds = true
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
        mapButtonContainer.layer.cornerRadius = mapButtonContainer.bounds.height / 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - iOS 26 System Tab
    private func setupSystemLanding() {
        setupCommonBackground()
        setupHeader()

        let tabVC = UITabBarController()
        systemTabVC = tabVC

        let discover = makeSystemNav(
            root: discoverVC,
            title: "Discover",
            image: UIImage(resource: .discoverIconV3)
        )

        let experiences = makeSystemNav(
            root: experiencesVC,
            title: "Experiences",
            image: UIImage(resource: .experiencesIcon)
        )

        let search = makeSystemNav(
            root: searchVC,
            title: "Search",
            image: UIImage(resource: .searchIconV3)
        )

        tabVC.viewControllers = [discover, experiences, search]
        tabVC.selectedIndex = 0
        tabVC.delegate = self

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(hex: "#191919").withAlphaComponent(0.65)

        let selectedColor = UIColor(hex: "#85B2E8")
        let normalColor = AppColor.primaryWhiteColor.withAlphaComponent(0.72)

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: Constant.Font.geistMedium(size: 10)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: Constant.Font.geistMedium(size: 10)
        ]

        tabVC.tabBar.standardAppearance = appearance
        tabVC.tabBar.scrollEdgeAppearance = appearance
        tabVC.tabBar.tintColor = selectedColor
        tabVC.tabBar.unselectedItemTintColor = normalColor

        addChild(tabVC)
        tabVC.view.backgroundColor = .clear
        tabVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabVC.view)

        NSLayoutConstraint.activate([
            tabVC.view.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tabVC.didMove(toParent: self)
    }

//    @available(iOS 26.0, *)
    private func makeSystemNav(
        root: UIViewController,
        title: String,
        image: UIImage?
    ) -> UINavigationController {
        root.title = title

        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.isHidden = true

        nav.tabBarItem = UITabBarItem(
            title: title,
            image: image,
            selectedImage: image
        )

        return nav
    }

    // MARK: - iOS 16/17/18 Custom Tab

    private func setupCustomLanding() {
        setupCommonBackground()
        setupHeader()
        setupCustomContent()
        setupCustomTabBar()
        selectTab(index: 0)
    }
    
    private func setupCommonBackground() {
        view.backgroundColor = AppColor.primaryBlackColor

        bgView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(bgView, at: 0)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: view.topAnchor),
            bgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        avatarContainer.backgroundColor = .clear
        avatarContainer.clipsToBounds = true
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(avatarContainer)

        signInIconView.image = UIImage(resource: .profileIcon)
        signInIconView.contentMode = .scaleAspectFit
        signInIconView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(signInIconView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(imageView)

        firstNameLetter.textColor = AppColor.primaryWhiteColor
        firstNameLetter.backgroundColor = .clear
        firstNameLetter.textAlignment = .center
        firstNameLetter.font = Constant.Font.interRegular(size: 16)
        firstNameLetter.isHidden = true
        firstNameLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(firstNameLetter)

        pageTitleLbl.text = "Sign in"
        pageTitleLbl.textColor = AppColor.primaryWhiteColor
        pageTitleLbl.font = Constant.Font.geistMedium(size: 16)
        pageTitleLbl.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(pageTitleLbl)

        profileTapButton.backgroundColor = .clear
        profileTapButton.addTarget(self, action: #selector(onClickProfile), for: .touchUpInside)
        profileTapButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(profileTapButton)

        avatarContainer.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(onClickProfile))
        avatarContainer.addGestureRecognizer(avatarTap)

        imageView.isUserInteractionEnabled = true
        firstNameLetter.isUserInteractionEnabled = true
        signInIconView.isUserInteractionEnabled = true
        
        mapButtonContainer.cornerRadius = 16
        mapButtonContainer.borderWidth = 0.5
        mapButtonContainer.overrideBackgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.08)
        mapButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(mapButtonContainer)

        mapIconView.image = UIImage(named: "mapIcon")
        mapIconView.tintColor = AppColor.primaryWhiteColor
        mapIconView.contentMode = .scaleAspectFit
        mapIconView.translatesAutoresizingMaskIntoConstraints = false
        mapButtonContainer.addSubview(mapIconView)

        mapButton.backgroundColor = .clear
        mapButton.addTarget(self, action: #selector(onClickMap), for: .touchUpInside)
        mapButton.translatesAutoresizingMaskIntoConstraints = false
        mapButtonContainer.addSubview(mapButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            avatarContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            avatarContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            avatarContainer.widthAnchor.constraint(equalToConstant: 30),
            avatarContainer.heightAnchor.constraint(equalToConstant: 30),

            signInIconView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            signInIconView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            signInIconView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            signInIconView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            firstNameLetter.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            firstNameLetter.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            firstNameLetter.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            firstNameLetter.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            pageTitleLbl.leadingAnchor.constraint(equalTo: avatarContainer.trailingAnchor, constant: 12),
            pageTitleLbl.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor),
            pageTitleLbl.trailingAnchor.constraint(lessThanOrEqualTo: mapButtonContainer.leadingAnchor, constant: -12),

            profileTapButton.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            profileTapButton.trailingAnchor.constraint(equalTo: pageTitleLbl.trailingAnchor, constant: 12),
            profileTapButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            profileTapButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            mapButtonContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            mapButtonContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            mapButtonContainer.widthAnchor.constraint(equalToConstant: 32),
            mapButtonContainer.heightAnchor.constraint(equalToConstant: 32),

            mapIconView.centerXAnchor.constraint(equalTo: mapButtonContainer.centerXAnchor),
            mapIconView.centerYAnchor.constraint(equalTo: mapButtonContainer.centerYAnchor),
            mapIconView.widthAnchor.constraint(equalToConstant: 13),
            mapIconView.heightAnchor.constraint(equalToConstant: 13),

            mapButton.topAnchor.constraint(equalTo: mapButtonContainer.topAnchor),
            mapButton.leadingAnchor.constraint(equalTo: mapButtonContainer.leadingAnchor),
            mapButton.trailingAnchor.constraint(equalTo: mapButtonContainer.trailingAnchor),
            mapButton.bottomAnchor.constraint(equalTo: mapButtonContainer.bottomAnchor)
        ])
    }

    private func setupCustomContent() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCustomTabBar() {
        customTabBar.delegate = self
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBar)

        let isSmallDevice = UIScreen.main.bounds.width <= 375
        let tabHeight: CGFloat = isSmallDevice ? 56 : 64
        let sidePadding: CGFloat = isSmallDevice ? 14 : 24

        customTabBar.configure(items: [
            FloatingTabItem(title: "Discover", icon: UIImage(resource: .discoverIcon)),
            FloatingTabItem(title: "Experiences", icon: UIImage(resource: .experiencesIcon)),
            FloatingTabItem(title: "Search", icon: UIImage(resource: .searchIcon))
        ])

        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -2),
            customTabBar.heightAnchor.constraint(equalToConstant: tabHeight)
        ])
    }

    private func selectTab(index: Int) {
        guard index >= 0, index < tabs.count else { return }
        guard selectedIndex != index || currentVC == nil else { return }

        let oldVC = currentVC
        let newVC = tabs[index]

        addChild(newVC)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(newVC.view)

        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        newVC.view.alpha = 0
        newVC.view.transform = CGAffineTransform(translationX: index > selectedIndex ? 20 : -20, y: 0)

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            newVC.view.alpha = 1
            newVC.view.transform = .identity
            oldVC?.view.alpha = 0
            oldVC?.view.transform = CGAffineTransform(translationX: index > self.selectedIndex ? -20 : 20, y: 0)
        } completion: { _ in
            oldVC?.willMove(toParent: nil)
            oldVC?.view.removeFromSuperview()
            oldVC?.removeFromParent()
            newVC.didMove(toParent: self)
        }

        currentVC = newVC
        selectedIndex = index
        customTabBar.setSelected(index: index)
        mapButtonContainer.isHidden = index != 0
    }

    // MARK: - User

    private func observeProfileUpdate() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onProfileUpdated),
            name: .userProfileDidUpdate,
            object: nil
        )
    }

    @objc private func onProfileUpdated() {
        setupUserData()
    }

    private func setupUserData() {
        guard let user = UserDefault.shared.user else {
            imageView.isHidden = true
            firstNameLetter.isHidden = true
            signInIconView.isHidden = false
            pageTitleLbl.text = "Sign in"
            return
        }

        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")

        signInIconView.isHidden = true
        pageTitleLbl.text = user.firstName.isEmpty ? "Profile" : user.firstName

        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(resource: .profileIcon)
            )
        } else {
            imageView.isHidden = false
            if let _ = user.firstName.first {
                imageView.image = UIImage(resource: .signInBgIcon)
                firstNameLetter.isHidden = false
            } else {
                imageView.image = UIImage(resource: .profileIcon)
                firstNameLetter.isHidden = true
            }
            firstNameLetter.text = String(firstLetter).uppercased()
        }
    }
    
    @objc private func onClickProfile() {
        if UserDefault.shared.isLoggedIn == true {
            Navigate.to.profileMenuVC(self)
        } else {
            Navigate.to.openPhoneLoginPopup(self)
        }
    }

    @objc private func onClickMap() {
        Navigate.to.gotoMapVC(self)
    }
}

@available(iOS 26.0, *)
extension NewLandingVC: UITabBarControllerDelegate {}

extension NewLandingVC: FloatingCustomTabBarDelegate {
    func floatingCustomTabBar(_ tabBar: FloatingCustomTabBar, didSelect index: Int) {
        selectTab(index: index)
    }
}

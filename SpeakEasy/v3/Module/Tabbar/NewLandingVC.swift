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

    private let profileTapButton = UIButton(type: .system)
    private let avatarContainer = UIView()
    private let imageView = UIImageView()
    private let firstNameLetter = UILabel()
    private let signInIconView = UIImageView()
    private let pageTitleLbl = UILabel()
    private let mapIconView = UIImageView()

    private let contentContainer = UIView()
    private let customTabBar = FloatingCustomTabBar()

    private lazy var discoverVC: DiscoverVC = {
        StoryboardAndXibManager.StoryBoard.discover.instantiateVC(DiscoverVC.self)
    }()

    private lazy var experiencesVC: PremiumExpVC = PremiumExpVC()

    private lazy var searchVC: PremiumSearchVC = PremiumSearchVC()
    
    private lazy var myOrdersVC: MyOrdersVC = MyOrdersVC()

    private lazy var tabs: [UIViewController] = [
        discoverVC,
        experiencesVC,
        myOrdersVC,
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
        observePremiumTabRequests()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bgView.applyScreenBgGradient()
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        firstNameLetter.layer.cornerRadius = firstNameLetter.bounds.height / 2
        firstNameLetter.clipsToBounds = true
        avatarContainer.layer.cornerRadius = avatarContainer.bounds.height / 2
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - iOS 26 System Tab
    private func setupSystemLanding() {
        setupCommonBackground()
//        setupHeader()

        let tabVC = UITabBarController()
        systemTabVC = tabVC

        let discover = makeSystemNav(
            root: discoverVC,
            title: "Discover",
            image: UIImage(resource: .discoverIconV3)
        )

        let experiences = makeSystemNav(
            root: experiencesVC,
            title: "Premium",
            image: UIImage(resource: .experiencesIcon)
        )

        let orders = makeSystemNav(
            root: myOrdersVC,
            title: "Orders",
            image: UIImage(resource: .ordersIcon)
        )
        
        let search = makeSystemNav(
            root: searchVC,
            title: "Search",
            image: UIImage(resource: .searchIconV3)
        )

        tabVC.viewControllers = [discover, experiences, orders, search]
        tabVC.selectedIndex = 0
        if #available(iOS 26.0, *) {
            tabVC.delegate = self
        } else {
            // Fallback on earlier versions
        }
        
        let selectedColor = UIColor(hex: "#8CB7FF")
        let normalColor = UIColor(hex: "#D1D1D1")
        tabVC.tabBar.tintColor = selectedColor
        tabVC.tabBar.unselectedItemTintColor = normalColor

        addChild(tabVC)
        tabVC.view.backgroundColor = .clear
        tabVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabVC.view)

        NSLayoutConstraint.activate([
            tabVC.view.topAnchor.constraint(equalTo: view.topAnchor),
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
        nav.delegate = self
        
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
    
    private func setupCustomContent() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
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
            FloatingTabItem(title: "Discover", icon: UIImage(resource: .discoverIconV3)),
            FloatingTabItem(title: "Premium", icon: UIImage(resource: .experiencesIcon)),
            FloatingTabItem(title: "Search", icon: UIImage(resource: .searchIconV3))
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

    private func observePremiumTabRequests() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onOpenPremiumTabRequest(_:)),
            name: .openPremiumTabFromDiscover,
            object: nil
        )
    }

    @objc private func onProfileUpdated() {
        setupUserData()
    }

    @objc private func onOpenPremiumTabRequest(_ notification: Notification) {
        let city = notification.userInfo?["city"] as? String
        experiencesVC.applyCity(city)

        if let systemTabVC {
            systemTabVC.selectedIndex = 1
        } else {
            selectTab(index: 1)
        }
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

extension NewLandingVC: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        
        let isRoot = navigationController.viewControllers.count <= 1
        
        systemTabVC?.tabBar.isHidden = !isRoot
    }
    
}

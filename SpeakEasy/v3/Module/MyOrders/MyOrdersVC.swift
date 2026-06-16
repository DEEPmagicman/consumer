//
//  MyOrdersVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 25/05/26.
//

import UIKit

final class MyOrdersVC: UIViewController {

    private let backBtn = AppIconButton()
    private let titleLabel = UILabel()

    private let segmentView = OrdersSegmentView()
    private let pageVC = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    private lazy var ticketsVC = TicketsOrdersVC()
    private lazy var tablesVC = TablesOrdersVC()

    private let landingHeaderView = LandingHeaderView()
    private var segmentTopConstraint: NSLayoutConstraint!
    
    var showsBackButtonHeader: Bool = false
    
    private var pages: [UIViewController] {
        [ticketsVC, tablesVC]
    }

    private var selectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
    }

    private func setupUI() {
        setupLandingHeader()
        setupNav()
        setupSegment()
        setupPageVC()
        setupConstraints()
        updateHeaderUI()
    }
    
    private func updateHeaderUI() {

        landingHeaderView.isHidden = showsBackButtonHeader

        backBtn.isHidden = !showsBackButtonHeader
        titleLabel.isHidden = !showsBackButtonHeader
    }
    
    private func setupLandingHeader() {

        landingHeaderView.setMapHidden(false)
        landingHeaderView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(landingHeaderView)

        NSLayoutConstraint.activate([
            landingHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            landingHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            landingHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            landingHeaderView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupNav() {
        // Back button styling
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 14
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)

        // Title styling
        titleLabel.text = "My orders"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 22)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }

    private func setupSegment() {
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        segmentView.onIndexChanged = { [weak self] index in
            self?.moveToPage(index)
        }
        view.addSubview(segmentView)
    }

    private func setupPageVC() {
        addChild(pageVC)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)

        pageVC.dataSource = self
        pageVC.delegate = self

        pageVC.setViewControllers(
            [ticketsVC],
            direction: .forward,
            animated: false
        )
    }

    private func setupConstraints() {
        let headerBottomAnchor = showsBackButtonHeader
            ? titleLabel.bottomAnchor
            : landingHeaderView.bottomAnchor
        let headerTopConstant = showsBackButtonHeader ? 20 : 10
        let headerRightConstant = showsBackButtonHeader ? 22 : 16
        
        NSLayoutConstraint.activate([
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),

            segmentView.topAnchor.constraint(equalTo: headerBottomAnchor, constant: CGFloat(headerTopConstant)),
            segmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(headerRightConstant)),
            segmentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CGFloat(headerRightConstant)),
            segmentView.heightAnchor.constraint(equalToConstant: 48),

            pageVC.view.topAnchor.constraint(equalTo: segmentView.bottomAnchor, constant: 10),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func moveToPage(_ index: Int) {
        guard index != selectedIndex else { return }

        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse
        selectedIndex = index

        pageVC.setViewControllers(
            [pages[index]],
            direction: direction,
            animated: true
        )

        segmentView.setSelectedIndex(index, animated: true)
    }

    @objc private func onClickBack() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Page Controller

extension MyOrdersVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(of: currentVC)
        else { return }

        selectedIndex = index
        segmentView.setSelectedIndex(index, animated: true)
    }
}

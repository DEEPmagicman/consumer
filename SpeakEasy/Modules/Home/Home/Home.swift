//
//  Home.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

final class Home: BaseController {
    
    @IBOutlet private weak var homeTabCollectionView: UICollectionView!
    @IBOutlet private weak var viewPageMenu: UIView!
    @IBOutlet private weak var lblCity: UILabelDeviceClass!
    
    private var arrTabBarOptions = [TabBarOption(label: Strings.EVENTS.text, index: 0, icon: UIImage(named: "EventsTab"), selectedIcon: UIImage(named: "EventsTabSelected"), isSelected: true),
                            TabBarOption(label: Strings.VENUE_AND_VIP.text, index: 1, icon: UIImage(named: "VenueAndVIPTab"), selectedIcon: UIImage(named: "VenueAndVIPTabSelected"), isSelected: false),
                            TabBarOption(label: Strings.HEAT_MAP.text, index: 2, icon: UIImage(named: "HeatMapTab"), selectedIcon: UIImage(named: "HeatMapTabSelected"), isSelected: false)]
    
    private var selectedIndex = 0
    private var pageMenu: CAPSPageMenu?
    private var pageMenuControllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setPageMenu()
    }
    
    @IBAction private func onBtnChangeLocation(_ sender: UIButton) {
        navigationController?.pushViewController(NotificationVC(), animated: true)
    }
    @IBAction private func onBtnSearch(_ sender: UIButton) {
        navigationController?.pushViewController(Search(), animated: true)
    }
    @IBAction private func onBtnNotifications(_ sender: UIButton) {
        navigationController?.pushViewController(NotificationCitySelection(), animated: true)
    }
}
//MARK: - Helper Methods
private extension Home {
     func setUI() {
        lblCity.text = Constants.localizedCity
        registerCells()
    }
    
    func registerCells() {
        homeTabCollectionView.register(UINib(nibName: "HomeTabCVC", bundle: nil), forCellWithReuseIdentifier: "HomeTabCVC")
    }

    func setPageMenu() {
        if pageMenu == nil {
            let events = getNavigationContainer(controller: Events())
            let venues = getNavigationContainer(controller: VenuesAndVIP())
            let heatMap = getNavigationContainer(controller: HeatMap())
            
            pageMenuControllers.append(events)
            pageMenuControllers.append(venues)
            pageMenuControllers.append(heatMap)
            
            let parameters: [CAPSPageMenuOption] = [
                .menuItemSeparatorWidth(0),
                .menuItemSeparatorPercentageHeight(0),
                .menuHeight(0),
                .bottomMenuHairlineColor(.clear),
                .scrollAnimationDurationOnMenuItemTap(0)
            ]
            pageMenu = CAPSPageMenu(viewControllers: pageMenuControllers, frame: CGRect(x: 0.0, y: 0.0, width: viewPageMenu.frame.width, height: viewPageMenu.frame.height), pageMenuOptions: parameters)
            
            guard let pageMenu = self.pageMenu else { return }
            pageMenu.controllerScrollView.isScrollEnabled = false
            
            viewPageMenu.addSubview(pageMenu.view)
        }
    }
}
//MARK: - Container controllers
extension Home {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
extension Home: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case homeTabCollectionView:
            return arrTabBarOptions.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case homeTabCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeTabCVC", for: indexPath) as! HomeTabCVC
            let data = arrTabBarOptions[indexPath.item]
            cell.setData(data: data)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}
extension Home: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/3
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension Home: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case homeTabCollectionView:
            if selectedIndex != indexPath.item {
                for index in 0..<arrTabBarOptions.count {
                    arrTabBarOptions[index].isSelected = false
                }
                arrTabBarOptions[indexPath.item].isSelected = true
                selectedIndex = indexPath.item
                collectionView.reloadData()
                
                pageMenu?.moveToPage(selectedIndex)
            }
            
        default:
            return
        }
    }
}

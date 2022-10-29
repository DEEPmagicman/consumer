//
//  Home.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

class Home: BaseController {
    
    @IBOutlet weak var homeTabCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    @IBOutlet weak var lblCity: UILabelDeviceClass!
    
    var arrTabBarOptions = [TabBarOption(label: Strings.EVENTS.text, index: 0, icon: UIImage(named: "EventsTab"), selectedIcon: UIImage(named: "EventsTabSelected"), isSelected: true),
                            TabBarOption(label: Strings.VENUE_AND_VIP.text, index: 1, icon: UIImage(named: "VenueAndVIPTab"), selectedIcon: UIImage(named: "VenueAndVIPTabSelected"), isSelected: false),
                            TabBarOption(label: Strings.HEAT_MAP.text, index: 2, icon: UIImage(named: "HeatMapTab"), selectedIcon: UIImage(named: "HeatMapTabSelected"), isSelected: false)]
    
    var selectedIndex = 0
    var pageMenu: CAPSPageMenu?
    var pageMenuControllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setPageMenu()
    }
    
    @IBAction func onBtnChangeLocation(_ sender: UIButton) {
        self.navigationController?.pushViewController(NotificationVC(), animated: true)
    }
    @IBAction func onBtnSearch(_ sender: UIButton) {
        self.navigationController?.pushViewController(Search(), animated: true)
    }
    @IBAction func onBtnNotifications(_ sender: UIButton) {
        self.navigationController?.pushViewController(NotificationCitySelection(), animated: true)
    }
}
//MARK: - Helper Methods
extension Home {
    private func setUI(){
        self.lblCity.text = Constants.localizedCity
        self.registerCells()
    }
    private func registerCells(){
        self.homeTabCollectionView.register(UINib(nibName: "HomeTabCVC", bundle: nil), forCellWithReuseIdentifier: "HomeTabCVC")
    }
}
extension Home {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let events = self.getNavigationContainer(controller: Events())
            let venues = self.getNavigationContainer(controller: VenuesAndVIP())
            let heatMap = self.getNavigationContainer(controller: HeatMap())
            
            self.pageMenuControllers.append(events)
            self.pageMenuControllers.append(venues)
            self.pageMenuControllers.append(heatMap)
            
            let parameters: [CAPSPageMenuOption] = [
                .menuItemSeparatorWidth(0),
                .menuItemSeparatorPercentageHeight(0),
                .menuHeight(0),
                .bottomMenuHairlineColor(.clear),
                .scrollAnimationDurationOnMenuItemTap(0)
            ]
            self.pageMenu = CAPSPageMenu(viewControllers: self.pageMenuControllers, frame: CGRect(x: 0.0, y: 0.0, width: self.viewPageMenu.frame.width, height: self.viewPageMenu.frame.height), pageMenuOptions: parameters)
            
            guard let pageMenu = self.pageMenu else {return}
            pageMenu.controllerScrollView.isScrollEnabled = false
            
            self.viewPageMenu.addSubview(pageMenu.view)
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
        case self.homeTabCollectionView:
            return self.arrTabBarOptions.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.homeTabCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeTabCVC", for: indexPath) as! HomeTabCVC
            let data = self.arrTabBarOptions[indexPath.item]
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
        case self.homeTabCollectionView:
            if self.selectedIndex != indexPath.item {
                for index in 0..<self.arrTabBarOptions.count {
                    self.arrTabBarOptions[index].isSelected = false
                }
                self.arrTabBarOptions[indexPath.item].isSelected = true
                self.selectedIndex = indexPath.item
                collectionView.reloadData()
                
                self.pageMenu?.moveToPage(self.selectedIndex)
            }
            
        default:
            return
        }
    }
}

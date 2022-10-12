//
//  AllVenues.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 16/09/2022.
//

import UIKit

class AllVenues: BaseController {

    @IBOutlet weak var homeTabCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    
    var arrTabBarOptions = [TabBarOption(label: Strings.FEATURED.text, index: 0, icon: UIImage(named: "featured"), selectedIcon: nil, isSelected: true),
                            TabBarOption(label: Strings.CITY_VIEWS.text, index: 1, icon: UIImage(named: "cityviews"), selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.ROOFTOP.text, index: 2, icon: UIImage(named: "rooftop"), selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.WATERFRONT.text, index: 3, icon: UIImage(named: "waterfront"), selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.STEAKHOUSE.text, index: 4, icon: UIImage(named: "steakhouse"), selectedIcon: nil, isSelected: false)]



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
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
//MARK: - Helper Methods
extension AllVenues {
    private func setUI(){
        self.registerCells()
    }
    private func registerCells(){
        self.homeTabCollectionView.register(UINib(nibName: "TabVenueCVC", bundle: nil), forCellWithReuseIdentifier: "TabVenueCVC")
    }
}
extension AllVenues {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let featured = self.getNavigationContainer(controller: FeaturedVenue())
            let cityviews = self.getNavigationContainer(controller: FeaturedVenue())
            let rooftop = self.getNavigationContainer(controller: FeaturedVenue())
            let waterfront = self.getNavigationContainer(controller: FeaturedVenue())
            let steakhouse = self.getNavigationContainer(controller: FeaturedVenue())

            
            self.pageMenuControllers.append(featured)
            self.pageMenuControllers.append(cityviews)
            self.pageMenuControllers.append(rooftop)
            self.pageMenuControllers.append(waterfront)
            self.pageMenuControllers.append(steakhouse)

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
extension AllVenues {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
extension AllVenues: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrTabBarOptions.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabVenueCVC", for: indexPath) as! TabVenueCVC
        let data = self.arrTabBarOptions[indexPath.item]
        cell.setData(data: data)
        return cell
    }
}
extension AllVenues: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.homeTabCollectionView.frame.height
        let width = self.homeTabCollectionView.frame.width / 5
        let size = CGSize(width: width, height: height)
        return size
    }
}

extension AllVenues: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.selectedIndex != indexPath.item {
            for index in 0..<self.arrTabBarOptions.count {
                self.arrTabBarOptions[index].isSelected = false
            }
            self.arrTabBarOptions[indexPath.item].isSelected = true
            self.selectedIndex = indexPath.item
            collectionView.reloadData()
            
            self.pageMenu?.moveToPage(self.selectedIndex)
        }
    }
}

//
//  AccessPass.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 05/09/2022.
//

import UIKit

class Wallet: UIViewController {

    @IBOutlet weak var tabCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    
    var arrTabBarOptions = [TabBarOption(label: Strings.ACCESS_PASS.text, index: 0, icon: UIImage(named: "EventsTab"), selectedIcon: UIImage(named: "EventsTabSelected"), isSelected: true),
                            TabBarOption(label: Strings.NFT_ASSETS.text, index: 1, icon: UIImage(named: "VenueAndVIPTab"), selectedIcon: UIImage(named: "VenueAndVIPTabSelected"), isSelected: false)]
    
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
}
//MARK: - Helper Methods
extension Wallet{
    private func setUI(){
        self.registerCells()
    }
    private func registerCells(){
        self.tabCollectionView.register(UINib(nibName: "TabCVC", bundle: nil), forCellWithReuseIdentifier: "TabCVC")
    }
}
extension Wallet {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let accessPass = self.getNavigationContainer(controller: AccessPass())
            let nftAssets = self.getNavigationContainer(controller: NFTAssets())
            
            self.pageMenuControllers.append(accessPass)
            self.pageMenuControllers.append(nftAssets)
            
            let parameters: [CAPSPageMenuOption] = [
                .menuItemSeparatorWidth(0),
                .menuItemSeparatorPercentageHeight(0),
                .menuHeight(0),
                .bottomMenuHairlineColor(.clear),
                .scrollAnimationDurationOnMenuItemTap(0),
                .viewBackgroundColor(.clear)
            ]
            self.pageMenu = CAPSPageMenu(viewControllers: self.pageMenuControllers, frame: CGRect(x: 0.0, y: 0.0, width: self.viewPageMenu.frame.width, height: self.viewPageMenu.frame.height), pageMenuOptions: parameters)
            
            guard let pageMenu = self.pageMenu else {return}
            pageMenu.controllerScrollView.isScrollEnabled = false
            
            self.viewPageMenu.addSubview(pageMenu.view)
        }
    }
}
//MARK: - Container controllers
extension Wallet {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
extension Wallet: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.tabCollectionView:
            return self.arrTabBarOptions.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.tabCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCVC", for: indexPath) as! TabCVC
            let data = self.arrTabBarOptions[indexPath.item]
            cell.setData(data: data)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}
extension Wallet: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension Wallet: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        switch collectionView {
        case self.tabCollectionView:
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

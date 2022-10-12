//
//  PendingBookingAwait.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 03/09/2022.
//

import UIKit

class PendingBookingAwait: BaseController {
    
    @IBOutlet weak var homeTabCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    
    var arrTabBarOptions = [TabBarOption(label: Strings.BOOKING_DETAILS.text, index: 0, icon: UIImage(named: ""), selectedIcon: UIImage(named: ""), isSelected: true),
                            TabBarOption(label: Strings.MESSAGES.text, index: 1, icon: UIImage(named: ""), selectedIcon: UIImage(named: ""), isSelected: false)]
    
    var selectedIndex = 0
    var pageMenu: CAPSPageMenu?
    var pageMenuControllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setPageMenu()
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

//MARK: - Helper Methods
extension PendingBookingAwait {
    private func setUI(){
        self.registerCells()
    }
    private func registerCells(){
        self.homeTabCollectionView.register(UINib(nibName: "BookingTabCVCCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BookingTabCVCCollectionViewCell")
    }
}
extension PendingBookingAwait {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let bookingDetails = self.getNavigationContainer(controller: BookingDetails())
            let messages = self.getNavigationContainer(controller: Messages())
            
            self.pageMenuControllers.append(bookingDetails)
            self.pageMenuControllers.append(messages)
            
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
            self.viewPageMenu.clipsToBounds = true
            self.viewPageMenu.addSubview(pageMenu.view)
        }
    }
}
//MARK: - Container controllers
extension PendingBookingAwait {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
extension PendingBookingAwait: UICollectionViewDataSource {
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookingTabCVCCollectionViewCell", for: indexPath) as! BookingTabCVCCollectionViewCell
            let data = self.arrTabBarOptions[indexPath.item]
            cell.setData(data: data)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}
extension PendingBookingAwait: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension PendingBookingAwait: UICollectionViewDelegate {
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

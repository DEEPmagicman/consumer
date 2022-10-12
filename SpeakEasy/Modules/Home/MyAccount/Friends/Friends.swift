//
//  Friends.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 31/08/2022.
//

import UIKit

class Friends: BaseController {

    @IBOutlet weak var friendsCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    
    
    var selectedIndex = 0
    var pageMenu: CAPSPageMenu?
    var pageMenuControllers = [UIViewController]()
    
    var arrFriendsOptions = [TabBarOption(label: Strings.SEARCH_AND_ADD.text, index: 0, icon: UIImage(named: "EventsTab"), selectedIcon: UIImage(named: "EventsTabSelected"), isSelected: true),
                             TabBarOption(label: Strings.MANAGE_FRIENDS.text, index: 1, icon: UIImage(named: "VenueAndVIPTab"), selectedIcon: UIImage(named: "VenueAndVIPTabSelected"), isSelected: false)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setPageMenu()
    }
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true
        )
    }
    
}

//MARK: - Helper Methods
extension Friends {
    private func setUI(){
        self.registerCells()
    }
    private func registerCells(){
        self.friendsCollectionView.register(UINib(nibName: "BookingTabCVCCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BookingTabCVCCollectionViewCell")
    }
}

extension Friends {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let friendRequest = self.getNavigationContainer(controller: FriendRequest())
            let manageFriends = self.getNavigationContainer(controller: ManageFriends())
            
            self.pageMenuControllers.append(friendRequest)
            self.pageMenuControllers.append(manageFriends)
            
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
extension Friends {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
//MARK: - UICollectionViewDataSource
extension Friends: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.arrFriendsOptions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookingTabCVCCollectionViewCell", for: indexPath) as! BookingTabCVCCollectionViewCell
            let data = self.arrFriendsOptions[indexPath.item]
            cell.setFriendsData(data: data)
            return cell
    }
}
extension Friends: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension Friends: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if self.selectedIndex != indexPath.item {
            for index in 0..<self.arrFriendsOptions.count {
                self.arrFriendsOptions[index].isSelected = false
            }
            self.arrFriendsOptions[indexPath.item].isSelected = true
            self.selectedIndex = indexPath.item
            collectionView.reloadData()
            
            self.pageMenu?.moveToPage(self.selectedIndex)
        }
        else {
            (self.pageMenuControllers[self.selectedIndex] as? UINavigationController)?.popViewController(animated: true)
        }
    }
}


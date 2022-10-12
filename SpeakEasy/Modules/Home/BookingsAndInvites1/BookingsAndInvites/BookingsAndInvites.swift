//
//  BookingsAndInvites.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

class BookingsAndInvites: UIViewController {

    var arrTabBarOptions = [TabBarOption(label: Strings.BOOKINGS.text, count: 1, isSelected: true),
                            TabBarOption(label: Strings.INVITES.text, count: 2, isSelected: false)]
    var pageMenuControllers = [UIViewController]()
    var selectedIndex = 0
    var pageMenu: CAPSPageMenu?
    
    @IBOutlet weak var blblBookingInvite: UILabel!
    
    @IBOutlet weak var bookingCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCells()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setPageMenu()
    }
}

//MARK: Helper Method
extension BookingsAndInvites {
    private func registerCells(){
        self.bookingCollectionView.register(UINib(nibName: "ExtendedTabCVC", bundle: nil), forCellWithReuseIdentifier: "ExtendedTabCVC")
    }
}

extension BookingsAndInvites {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let bookings = self.getNavigationContainer(controller: Bookings())
            let venues = self.getNavigationContainer(controller: Invites())
            
            self.pageMenuControllers.append(bookings)
            self.pageMenuControllers.append(venues)
            
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
extension BookingsAndInvites {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
extension BookingsAndInvites: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.bookingCollectionView:
            return self.arrTabBarOptions.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.bookingCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExtendedTabCVC", for: indexPath) as! ExtendedTabCVC
            let data = self.arrTabBarOptions[indexPath.item]
            cell.setData(data: data)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}
extension BookingsAndInvites: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2.07
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension BookingsAndInvites: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {


        switch collectionView {
        case self.bookingCollectionView:
            if self.selectedIndex != indexPath.item {
                for index in 0..<self.arrTabBarOptions.count {
                    self.arrTabBarOptions[index].isSelected = false
                }
                self.arrTabBarOptions[indexPath.item].isSelected = true
                if self.arrTabBarOptions.first?.isSelected == true {
                    self.blblBookingInvite.text = "Upcoming"
                }else{
                    self.blblBookingInvite.text = "Active Invites"
                }
                self.selectedIndex = indexPath.item
                collectionView.reloadData()

                self.pageMenu?.moveToPage(self.selectedIndex)
            }

        default:
            return
        }
    }
}

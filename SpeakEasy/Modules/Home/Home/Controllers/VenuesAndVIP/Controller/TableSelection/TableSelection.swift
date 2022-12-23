//
//  TableSelection.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/6/22.
//

import UIKit

class TableSelection: UIViewController {
    
    @IBOutlet weak var tableCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    @IBOutlet weak var imgBrandLogo: UIImageView!
    
    var selectedIndex = 0
    var pageMenu: CAPSPageMenu?
    var pageMenuControllers = [UIViewController]()
    
    var arrTableSelectionOptions = [
        TabBarOption(label: "Main", index: 0, icon: nil, selectedIcon: nil, isSelected: true),
        TabBarOption(label: "Lotus", index: 1, icon: nil, selectedIcon: nil, isSelected: false),
        TabBarOption(label: "Chandelier", index: 2, icon: nil, selectedIcon: nil, isSelected: false)]
    
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
extension TableSelection {
    private func setUI(){
        self.registerCells()
        self.setData()
    }
    private func setData(){
        self.imgBrandLogo.image = VenueDetails.hotVenuesData?.imgBrandLogo
    }
    private func registerCells(){
        self.tableCollectionView.register(UINib(nibName: "TabCVC", bundle: nil), forCellWithReuseIdentifier: "TabCVC")
    }
}
//MARK: - Page Menu
extension TableSelection {
    private func setPageMenu(){
        if self.pageMenu == nil {
            
            let floor = Main1()
            floor.from = "main"
            let floorNavigation = self.getNavigationContainer(controller:  floor)
            
            let floor1 = Main1()
            floor1.from = "lotus"
            let floor1Navigation = self.getNavigationContainer(controller: floor1)

            let floor2 = Main1()
            floor2.from = "chandelier"
            let floor2Navigation = self.getNavigationContainer(controller:  floor2)
            
            
            self.pageMenuControllers.append(floorNavigation)
            self.pageMenuControllers.append(floor1Navigation)
            self.pageMenuControllers.append(floor2Navigation)
            
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
extension TableSelection {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
//MARK: - UICollectionViewDataSource
extension TableSelection: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrTableSelectionOptions.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCVC", for: indexPath) as! TabCVC
            let data = self.arrTableSelectionOptions[indexPath.item]
            cell.setData(data: data)
            return cell
    }
}
extension TableSelection: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15.0)
        
        let height = collectionView.frame.height
        
        let tabOption = self.arrTableSelectionOptions[indexPath.item].label
        let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
        
        let size = CGSize(width: width, height: height)
        return size
    }
}
extension TableSelection: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.selectedIndex != indexPath.item {
            for index in 0..<self.arrTableSelectionOptions.count {
                self.arrTableSelectionOptions[index].isSelected = false
            }
            self.arrTableSelectionOptions[indexPath.item].isSelected = true
            self.selectedIndex = indexPath.item
            collectionView.reloadData()
            
            self.pageMenu?.moveToPage(self.selectedIndex)
        }
    }
}

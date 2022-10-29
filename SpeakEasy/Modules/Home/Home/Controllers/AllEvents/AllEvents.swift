//
//  AllEvents.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 15/09/2022.
//

import UIKit

class AllEvents: BaseController {

    @IBOutlet weak var homeTabCollectionView: UICollectionView!
    @IBOutlet weak var viewPageMenu: UIView!
    @IBOutlet weak var lblCity: UILabelDeviceClass!
    
   
    var arrTabBarOptions = [TabBarOption(label: Strings.ALL.text, index: 0, icon: nil, selectedIcon: nil, isSelected: true),
                            TabBarOption(label: Strings.THIS_WEEK.text, index: 1, icon: nil, selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.CUSTOM_DATES.text, index: 2, icon: nil, selectedIcon: nil, isSelected: false)]

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
extension AllEvents {
    private func setUI(){
        self.registerCells()
        self.lblCity.text = Constants.localizedCity
    }
    private func registerCells(){
        self.homeTabCollectionView.register(UINib(nibName: "TabCVC", bundle: nil), forCellWithReuseIdentifier: "TabCVC")
    }
}
extension AllEvents {
    private func setPageMenu(){
        if self.pageMenu == nil {
            let events = self.getNavigationContainer(controller: All())
            let venues = self.getNavigationContainer(controller: All())
            let heatMap = self.getNavigationContainer(controller: All())
            
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
extension AllEvents {
    private func getNavigationContainer(controller: UIViewController)->UINavigationController{
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isHidden = true
        return navigationController
    }
}
extension AllEvents: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrTabBarOptions.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCVC", for: indexPath) as! TabCVC
        let data = self.arrTabBarOptions[indexPath.item]
        cell.setData(data: data)
        return cell
    }
}
extension AllEvents: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15.0)
        
        let height = collectionView.frame.height
        
        let tabOption = self.arrTabBarOptions[indexPath.item].label
        let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
        
        let size = CGSize(width: width, height: height)
        return size
    }
}

extension AllEvents: UICollectionViewDelegate {
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

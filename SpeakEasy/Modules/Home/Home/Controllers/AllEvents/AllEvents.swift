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
    @IBOutlet weak var eventCollectionView: UICollectionView!
    
   
    var arrTabBarOptions = [TabBarOption(label: Strings.ALL.text, index: 0, icon: nil, selectedIcon: nil, isSelected: true),
                            TabBarOption(label: Strings.THIS_WEEK.text, index: 1, icon: nil, selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.CUSTOM_DATES.text, index: 2, icon: nil, selectedIcon: nil, isSelected: false)]

    var selectedIndex = 0
    var eventDelegate = EventPresenter()
    var from = 0
    var hasMore = false
    var eventList = [Event]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.fetchAllEvent()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func fetchAllEvent() {
        self.eventDelegate.getEvents(from: self.from) { isSuccess, errMsg, eventList, hasMore in
            if isSuccess {
                for event in eventList {
                    self.eventList.append(event)
                }
                if hasMore {
                    self.from = self.eventList.count
                }
                self.hasMore = hasMore
                self.eventCollectionView.reloadData()
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }

    }
    
    @IBAction func onBtnChangeLocation(_ sender: UIButton) {
        self.navigationController?.pushViewController(HomeCitySelectionVC(), animated: true)
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
        self.eventCollectionView.register(UINib(nibName: "EventCVC", bundle: nil), forCellWithReuseIdentifier: "EventCVC")
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
        if collectionView == homeTabCollectionView {
            return self.arrTabBarOptions.count
        } else {
            if Constants.localizedCity == "Chicago" {
                return Constants.arrayAllEventsChicago.count
            }else {
                //            return Constants.arrayAllEventsCleveland.count
                return eventList.count
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == homeTabCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCVC", for: indexPath) as! TabCVC
            let data = self.arrTabBarOptions[indexPath.item]
            cell.setData(data: data)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventCVC", for: indexPath) as! EventCVC
            if Constants.localizedCity == "Chicago" {
                let data = Constants.arrayAllEventsChicago[indexPath.item]
                cell.setData(data: data)
                return cell
            }else {
                //            let data = Constants.arrayAllEventsCleveland[indexPath.item]
                let data = eventList[indexPath.row]
                cell.imgEventCover.sd_setImage(with: URL( string: (data.flyer?.key ?? "").imageURL), completed: nil)
                cell.lblPerformerName.text = data.title
                cell.lblVenueName.text = data.eventType
                let date = data.date.convertDateFormat(from: .YYYYMMDD, to: .EEEEMMMD)
                cell.lblEventDate.text = date
                //            cell.setData(data: data)
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == eventCollectionView {
            if indexPath.row == eventList.count - 1 {
                if self.hasMore {
                    self.fetchAllEvent()
                }
            }
        }
    }
}
extension AllEvents: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == homeTabCollectionView {
            let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15.0)
            
            let height = collectionView.frame.height
            
            let tabOption = self.arrTabBarOptions[indexPath.item].label
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
        } else {
            let width = collectionView.frame.width/2.07
            let size = CGSize(width: width, height: width * 1.43)
            return size
        }
        
    }
}

extension AllEvents: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == homeTabCollectionView {
            if self.selectedIndex != indexPath.item {
                for index in 0..<self.arrTabBarOptions.count {
                    self.arrTabBarOptions[index].isSelected = false
                }
                self.arrTabBarOptions[indexPath.item].isSelected = true
                self.selectedIndex = indexPath.item
                collectionView.reloadData()
                
                //            self.pageMenu?.moveToPage(self.selectedIndex)
                //TO DO handle collectionview tab change
            }
        } else {
            Navigate.to.eventDetail(self, eventId: eventList[indexPath.row].id )
        }
    }
}

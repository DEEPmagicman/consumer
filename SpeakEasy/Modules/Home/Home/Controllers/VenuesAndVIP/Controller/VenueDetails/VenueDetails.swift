//
//  VenueDetails.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

struct HoursDataSet {
    var day: String
    var time: String
}

struct DressCodeDataSet {
    var dressCode: String
}

class VenueDetails: UIViewController {
    
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    @IBOutlet weak var onBtnPhotos: UIButtonDeviceClass!
    @IBOutlet weak var constDressTVCHeight: NSLayoutConstraint!
    @IBOutlet weak var constHousTVCHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHours: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var venueCollectionView: UICollectionView!
    @IBOutlet weak var tableViewDressCode: UITableView!
    @IBOutlet weak var viewVenueDetails: UIView!
    @IBOutlet weak var lblVenueDescription: UILabelDeviceClass!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    @IBOutlet weak var imgBrandLogo: RoundedImage!
    //@IBOutlet weak var lblLocation: UILabelDeviceClass!
    //@IBOutlet weak var lblPhoneNumber: UILabelDeviceClass!
    @IBOutlet weak var vibesCollectionView: UICollectionView!
    
    var arrGallery = ["GeneralAdmissionBG1","GeneralAdmissionBG2","GeneralAdmissionBG3","GeneralAdmissionBG1","GeneralAdmissionBG2"]
    var arrHours: [HoursDataSet] = []
    var arrDressCode = [DressCodeDataSet(dressCode: "Smart casual"),
                        DressCodeDataSet(dressCode: "No shorts, baseball caps and athletic apparel"),
                        DressCodeDataSet(dressCode: "No large bags")]
    
    var arrTabBarOptions = [TabBarOption(label: Strings.VIP_AND_EVENTS.text, index: 0, icon: nil, selectedIcon: nil, isSelected: true),
                            TabBarOption(label: Strings.VENUE_DEAILS.text,   index: 1, icon: nil, selectedIcon: nil, isSelected: false)]
    
    var arrayTopEvents: [TopEventDataSet] = []
    
   static var hotVenuesData: VenuesVIPEventDataSet?
    
    var arrVibes = ["VIP Bottle Service","Strict Dress Code","Premium Bottles","Celebrity DJs",  "EDM", "Fashion Forward","Musical Variety", "Dress to Impress","Tables Recommended"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let newHeight : CGFloat = self.tableViewHours.contentSize.height
        self.constHousTVCHeight.constant = newHeight
        self.tableViewHours.layoutIfNeeded()
        tableViewHeightManagement(tableView: self.tableViewHours, heightConstraint: constHousTVCHeight)
        tableViewHeightManagement(tableView: self.tableViewDressCode, heightConstraint: constDressTVCHeight)
    }
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnAddress(_ sender: UIButton) {
        Utility.main.openMap(lat: 41.893600, lng: -87.629820)
    }
    @IBAction func onBtnBookVIPTable(_ sender: UIButtonDeviceClass) {
        Utility.main.topViewController()?.navigationController?.navigationController?.pushViewController(VIPTableBookingCalendar(), animated: true)
    }
    @IBAction func onBtnViewBottleMenu(_ sender: UIButtonDeviceClass) {
        self.navigationController?.pushViewController(BottleMenu(), animated: true)
    }
    @IBAction func onBtnPhoto(_ sender: UIButtonDeviceClass) {
        self.navigationController?.pushViewController(VenuePhotoGallery(), animated: true)
    }
}
//MARK: - Helper methods
extension VenueDetails{
    private func setUI() {
        registerCell()
        setData()
        addObservers(tableView: self.tableViewHours)
        addObservers(tableView: self.tableViewDressCode)
    }
    private func setData() {
        //self.lblLocation.text = VenueDetails.hotVenuesData?.location ?? ""
        //self.lblPhoneNumber.text = VenueDetails.hotVenuesData?.phoneNumber ?? ""
        self.lblTitle.text = VenueDetails.hotVenuesData?.lblPerformerName ?? ""
        self.imgBrandLogo.image = VenueDetails.hotVenuesData?.imgBrandLogo
        let imgEventCover = VenueDetails.hotVenuesData?.imgEventCover?.imageAsset?.value(forKey: "assetName") as? String ?? ""
        self.arrGallery[0] = imgEventCover
        self.arrayTopEvents = VenueDetails.hotVenuesData?.upcomingEvents ?? []
        self.lblVenueDescription.text = VenueDetails.hotVenuesData?.description
        self.arrHours = VenueDetails.hotVenuesData?.hours ?? []
        DispatchQueue.main.async {
            self.galleryCollectionView.reloadData()
        }
    }
    private func addObservers(tableView: UITableView) {
        tableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
    }
    private func tableViewHeightManagement(tableView : UITableView, heightConstraint: NSLayoutConstraint) {
        let newHeight : CGFloat = tableView.contentSize.height
        heightConstraint.constant = newHeight
        tableView.layoutIfNeeded()
    }
    private func registerCell(){
        self.galleryCollectionView.register(UINib(nibName: "GalleryCVC", bundle: nil), forCellWithReuseIdentifier: "GalleryCVC")
        self.collectionView.register(UINib(nibName: "TopEventCVC", bundle: nil), forCellWithReuseIdentifier: "TopEventCVC")
        self.venueCollectionView.register(UINib(nibName: "TabCVC", bundle: nil), forCellWithReuseIdentifier: "TabCVC")
        self.tableViewHours.register(UINib(nibName: "HoursTVC", bundle: nil), forCellReuseIdentifier: "HoursTVC")
        self.tableViewDressCode.register(UINib(nibName: "DressCodeTVC", bundle: nil), forCellReuseIdentifier: "DressCodeTVC")
        self.vibesCollectionView.register(UINib(nibName: "VibesCVC", bundle: nil), forCellWithReuseIdentifier: "VibesCVC")
    }
}
//MARK: - UICollectionViewDataSource
extension VenueDetails: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.galleryCollectionView:
            return self.arrGallery.count
        case self.venueCollectionView:
            return self.arrTabBarOptions.count
        case self.collectionView:
            return self.arrayTopEvents.count
        case self.vibesCollectionView:
            return self.arrVibes.count
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.galleryCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCVC", for: indexPath) as! GalleryCVC
            let data = self.arrGallery[indexPath.item]
            cell.setData(data: data)
            return cell
        case self.venueCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCVC", for: indexPath) as! TabCVC
            let data = self.arrTabBarOptions[indexPath.row]
            cell.setData(data: data)
            return cell
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopEventCVC", for: indexPath) as! TopEventCVC
            let data = self.arrayTopEvents[indexPath.item]
            cell.setData(data: data)
            return cell
        case self.vibesCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VibesCVC", for: indexPath) as! VibesCVC
            cell.lblVibes.text = arrVibes[indexPath.row]
            
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}
//MARK: - UICollectionViewDelegate
extension VenueDetails: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == venueCollectionView {
            if indexPath.item == 1 {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: self.viewVenueDetails.frame.minY - 100), animated: true)
            }
        }
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension VenueDetails: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case self.galleryCollectionView:
            let width = collectionView.frame.width
            let height = collectionView.frame.height
            let size = CGSize(width: width, height: height)
            return size
            
        case self.collectionView:
            let width = 250.0//collectionView.frame.width * 0.6
            let height = 290.0//collectionView.frame.height * 0.96
            let size = CGSize(width: width, height: height)
            return size
            
        case self.venueCollectionView:
            let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15.0)
            let height = collectionView.frame.height
            
            let tabOption = self.arrTabBarOptions[indexPath.item].label
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
        case vibesCollectionView:
            let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)
            let height = 40.0
            let tabOption = self.arrVibes[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 30.0
            let size = CGSize(width: width, height: height)
            return size
        default:
            return .zero
        }
    }
}
//MARK: - UITableViewDataSource
extension VenueDetails: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return arrHours.count
        }else {
            return arrDressCode.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case tableViewHours:
            let cell = tableViewHours.dequeueReusableCell(withIdentifier: "HoursTVC", for: indexPath) as! HoursTVC
            let data = arrHours[indexPath.row]
//            cell.setData(data: data)
            return cell
            
        case tableViewDressCode:
            let cell = tableViewDressCode.dequeueReusableCell(withIdentifier: "DressCodeTVC", for: indexPath) as! DressCodeTVC
            let data = arrDressCode[indexPath.row]
            cell.setData(data: data)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}
//MARK: - UITableViewDelegate
extension VenueDetails: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension
        default:
            let height = tableView.frame.height * 0.35
            
            if indexPath.row == 2 {
                return height + 60.0
            }
            else {
                return height
            }
        }
    }
}

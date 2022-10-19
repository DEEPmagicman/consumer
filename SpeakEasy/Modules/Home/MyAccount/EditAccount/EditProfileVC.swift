//
//  EditProfileVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 29/08/2022.
//

import UIKit
import DropDown

struct ImportantDates {
    
    var leftImage: String
    var rightImage: String?
    var title: String
    var month: String
    var day: String

}

class EditProfileVC: BaseController {

    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var vibesCollectionView: UICollectionView!
    @IBOutlet weak var favouriteDrinkCollectionView: UICollectionView!
    @IBOutlet weak var favouriteArtistCollectionView: UICollectionView!
    @IBOutlet weak var importantDatesTableView: UITableView!
    @IBOutlet weak var tfOccupation: UITextField!
    @IBOutlet weak var btnOccupation: UIButton!
    @IBOutlet weak var heightImportantDatesTableView: NSLayoutConstraint!
    @IBOutlet weak var heightVibesCollectionView: NSLayoutConstraint!
    @IBOutlet weak var heightFavouriteDrinkCollectionView: NSLayoutConstraint!
    @IBOutlet weak var heightFavouriteArtistCollectionView: NSLayoutConstraint!
    @IBOutlet weak var industryPrivateLbl: UILabelDeviceClass!
    @IBOutlet weak var industryPrivateLineView: UIView!
    @IBOutlet weak var industryPublicLbl: UILabelDeviceClass!
    @IBOutlet weak var industryPublicLineView: UIView!
    @IBOutlet weak var industryPrivateView: UIView!
    @IBOutlet weak var industryPublicView: UIView!
    @IBOutlet weak var socialMediaPrivateLbl: UILabelDeviceClass!
    @IBOutlet weak var socialMediaPrivateLineView: UIView!
    @IBOutlet weak var socialMediaPublicLbl: UILabelDeviceClass!
    @IBOutlet weak var socialMediaPublicLineView: UIView!
    @IBOutlet weak var socialMediaPrivateView: UIView!
    @IBOutlet weak var socialMediaPublicView: UIView!
    @IBOutlet weak var vibesPrivateLbl: UILabelDeviceClass!
    @IBOutlet weak var vibesPrivateLineView: UIView!
    @IBOutlet weak var vibesPublicLbl: UILabelDeviceClass!
    @IBOutlet weak var vibesPublicLineView: UIView!
    @IBOutlet weak var vibesPrivateView: UIView!
    @IBOutlet weak var vibesPublicView: UIView!
    @IBOutlet weak var favDrinksPrivateLbl: UILabelDeviceClass!
    @IBOutlet weak var favDrinksPrivateLineView: UIView!
    @IBOutlet weak var favDrinksPublicLbl: UILabelDeviceClass!
    @IBOutlet weak var favDrinksPublicLineView: UIView!
    @IBOutlet weak var favDrinksPrivateView: UIView!
    @IBOutlet weak var favDrinksPublicView: UIView!
    @IBOutlet weak var datePrivateLbl: UILabelDeviceClass!
    @IBOutlet weak var datePrivateLineView: UIView!
    @IBOutlet weak var datePublicLbl: UILabelDeviceClass!
    @IBOutlet weak var datePublicLineView: UIView!
    @IBOutlet weak var datePrivateView: UIView!
    @IBOutlet weak var datePublicView: UIView!
    
    var arrVibes = ["Fridays", "EDM", "Bottle Service","Crowds"]
    var arrFavouriteDrinks = ["Whiskey", "Dom Perignon", "Moscow Mule", "Whiskey Sour", "Martini", "Whiskey Coke"]
    var arrFavouriteArtists = ["Steve Aoki", "DJ Heavy", "Martin Garrix", "Armin van Buuren"]
    
    var arrImportantDates =
       [ImportantDates(leftImage: "YourBirthday", rightImage: nil, title: "My  Birthday", month: "September", day: "30"),
        ImportantDates(leftImage: "partnersBirthday", rightImage: "delete", title: "Partner’s  Birthday", month: "September", day: "30"),
        ImportantDates(leftImage: "ic-friends", rightImage: "delete", title: "Paul’s  Birthday", month: "September", day: "30")]

    private var isIndustryPublic = true
    private var isSocialMediaPublic = true
    private var isVibesPublic = true
    private var isFavDrinksPublic = true
    private var isDatePublic = true
    
    let occupationDropDown = DropDown()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.setPublicPrivate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addCollectionViewContentObservers()
        self.addTableViewContentObservers()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeCollectionViewContentObservers()
        self.removeTableViewContentObservers()
    }
    
    private func setUI(){
        self.registerCell()
    }
    
    private func setPublicPrivate() {
        setPrivatePublicUI(privateLbl: industryPrivateLbl, publicLbl: industryPublicLbl, privateLine: industryPrivateLineView, publicLine: industryPublicLineView, privateView: industryPrivateView, publicView: industryPublicView, isPublic: isIndustryPublic)
        setPrivatePublicUI(privateLbl: socialMediaPrivateLbl, publicLbl: socialMediaPublicLbl, privateLine: socialMediaPrivateLineView, publicLine: socialMediaPublicLineView, privateView: socialMediaPrivateView, publicView: socialMediaPublicView, isPublic: isSocialMediaPublic)
        setPrivatePublicUI(privateLbl: vibesPrivateLbl, publicLbl: vibesPublicLbl, privateLine: vibesPrivateLineView, publicLine: vibesPublicLineView, privateView: vibesPrivateView, publicView: vibesPublicView, isPublic: isVibesPublic)
        setPrivatePublicUI(privateLbl: favDrinksPrivateLbl, publicLbl: favDrinksPublicLbl, privateLine: favDrinksPrivateLineView, publicLine: favDrinksPublicLineView, privateView: favDrinksPrivateView, publicView: favDrinksPublicView, isPublic: isFavDrinksPublic)
        setPrivatePublicUI(privateLbl: datePrivateLbl, publicLbl: datePublicLbl, privateLine: datePrivateLineView, publicLine: datePublicLineView, privateView: datePrivateView, publicView: datePublicView, isPublic: isDatePublic)
    }
    
    private func registerCell() {
        self.vibesCollectionView.register(UINib(nibName: "VibesCVC", bundle: nil), forCellWithReuseIdentifier: "VibesCVC")
        self.favouriteDrinkCollectionView.register(UINib(nibName: "FavouriteDrinksCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteDrinksCVC")
        self.favouriteArtistCollectionView.register(UINib(nibName: "FavouriteArtistCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteArtistCVC")
        self.importantDatesTableView.register(UINib(nibName: "ImportantDatesTVC", bundle: nil), forCellReuseIdentifier: "ImportantDatesTVC")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        self.heightImportantDatesTableView.constant = self.importantDatesTableView.contentSize.height
        self.heightVibesCollectionView.constant = self.vibesCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.heightFavouriteDrinkCollectionView.constant = self.favouriteDrinkCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.heightFavouriteArtistCollectionView.constant = self.favouriteArtistCollectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    @IBAction func onBtnClose(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnOccupation(_ sender: UIButton) {
        self.setOccupationDropDown(show: true)

    }
    @IBAction func onBtnCamera(_ sender: UIButton) {
        self.uploadPhoto()
    }
    @IBAction func onBtnSave(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

//MARK: - Helper Methods
extension EditProfileVC {
    
    private func setOccupationDropDown(show: Bool) {
        self.occupationDropDown.dataSource = ["Software Engineer, Somelier ","Mechanical Engineer","Civil Engineer","Electrical Engineer"]
        self.occupationDropDown.anchorView = self.btnOccupation
        self.occupationDropDown.bottomOffset = CGPoint(x: 0, y:(self.occupationDropDown.anchorView?.plainView.bounds.height ?? 0.0))
        self.occupationDropDown.cellHeight = self.btnOccupation.frame.height+10.0
        self.occupationDropDown.backgroundColor = Global.APP_COLOR
        self.occupationDropDown.textColor = .white
        self.occupationDropDown.textFont = UIFont(name: "Poppins-SemiBold", size: 13.0) ?? UIFont.systemFont(ofSize:13.0)
        self.occupationDropDown.selectionBackgroundColor = Global.APP_COLOR_GREY
        self.occupationDropDown.width = self.btnOccupation.frame.width
        self.occupationDropDown.dimmedBackgroundColor = UIColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 0.25)
        self.occupationDropDown.show()
        self.occupationDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.tfOccupation.text = item
        }
    }
    
    private func addTableViewContentObservers(){
        importantDatesTableView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
    }
    
    private func removeTableViewContentObservers(){
        importantDatesTableView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    private func addCollectionViewContentObservers(){
        self.vibesCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        self.favouriteDrinkCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        self.favouriteArtistCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
    }
    private func removeCollectionViewContentObservers(){
        self.vibesCollectionView.removeObserver(self, forKeyPath: "contentSize")
        self.favouriteDrinkCollectionView.removeObserver(self, forKeyPath: "contentSize")
        self.favouriteArtistCollectionView.removeObserver(self, forKeyPath: "contentSize")
    }
}

//MARK: - Image picker
extension EditProfileVC{
    func uploadFromCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            Utility.main.topViewController()?.present(picker, animated: true, completion: nil)
        }
    }
    func uploadFromGallery(){
        let picker = UIImagePickerController()
        picker.delegate = self
        Utility.main.topViewController()?.present(picker, animated: true, completion: nil)
    }
    func uploadPhoto(){
        let alert = UIAlertController(title: Strings.ASK_UPLOAD_DOCMENT_PHOTO_VIA.text , message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.CAMERA.text, style: .default, handler: { (UIAlertAction) in
            self.uploadFromCamera()
        }))
        alert.addAction(UIAlertAction(title: Strings.GALLERY.text, style: .default, handler: { (UIAlertAction) in
            self.uploadFromGallery()
        }))
        alert.addAction(UIAlertAction(title: Strings.CANCEL.text, style: .cancel, handler: nil))
        Utility.main.topViewController()?.present(alert, animated: true, completion: nil)
    }
}
//MARK: - UIImagePickerControllerDelegate
extension EditProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: {
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                self.imgUser.image = pickedImage
            }
        })
    }
}
//MARK: - TableView
extension EditProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrImportantDates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.importantDatesTableView.dequeueReusableCell(withIdentifier: "ImportantDatesTVC") as! ImportantDatesTVC
        let data = self.arrImportantDates[indexPath.row]
        cell.setData(data: data)
        return cell
    }
}
//MARK: - CollectionView
extension EditProfileVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
            
        case vibesCollectionView:
            return arrVibes.count
        case favouriteDrinkCollectionView:
            return arrFavouriteDrinks.count
        default:
            return arrFavouriteArtists.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case vibesCollectionView:
            let cell = vibesCollectionView.dequeueReusableCell(withReuseIdentifier: "VibesCVC", for: indexPath) as! VibesCVC
            cell.lblVibes.text = self.arrVibes[indexPath.row]
            return cell
        case favouriteDrinkCollectionView:
            let cell = favouriteDrinkCollectionView.dequeueReusableCell(withReuseIdentifier: "FavouriteDrinksCVC", for: indexPath) as! FavouriteDrinksCVC
            cell.lblDrinks.text = self.arrFavouriteDrinks[indexPath.row]
            cell.backGroundView.backgroundColor = UIColor(hex: "#007AFF")
            return cell
        case favouriteArtistCollectionView:
            let cell = favouriteArtistCollectionView.dequeueReusableCell(withReuseIdentifier: "FavouriteArtistCVC", for: indexPath) as! FavouriteArtistCVC
            cell.lblArtist.text = self.arrFavouriteArtists[indexPath.row]
            return cell
        default:
            return UICollectionViewCell()
        }
        
    }
}
extension EditProfileVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)

        switch collectionView {
        case vibesCollectionView:
            
            let height = 40.0
            let tabOption = self.arrVibes[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
        case favouriteDrinkCollectionView:
            let height = 40.0
            let tabOption = self.arrFavouriteDrinks[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size

        case favouriteArtistCollectionView:
            
            let height = 40.0
            let tabOption = self.arrFavouriteArtists[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
        default:
            return CGSize()
        }
    }
}

private extension EditProfileVC {
    func setPrivatePublicUI(privateLbl: UILabelDeviceClass, publicLbl: UILabelDeviceClass, privateLine: UIView, publicLine: UIView, privateView: UIView, publicView: UIView, isPublic: Bool) {
        let privateTap = UITapGestureRecognizer(target: self, action: #selector(onClickPrivate))
        privateView.isUserInteractionEnabled = true
        privateView.addGestureRecognizer(privateTap)
        let publicTap = UITapGestureRecognizer(target: self, action: #selector(onClickPrivate))
        publicView.isUserInteractionEnabled = true
        publicView.addGestureRecognizer(publicTap)
        switch isPublic {
        case true:
            publicLbl.textColor = .white
            privateLbl.textColor = Global.APP_COLOR_DARK_GREY
            publicLbl.isShadowed = true
            privateLbl.isShadowed = false
            publicLine.isHidden = false
            privateLine.isHidden = true
        case false:
            publicLbl.textColor = Global.APP_COLOR_DARK_GREY
            privateLbl.textColor = .white
            publicLbl.isShadowed = false
            privateLbl.isShadowed = true
            publicLine.isHidden = true
            privateLine.isHidden = false
        }
        publicLbl.layoutSubviews()
        privateLbl.layoutSubviews()
    }
    
    @objc func onClickPrivate(_ sender: UISwipeGestureRecognizer) {
        switch (sender.view?.tag ?? 0) {
        case 1:
            isIndustryPublic = false
        case 2:
            isIndustryPublic = true
        case 3:
            isSocialMediaPublic = false
        case 4:
            isSocialMediaPublic = true
        case 5:
            isVibesPublic = false
        case 6:
            isVibesPublic = true
        case 7:
            isFavDrinksPublic = false
        case 8:
            isFavDrinksPublic = true
        case 9:
            isDatePublic = false
        case 10:
            isDatePublic = true
        default:
            break
        }
        setPublicPrivate()
    }
}

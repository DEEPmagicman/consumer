//
//  MyAccount.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 28/08/2022.
//

import UIKit

//Dummy data
struct FriendProfile {
    var firstName: String
    var friendImg: UIImage?
}
struct ArtistProfile {
    var artistImg: UIImage?
}

class MyAccount: BaseController {
    
    @IBOutlet weak var socialMediaCollectionView: UICollectionView!
    @IBOutlet weak var friendsListCollectionView: UICollectionView!
    @IBOutlet weak var vibesCollectionView: UICollectionView!
    @IBOutlet weak var importantDatesCollectionView: UICollectionView!
    @IBOutlet weak var favouriteDrinkCollectionView: UICollectionView!
    @IBOutlet weak var favouriteArtistCollectionView: UICollectionView!

    @IBOutlet weak var socialMediaCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var vibesCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var favouriteDrinksCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var favoriteVenueCollectionView: UICollectionView!
    
    var arrSocialMedia = ["@tamasan", "Tamas An", "@tamasan"]
    var arrSocialMediaIcons = [UIImage(named: "profileInsta"), UIImage(named: "snapIc"), UIImage(named: "profileSpotify")]
    
    var arrVibes = ["Fridays", "EDM", "Bottle Service", "Crowds"]
    var arrFavouriteDrinks = ["Whiskey", "Dom Perignon", "Moscow Mule", "Whiskey Sour", "Martini", "Whiskey Coke"]
    var arrFavouriteArtists = ["Steve Aoki", "DJ Heavy", "Martin Garrix", "Armin van Buuren"]
    var arrayFavoriteVenueEvents = [
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG1"), lblPerformerName: "TAO Chicago", imgBrandLogo: UIImage(named:"VenueTao"), isLive: true, isFavourite: true, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 4:00 AM"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG2"), lblPerformerName: "The Underground", imgBrandLogo: UIImage(named:"HotVenueBrandLogo3"), isLive: false, isFavourite: true, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 3:00 AM"),
        
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenuesBG3"), lblPerformerName: "Studio Paris", imgBrandLogo: UIImage(named:"HotVenueBrandLogo2"), isLive: false, isFavourite: true, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 11:00 PM"),
    ]
    //Dummy Date
    var friendsArray = [
        FriendProfile(firstName: "Paul", friendImg: UIImage(named: "ic-friends")),
        FriendProfile(firstName: "Anna", friendImg: UIImage(named: "annamSmall")),
        FriendProfile(firstName: "Conor", friendImg: UIImage(named: "conormSmall")),
        FriendProfile(firstName: "Dana", friendImg: UIImage(named: "danawSmall")),
        FriendProfile(firstName: "Georges", friendImg: UIImage(named: "gspSmall")),
        FriendProfile(firstName: "Madison", friendImg: UIImage(named: "madisonsSmall")),
        FriendProfile(firstName: "Hieu", friendImg: UIImage(named: "nguyenhSmall")),
        FriendProfile(firstName: "Virgil", friendImg: UIImage(named: "virgilsSmall"))
    ]
    var artistArray = [
        ArtistProfile(artistImg: UIImage(named: "artistIc")),
        ArtistProfile(artistImg: UIImage(named: "davidG")),
        ArtistProfile(artistImg: UIImage(named: "martinG")),
        ArtistProfile(artistImg: UIImage(named: "morten")),
        ArtistProfile(artistImg: UIImage(named: "tiesto"))
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.register()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addCollectionViewContentObservers()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeCollectionViewContentObservers()
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.socialMediaCollectionViewHeight.constant = self.socialMediaCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.vibesCollectionViewHeight.constant = self.vibesCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.favouriteDrinksCollectionViewHeight.constant = self.favouriteDrinkCollectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    private func register() {
        self.socialMediaCollectionView.register(UINib(nibName: "SocialMediaCVC", bundle: nil), forCellWithReuseIdentifier: "SocialMediaCVC")
        self.friendsListCollectionView.register(UINib(nibName: "FriendsListCVC", bundle: nil), forCellWithReuseIdentifier: "FriendsListCVC")
        self.vibesCollectionView.register(UINib(nibName: "VibesCVC", bundle: nil), forCellWithReuseIdentifier: "VibesCVC")
        self.importantDatesCollectionView.register(UINib(nibName: "ImportantDatesCVC", bundle: nil), forCellWithReuseIdentifier: "ImportantDatesCVC")
        self.favouriteDrinkCollectionView.register(UINib(nibName: "FavouriteDrinksCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteDrinksCVC")
        self.favouriteArtistCollectionView.register(UINib(nibName: "FavoriteArtistProfileCVC", bundle: nil), forCellWithReuseIdentifier: "FavoriteArtistProfileCVC")
        self.favoriteVenueCollectionView.register(UINib(nibName: "HotVenueCVC", bundle: nil), forCellWithReuseIdentifier: "HotVenueCVC")
    }
    
    @IBAction func onBtnSearchAndAddFriends(_ sender: UIButton) {
        self.navigationController?.pushViewController(Friends(), animated: true)
    }
    @IBAction func onBtnEdit(_ sender: UIButton) {
        Navigate.to.editProfile(self)
    }
    @IBAction func onBtnSetting(_ sender: UIButton) {
        Navigate.to.settingsVc(self)
    }
}
//MARK: - Helper Methods
extension MyAccount {
    private func addCollectionViewContentObservers(){
        self.socialMediaCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        self.vibesCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        self.favouriteDrinkCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
        self.favouriteArtistCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
    }
    private func removeCollectionViewContentObservers(){
        self.socialMediaCollectionView.removeObserver(self, forKeyPath: "contentSize")
        self.vibesCollectionView.removeObserver(self, forKeyPath: "contentSize")
        self.favouriteDrinkCollectionView.removeObserver(self, forKeyPath: "contentSize")
        self.favouriteArtistCollectionView.removeObserver(self, forKeyPath: "contentSize")
    }
}
//MARK: - UICollectionViewDataSource
extension MyAccount: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.socialMediaCollectionView:
            return self.arrSocialMediaIcons.count
        case self.friendsListCollectionView:
            return 8
        case self.vibesCollectionView:
            return self.arrVibes.count
        case self.importantDatesCollectionView:
            return 4
        case self.favouriteDrinkCollectionView:
            return self.arrFavouriteDrinks.count
        case self.favouriteArtistCollectionView:
            return 5
        case self.favoriteVenueCollectionView:
            return self.arrayFavoriteVenueEvents.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case socialMediaCollectionView:
            let cell = socialMediaCollectionView.dequeueReusableCell(withReuseIdentifier: "SocialMediaCVC", for: indexPath) as! SocialMediaCVC
            cell.setData(socialLink: self.arrSocialMediaIcons[indexPath.item])
            return cell
        case friendsListCollectionView:
            let cell = friendsListCollectionView.dequeueReusableCell(withReuseIdentifier: "FriendsListCVC", for: indexPath) as! FriendsListCVC
            //Dummy Data
            cell.profileImg.image = friendsArray[indexPath.row].friendImg
            cell.firstName.text = friendsArray[indexPath.row].firstName
            return cell
        case vibesCollectionView:
            let cell = vibesCollectionView.dequeueReusableCell(withReuseIdentifier: "VibesCVC", for: indexPath) as! VibesCVC
            cell.lblVibes.text = self.arrVibes[indexPath.row]
            return cell
        case importantDatesCollectionView:
            let cell = importantDatesCollectionView.dequeueReusableCell(withReuseIdentifier: "ImportantDatesCVC", for: indexPath) as! ImportantDatesCVC
            cell.setData(index: indexPath.item)
            return cell
        case favouriteDrinkCollectionView:
            let cell = favouriteDrinkCollectionView.dequeueReusableCell(withReuseIdentifier: "FavouriteDrinksCVC", for: indexPath) as! FavouriteDrinksCVC
            cell.lblDrinks.text = self.arrFavouriteDrinks[indexPath.row]
            cell.backGroundView.backgroundColor = UIColor(hex: "#007AFF")
            return cell
        case favouriteArtistCollectionView:
            let cell = favouriteArtistCollectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteArtistProfileCVC", for: indexPath) as! FavoriteArtistProfileCVC
            cell.artistImg.image = artistArray[indexPath.row].artistImg
            return cell
        case favoriteVenueCollectionView:
            let cell = favoriteVenueCollectionView.dequeueReusableCell(withReuseIdentifier: "HotVenueCVC", for: indexPath) as! HotVenueCVC
            let data = arrayFavoriteVenueEvents[indexPath.row]
            cell.setData(data: data)
            return cell
        default:
            return UICollectionViewCell()
        }
        
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension MyAccount: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)
        switch collectionView {
        case socialMediaCollectionView:
//            let stringWidth = self.arrSocialMedia[indexPath.item].getWidth(with: 15.0, font: UIFont(name: "Poppins-Medium", size: 15.0)!)
            let cellSize: CGSize = CGSize(width: 60, height: 46)
            return cellSize
        case friendsListCollectionView:
            let cellSize: CGSize = CGSize(width: (collectionView.frame.width/5), height: collectionView.frame.height*1.1)
            return cellSize
        case vibesCollectionView:

            let height = 40.0
            
            let tabOption = self.arrVibes[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 30.0
            
            let size = CGSize(width: width, height: height)
            return size
        case importantDatesCollectionView:
            let cellSize: CGSize = CGSize(width: self.importantDatesCollectionView.frame.size.width/2 - 10, height: self.importantDatesCollectionView.frame.size.height/2)
            return cellSize
        case favouriteDrinkCollectionView:
            
            let height = 40.0
            
            let tabOption = self.arrFavouriteDrinks[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
        case favouriteArtistCollectionView:

            let height = 102.0
            let width = 102.0

            let size = CGSize(width: width, height: height)
            return size
        case favoriteVenueCollectionView:
            let width = 250.0//favoriteVenueCollectionView.frame.width * 0.675
            let height = favoriteVenueCollectionView.frame.height
            let size = CGSize(width: width, height: height)
            return size
        default:
            return CGSize()
        }
    }
}

//
//  UserProfilePopUp.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 14/10/22.
//

import UIKit

class UserProfilePopUp: UIViewController {

    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var profileTabCollectionView: UICollectionView!
    @IBOutlet weak var favoriteDrinksCollection: UICollectionView!
    @IBOutlet weak var favoriteArtistCollection: UICollectionView!
    
    var profileTabArry = [EventHeaderOptions(label: Strings.PREFERENCES.text, isSelected: true),EventHeaderOptions(label: Strings.MEMBERSGIP_NFT.text, isSelected: false)]
    var arrFavouriteDrinks = ["The Bag", "Casamigos", "Carlsberg", "Krombacher", "Martini", "Whiskey Coke"]
    var arrFavouriteArtists = ["Ezell Foster", "Ericka from KP", "Shawn Wuu", "DJ Dorobiala"]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileTabCollectionView.register(UINib(nibName: "EventOptionCVC", bundle: nil), forCellWithReuseIdentifier: "EventOptionCVC")
        self.favoriteDrinksCollection.register(UINib(nibName: "FavouriteDrinksCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteDrinksCVC")
        self.favoriteArtistCollection.register(UINib(nibName: "FavouriteArtistCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteArtistCVC")
        self.profileTabCollectionView.delegate = self
        self.profileTabCollectionView.dataSource = self

    }

    @IBAction func onClickInvite(_ sender: Any) {
        
    }
    
    @IBAction func onClickCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension UserProfilePopUp: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.profileTabCollectionView:
            return profileTabArry.count
        case self.favoriteDrinksCollection:
            return arrFavouriteDrinks.count
        case self.favoriteArtistCollection:
            return arrFavouriteArtists.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.profileTabCollectionView:
            let cell = profileTabCollectionView.dequeueReusableCell(withReuseIdentifier: "EventOptionCVC", for: indexPath) as! EventOptionCVC
            let data = profileTabArry[indexPath.row]
            cell.setData(data: data)
            return cell
        case self.favoriteDrinksCollection:
            let cell = favoriteDrinksCollection.dequeueReusableCell(withReuseIdentifier: "FavouriteDrinksCVC", for: indexPath) as! FavouriteDrinksCVC
            cell.lblDrinks.text = self.arrFavouriteDrinks[indexPath.row]
            cell.backGroundView.backgroundColor = UIColor(hex: "#3F3F3F")
            return cell
        case self.favoriteArtistCollection:
            let cell = favoriteArtistCollection.dequeueReusableCell(withReuseIdentifier: "FavouriteArtistCVC", for: indexPath) as! FavouriteArtistCVC
            cell.lblArtist.text = self.arrFavouriteArtists[indexPath.row]
            return cell
        default:
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == profileTabCollectionView {
            if self.profileTabArry[indexPath.item].isSelected {
                return
            }
            else {
                for index in 0..<self.profileTabArry.count {
                    self.profileTabArry[index].isSelected = false
                }
                self.profileTabArry[indexPath.item].isSelected = true
    //            self.selectedTabAt?(indexPath.item)
            }
            DispatchQueue.main.async {
                collectionView.reloadData()
            }
        }
       
    }
}

extension UserProfilePopUp: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case profileTabCollectionView:
            let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "semiBold", fontSize: 15.0)
            let tabOption = self.profileTabArry[indexPath.item].label
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 40.0
            let height = collectionView.frame.height
                let size = CGSize(width: width, height: height)
                return size
            
        case favoriteDrinksCollection:
            let height = 40.0
            let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)
            let tabOption = self.arrFavouriteDrinks[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
            
        case favoriteArtistCollection:
            let height = 40.0
            let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)
            let tabOption = self.arrFavouriteArtists[indexPath.item]
            let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
            
            let size = CGSize(width: width, height: height)
            return size
        default:
            return CGSize()
        }
       
    }
}

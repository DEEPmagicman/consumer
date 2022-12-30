//
//  SelectFavoriteDrinkViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit

final class SelectFavoriteDrinkViewController: UIViewController {

    @IBOutlet weak var favoriteDrinksCollectionView: UICollectionView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    var drinksListArry = [Drink]()
    var drinkListDammy = [Drink(id:"1",drinkName:"Whiskey",status:"ENABLED",isDeleted: false, isSelected: false),Drink(id:"2",drinkName:"Dom Perignon",status:"ENABLED",isDeleted: false, isSelected: false),Drink(id:"3",drinkName:"Moscow Mule",status:"ENABLED",isDeleted: false,isSelected: false),Drink(id:"4",drinkName:"Whiskey Sour",status:"ENABLED",isDeleted: false,isSelected: false),Drink(id:"5",drinkName:"Martini",status:"ENABLED",isDeleted: false,isSelected: false),Drink(id:"6",drinkName:"Whiskey Coke",status:"ENABLED",isDeleted: false,isSelected: false)]
    var selectedDrinks = [String]()
    var onBoardingDelegate = OnBoardingPresenter()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.favoriteDrinksCollectionView.register(UINib(nibName: "FavouriteDrinksCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteDrinksCVC")
        
        self.onBoardingDelegate.getDrinkListAPi { drinkList, isSuccess in
            if isSuccess {
                for drink in self.drinkListDammy {
                    if drink.status == "ENABLED" && drink.isDeleted == false {
                        self.drinksListArry.append(drink)
                    }
                }
                self.favoriteDrinksCollectionView.reloadData()
                print(drinkList)
            } else {
                Alert.showAlertSheet(style: .alert, title: "drink not found", message: "")
            }
            Loader.hide()
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.favoriteDrinksCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.favoriteDrinksCollectionView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.collectionViewHeight.constant = self.favoriteDrinksCollectionView.collectionViewLayout.collectionViewContentSize.height
    }

    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.editUserProfileApi(drinkIds: self.selectedDrinks) { isSuccess in
            if isSuccess {
                UserDefault.shared.user?.drinkIds = self.selectedDrinks
                Navigate.to.connectSocialMediaVc(self)
            } else {
                Alert.showAlertSheet(style: .alert, title: "drinks not update", message: "")
            }
        }
        Loader.hide()
    }
    
}

extension SelectFavoriteDrinkViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drinksListArry.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavouriteDrinksCVC", for: indexPath) as! FavouriteDrinksCVC
        cell.lblDrinks.text = drinksListArry[indexPath.row].drinkName
        if drinksListArry[indexPath.row].isSelected {
            cell.backGroundView.backgroundColor = Constant.Color.selectedDrinkColor
            cell.lblDrinks.textColor = Constant.Color.selectedItemTextColor
        } else {
            cell.backGroundView.backgroundColor = .white
            cell.lblDrinks.textColor = .black
        }
        cell.backGroundView.tag = 0
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)
        let height = 40.0
        
        let tabOption = self.drinksListArry[indexPath.item].drinkName
        let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
        
        let size = CGSize(width: width, height: height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if drinksListArry[indexPath.row].isSelected {
            self.selectedDrinks = selectedDrinks.filter{ (drinkid) in
                drinkid != drinksListArry[indexPath.row].id
            }
        } else {
            selectedDrinks.append(drinksListArry[indexPath.row].id)
        }
        self.drinksListArry[indexPath.row].isSelected.toggle()
        favoriteDrinksCollectionView.reloadData()
    }
    
}

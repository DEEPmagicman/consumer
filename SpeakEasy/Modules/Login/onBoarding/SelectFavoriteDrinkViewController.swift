//
//  SelectFavoriteDrinkViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit

class SelectFavoriteDrinkViewController: UIViewController {

    @IBOutlet weak var favoriteDrinksCollectionView: UICollectionView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    var drinksListArry = ["Whiskey", "Dom Perignon", "Moscow Mule", "Whiskey Sour", "Martini", "Whiskey Coke"]
    var drinkSelectedDemoArry = [false,false,false,false,false,false]
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.favoriteDrinksCollectionView.register(UINib(nibName: "FavouriteDrinksCVC", bundle: nil), forCellWithReuseIdentifier: "FavouriteDrinksCVC")
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
        Navigate.to.connectSocialMediaVc(self)
    }
    
}

extension SelectFavoriteDrinkViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drinksListArry.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavouriteDrinksCVC", for: indexPath) as! FavouriteDrinksCVC
        cell.lblDrinks.text = drinksListArry[indexPath.row]
        if drinkSelectedDemoArry[indexPath.row] {
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
        
        let tabOption = self.drinksListArry[indexPath.item]
        let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 20.0
        
        let size = CGSize(width: width, height: height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.drinkSelectedDemoArry[indexPath.row].toggle()
        favoriteDrinksCollectionView.reloadData()
    }
    
}

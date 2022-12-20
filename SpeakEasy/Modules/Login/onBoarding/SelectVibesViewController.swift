//
//  SelectVibesViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit

final class SelectVibesViewController: UIViewController {

    @IBOutlet weak var vibesCollectionView: UICollectionView!
    @IBOutlet weak var visibleprofileBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    var vibesListArry = ["Fridays", "EDM", "Bottle Service", "Crowds","DJ Boooth"]
    var demoVibesSelect = [false,false,false,false,false]
    var vibesCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.visibleprofileBtn.isSelected = false
        self.vibesCollectionView.register(UINib(nibName: "VibesCVC", bundle: nil), forCellWithReuseIdentifier: "VibesCVC")
        self.continueBtn.alpha = 0.5
        self.continueBtn.isUserInteractionEnabled = false

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.vibesCollectionView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.old, context: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.vibesCollectionView.removeObserver(self, forKeyPath: "contentSize")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.collectionViewHeight.constant = self.vibesCollectionView.collectionViewLayout.collectionViewContentSize.height
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        Navigate.to.selectFavoriteDrinkVc(self)
    }
    
    @IBAction func onClickVisibleProfile(_ sender: Any) {
        if self.visibleprofileBtn.isSelected {
            self.visibleprofileBtn.setImage(Constant.Icon.radioIcon, for: .normal)
            self.visibleprofileBtn.isSelected = false
        } else {
            self.visibleprofileBtn.setImage(Constant.Icon.radioClick, for: .normal)
            self.visibleprofileBtn.isSelected = true
        }
    }
    
}

extension SelectVibesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vibesListArry.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VibesCVC", for: indexPath) as! VibesCVC
        cell.lblVibes.text = vibesListArry[indexPath.row]
        if self.demoVibesSelect[indexPath.row] {
            cell.bgColorView.backgroundColor = Constant.Color.vibesSelectedBgColor
            cell.lblVibes.textColor = Constant.Color.selectedItemTextColor
        } else {
            cell.bgColorView.backgroundColor = .white
            cell.lblVibes.textColor = .black
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let lableFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 15.0)

        let height = 36.0
        
        let tabOption = self.vibesListArry[indexPath.item]
        let width = tabOption.size(withAttributes:[.font: lableFont ?? UIFont.systemFont(ofSize:15.0)]).width + 30.0
        
        let size = CGSize(width: width, height: height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if demoVibesSelect[indexPath.row] {
            vibesCount -= 1
        } else {
            vibesCount += 1
        }
        if vibesCount >= 4 {
            self.continueBtn.alpha = 1
            self.continueBtn.isUserInteractionEnabled = true
        } else {
            self.continueBtn.alpha = 0.5
            self.continueBtn.isUserInteractionEnabled = false
        }
        self.demoVibesSelect[indexPath.row].toggle()
        self.vibesCollectionView.reloadData()
    }
}

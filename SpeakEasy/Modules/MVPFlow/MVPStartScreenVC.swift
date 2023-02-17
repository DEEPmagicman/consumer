//
//  MVPStartScreenVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/02/23.
//

import UIKit
import SCPageControl

class MVPStartScreenVC: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControllerView: SCPageControlView!
    
    var pagesCount = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pageControllerView.scp_style = .SCJAFillCircle
        pageControllerView.set_view(self.pagesCount , current: 0, current_color: Constant.Color.submiteRequestBtnColor, disable_color: .red)
        collectionView.register(UINib(nibName: "MVPSplashCVC", bundle: nil), forCellWithReuseIdentifier: "MVPSplashCVC")
    }
    

    @IBAction func onClickContinueasGuest(_ sender: Any) {
        Navigate.to.MVPVenueListViewController(self)
    }
    
}

extension MVPStartScreenVC: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pagesCount
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MVPSplashCVC", for: indexPath) as! MVPSplashCVC
        switch indexPath.item {
        case 0:
            cell.imgView.image = UIImage(named: "MVPHome-Ic")
            cell.headerLbl.text = "Top Venues & Events"
            cell.infoLbl.text = "Buy entry to your favorite nightclubs, bars, & events"
        case 1:
            cell.imgView.image = UIImage(named: "MVPWifi-ic")
            cell.headerLbl.text = "Live Cover & Wait Times"
            cell.infoLbl.text = "View this all here to plan your night live!"
        case 2:
            cell.imgView.image = UIImage(named: "MVPLock-ic")
            cell.headerLbl.text = " + Guaranteed Entry"
            cell.infoLbl.text = "Full protection with Speakeasy+ Purchase"
        default: break
        }
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageControllerView.scroll_did(scrollView)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let pageWidth = scrollView.frame.size.width
//        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
//        self.pagesCount = currentPage
//        DispatchQueue.main.async {
//            self.setCurrentPageBottom(currentPage: currentPage)
//        }
    }
}

extension MVPStartScreenVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        let width = collectionView.frame.width
        let size = CGSize(width: width, height: height)
        return size
    }
}


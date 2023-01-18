//
//  Tutorials.swift
//  QuickPay
//
//  Created by M.Usman Bin Rehan on 7/27/21.
//

import UIKit
import SCPageControl

// TODO: remove old vc (with SCPageControl pod)
class Tutorials: BaseController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: SCPageControlView!
    @IBOutlet weak var bottomFrontView: UIView!
    @IBOutlet weak var btnSkipCreateAccount: UIButton!
    
    var pagesCount = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.registerCell()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func onBtnSignIn(_ sender: UIButton) {
        AppDelegate.shared.showLogin()
    }
}
//MARK: - Helper Methods
extension Tutorials{
    private func setUI(){
        self.pageControl.scp_style = .SCJAFillCircle
        self.pageControl.set_view(self.pagesCount - 1 , current: 0, current_color: Global.APP_COLOR_DARK_PURPLE, disable_color: nil)
    }
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "Tutorial1CVC", bundle: nil), forCellWithReuseIdentifier: "Tutorial1CVC")
        self.collectionView.register(UINib(nibName: "Tutorial2CVC", bundle: nil), forCellWithReuseIdentifier: "Tutorial2CVC")
        self.collectionView.register(UINib(nibName: "Tutorial3CVC", bundle: nil), forCellWithReuseIdentifier: "Tutorial3CVC")
        self.collectionView.register(UINib(nibName: "Tutorial4CVC", bundle: nil), forCellWithReuseIdentifier: "Tutorial4CVC")
        self.collectionView.register(UINib(nibName: "Tutorial5CVC", bundle: nil), forCellWithReuseIdentifier: "Tutorial5CVC")
        
    }
    private func setCurrentPageBottom(currentPage: Int){
        if currentPage == 4{
            DispatchQueue.main.async {
                self.pageControl.isHidden = true
                if !self.bottomFrontView.isHidden{return}
                self.bottomFrontView.isHidden = false
                UIView.animate(withDuration: 0.15) {
                    self.bottomFrontView.alpha = 1.0
                }
            }
        }
        else{
            DispatchQueue.main.async {
                self.pageControl.isHidden = false
                UIView.animate(withDuration: 0.15) {
                    self.bottomFrontView.alpha = 0.0
                } completion: { _ in
                    self.bottomFrontView.isHidden = true
                }
            }
        }
    }
}
//MARK: - UICollectionViewDataSource
extension Tutorials: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pagesCount
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Tutorial1CVC", for: indexPath)
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Tutorial2CVC", for: indexPath)
            return cell
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Tutorial3CVC", for: indexPath)
            return cell
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Tutorial4CVC", for: indexPath)
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Tutorial5CVC", for: indexPath)
            return cell
        }
    }
}
//MARK: - UICollectionViewDelegate
extension Tutorials: UICollectionViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageControl.scroll_did(scrollView)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        self.pagesCount = currentPage
        DispatchQueue.main.async {
            self.setCurrentPageBottom(currentPage: currentPage)
        }
    }
}
//MARK: - UICollectionViewDelegateFlowLayout
extension Tutorials: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        let width = collectionView.frame.width
        let size = CGSize(width: width, height: height)
        return size
    }
}

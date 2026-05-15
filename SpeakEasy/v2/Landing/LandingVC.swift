//
//  LandingVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit

final class LandingVC: UIViewController {
    
    @IBOutlet var segmentViewContainer: [UIView]!
    @IBOutlet private var tabBarImages: [UIImageView]!
    @IBOutlet private var tabBarTitles: [UILabel]!
    @IBOutlet weak var pageTitleLbl: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstNameLetter: UILabel!
    @IBOutlet weak var searchBtnView: UIView!
    @IBOutlet var bgView: UIView!
    @IBOutlet weak var signInView: UIView!
    @IBOutlet weak var noImageView: UIView!
    
    
    private var viewControllers = [UIViewController]()
    private var onBoardingPresenter = OnBoardingPresenter()
    var titles = ["", "Your Orders", "Photos", "Search"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSegmentView(0)
        setupUserData()
//        whoAmIAPI()
        bgView.applyScreenBgGradient()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        setupUserData()
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
        
        firstNameLetter.layer.cornerRadius = firstNameLetter.frame.height / 2
        firstNameLetter.clipsToBounds = true
    }
    
    @IBAction func onClickProfile(_ sender: UIButton) {
        if UserDefault.shared.isLoggedIn == true {
            sideMenuController?.showLeftView()
        } else {
            Navigate.to.openPhoneLoginPopup(self)
        }
    }
    
    @IBAction func onClickTabBarItem(_ sender: UIButton) {
        showSegmentView(sender.tag)
    }
    
    @IBAction func onClickSearchBtn(_ sender: Any) {
//        Navigate.to.gotoSearchVc(self)
    }
    
    private func showSegmentView(_ index: Int) {
        segmentViewContainer.enumerated().forEach { enumeratedIndex, _ in
            segmentViewContainer[enumeratedIndex].isHidden = enumeratedIndex != index
            segmentViewContainer[enumeratedIndex].endEditing(enumeratedIndex != index)
            tabBarImages[enumeratedIndex].tintColor = enumeratedIndex == index ? .white : UIColor(hex: "#5C5C5C")
            tabBarTitles[enumeratedIndex].textColor = enumeratedIndex == index ? .white : UIColor(hex: "#5C5C5C")
//            pageTitleLbl.text = titles[index]
            if index == 0 {
                self.searchBtnView.isHidden = false
            } else {
                self.searchBtnView.isHidden = true
            }
        }
    }
    
    private func setupUserData() {
        
        guard let user = UserDefault.shared.user else {
            self.imageView.isHidden = true
            noImageView.isHidden = true
            self.signInView.isHidden = false
            self.pageTitleLbl.text = "Sing in"
            return
        }
        
        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("P")
        
        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            noImageView.isHidden = true
            self.signInView.isHidden = true
            
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(named: "placeholder")
            )
            self.pageTitleLbl.text = user.firstName
            
        } else {
            imageView.isHidden = true
            firstNameLetter.isHidden = false
            noImageView.isHidden = false
            self.signInView.isHidden = true
            self.pageTitleLbl.text = user.firstName
            firstNameLetter.text = String(firstLetter).uppercased()
            firstNameLetter.textAlignment = .center
        }
    }
    
    private func whoAmIAPI() {
        if UserDefault.shared.isGuest == true { return }
        onBoardingPresenter.getCurrentUserDetail {[weak self] isSuccess in
            guard let self = self else { return }
            if isSuccess {
                self.setupUserData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        viewControllers.append(segue.destination)
        switch segue.destination {
        case is DiscoverVC:
            if segue.destination is DiscoverVC {
                print("BoxOfficeOverviewVC")
            }
        case is OrdersVC:
            if segue.destination is OrdersVC {
                print("BoxOfficeCoverSalesVC")
            }
        case is PhotosVC:
            if segue.destination is PhotosVC {
                print("CustomPaycodeVC")
            }
        case is SearchVC:
            if segue.destination is SearchVC {
                print("CustomPaycodeVC")
            }
        default:
            break
        }
    }
}

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

    private var viewControllers = [UIViewController]()
    private var onBoardingPresenter = OnBoardingPresenter()
    var titles = ["Explore", "Your Orders", "Photos", "Search"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSegmentView(0)
        setupUserData()
        whoAmIAPI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
        
        firstNameLetter.layer.cornerRadius = firstNameLetter.frame.height / 2
        firstNameLetter.clipsToBounds = true
    }
    
    @IBAction func onClickProfile(_ sender: UIButton) {
        sideMenuController?.showLeftView()
    }
    
    @IBAction func onClickTabBarItem(_ sender: UIButton) {
        showSegmentView(sender.tag)
    }
    
    @IBAction func onClickSearchBtn(_ sender: Any) {
        
    }
    
    private func showSegmentView(_ index: Int) {
        segmentViewContainer.enumerated().forEach { enumeratedIndex, _ in
            segmentViewContainer[enumeratedIndex].isHidden = enumeratedIndex != index
            segmentViewContainer[enumeratedIndex].endEditing(enumeratedIndex != index)
            tabBarImages[enumeratedIndex].tintColor = enumeratedIndex == index ? .white : UIColor(hex: "#5C5C5C")
            tabBarTitles[enumeratedIndex].textColor = enumeratedIndex == index ? .white : UIColor(hex: "#5C5C5C")
            pageTitleLbl.text = titles[index]
        }
    }
    
    private func setupUserData() {
        
        guard let user = UserDefault.shared.user else { return }
        
        let imageUrl = user.image.key
        let firstLetter = user.firstName.first ?? Character("")
        
        if !imageUrl.isEmpty {
            imageView.isHidden = false
            firstNameLetter.isHidden = true
            
            imageView.sd_setImage(
                with: URL(string: imageUrl),
                placeholderImage: UIImage(named: "placeholder")
            )
            
        } else {
            imageView.isHidden = true
            firstNameLetter.isHidden = false
            
            firstNameLetter.text = String(firstLetter).uppercased()
            firstNameLetter.textAlignment = .center
        }
    }
    
    private func whoAmIAPI() {
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

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
    
    private var viewControllers = [UIViewController]()
    var titles = ["Explore", "Your Orders", "Photos", "Search"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSegmentView(0)
    }
    
    @IBAction func onClickProfile(_ sender: UIButton) {
        sideMenuController?.showLeftView()
    }
    
    @IBAction func onClickTabBarItem(_ sender: UIButton) {
        showSegmentView(sender.tag)
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

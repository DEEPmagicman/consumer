//
//  TableCheckOutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Deep on 03/01/26.
//

import UIKit

class TableCheckOutVC: UIViewController {
    
    @IBOutlet weak var mainContentView: UIView!
    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueNameNavigationLbl: UILabel!
    @IBOutlet weak var eventNameLbl: UILabel!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    
    private var tablesListVC: TablesListVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tablesListVC = TablesListVC()
        setupChildVCs()
    }
    
    @IBAction func onCloseTapped(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    private func showChild(_ vc: UIViewController) {

        children.forEach { child in
            child.view.isHidden = true
        }

        vc.view.isHidden = false
    }
    
    private func setupChildVCs() {

        if let tablesListVC = tablesListVC {
            addChild(tablesListVC)
            mainContentView.addSubview(tablesListVC.view)
            tablesListVC.didMove(toParent: self)
        }
    }
}

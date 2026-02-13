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
    
    var event: Event?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tablesListVC = TablesListVC()
        setupChildVCs()
        setupUI()
    }
    
    private func setupUI() {
        venueNameNavigationLbl.text = "Nebula New York"
        eventNameLbl.text = "Fedde Le Grand"
        venueNameLbl.text = "Nebula New York"
        timeLbl.text = "Fri, Sep 19 at 9:00 PM"
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
            addChildView(tablesListVC)
        }
    }
    
    private func addChildView(_ vc: UIViewController) {
        addChild(vc)
        mainContentView.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: mainContentView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor),
            vc.view.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor)
        ])

        vc.didMove(toParent: self)
    }
}

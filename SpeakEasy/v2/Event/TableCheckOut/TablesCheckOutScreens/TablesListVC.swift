//
//  TablesListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

//protocol MainDataConsumer: AnyObject {
//    func update(with data: EventDataModel)
//}

import UIKit

class TablesListVC: UIViewController {

    @IBOutlet weak var switchContainerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    
    private var optionSwitchView: TopOptionSwitchView!
    private var optionSwitchList = ["3D Map", "List", "Request"]
    
    private var mapVC: Tables3DMapVC?
    private var listVC: TableBookingListVC?
    private var requestVC: TableRequestVC?
    var event: Event?
    
    
    private var has3DMap = true
//    private var sharedData: EventDataModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
        setupTopSwitch()
        setupChildVCs()
        showChild(mapVC!)
    }
    
    private func fetchData() {
        //            API.getEventData { [weak self] data in
        //                self?.sharedData = data
        //                self?.updateChildren()
        //            }
        mapVC = Tables3DMapVC()
        mapVC?.event = event
        let vc =  TableBookingListVC()
        vc.event = self.event
        listVC = vc
        requestVC = TableRequestVC()
    }
    
    private func setupTopSwitch() {

        optionSwitchView = TopOptionSwitchView()
        switchContainerView.addSubview(optionSwitchView)

        optionSwitchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            optionSwitchView.topAnchor.constraint(equalTo: switchContainerView.topAnchor),
            optionSwitchView.bottomAnchor.constraint(equalTo: switchContainerView.bottomAnchor),
            optionSwitchView.leadingAnchor.constraint(equalTo: switchContainerView.leadingAnchor),
            optionSwitchView.trailingAnchor.constraint(equalTo: switchContainerView.trailingAnchor)
        ])

        // Dynamic options
        optionSwitchView.options = has3DMap
            ? optionSwitchList
        : ["List", "Request"]

        optionSwitchView.onSelectionChange = { [weak self] index in
            self?.handleSelection(index)
        }
    }

    private func handleSelection(_ index: Int) {

        let title = optionSwitchView.options[index]

        switch title {

        case "3D Map":
            if let mapVC = mapVC {
                showChild(mapVC)
            }
        case "List":
            if let listVC = listVC {
                showChild(listVC)
            }

        case "Request":
            if let requestVC = requestVC {
                showChild(requestVC)
            }

        default:
            break
        }
    }
    
    private func showChild(_ vc: UIViewController) {

        children.forEach { child in
            child.view.isHidden = true
        }

        vc.view.isHidden = false
    }
    
    private func setupChildVCs() {

        if let mapVC = mapVC {
            addChildView(mapVC)
        }

        if let listVC = listVC {
            addChildView(listVC)
        }

        if let requestVC = requestVC {
            addChildView(requestVC)
        }
    }
    
    private func addChildView(_ vc: UIViewController) {
        addChild(vc)
        contentContainerView.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            vc.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor)
        ])

        vc.didMove(toParent: self)
    }
    
    private func updateChildren() {
//        [mapVC, listVC, requestVC].forEach {
//            ($0 as? MainDataConsumer)?.update(with: sharedData!)
//        }
    }
}

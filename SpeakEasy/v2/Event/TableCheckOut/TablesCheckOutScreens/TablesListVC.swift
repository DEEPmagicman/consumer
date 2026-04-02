//
//  TablesListVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 05/01/26.
//

// protocol MainDataConsumer: AnyObject {
//    func update(with data: EventDataModel)
// }

import UIKit

class TablesListVC: UIViewController {

    @IBOutlet weak var switchContainerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!

    private var optionSwitchView: TopOptionSwitchView!
    private var mapVC: Tables3DMapVC?
    private var listVC: TableBookingListVC?
    private var requestVC: TableRequestVC?

    var event: Event?

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchData()
        setupTopSwitch()
        setupChildVCs()
        showDefaultScreen()
    }

    private func fetchData() {

        if event?.isEnable3DMap ?? false && event?.isEnableOnlineTables ?? false {
            let vc = Tables3DMapVC()
            vc.event = event
            mapVC = vc
        }

        if event?.isEnableOnlineTables == true {
            let vc = TableBookingListVC()
            vc.event = event
            listVC = vc
        }

        if event?.isEnableReservationRequest == true {
            let vc = TableRequestVC()
            vc.event = event
            requestVC = vc
        }
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

        var options: [String] = []

        if event?.isEnable3DMap == true {
            options.append("3D Map")
        }

        if event?.isEnableOnlineTables == true {
            options.append("List")
        }

        if event?.isEnableReservationRequest == true {
            options.append("Request")
        }

        optionSwitchView.options = options

        optionSwitchView.onSelectionChange = { [weak self] index in
            self?.handleSelection(index)
        }
    }

    private func handleSelection(_ index: Int) {
        
        view.endEditing(true)
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

    private func showDefaultScreen() {

        guard let firstOption = optionSwitchView.options.first else { return }

        switch firstOption {

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
}

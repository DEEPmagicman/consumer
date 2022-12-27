//
//  BaseController.swift
//  The Court Lawyer
//
//  Created by Ahmed Shahid on 5/3/18.
//  Copyright © 2018 Ahmed Shahid. All rights reserved.
//

import Foundation
import UIKit

class BaseController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loopThroughSubViewAndAlignTextfieldText(subviews: self.view.subviews)
    }
}
//MARK: - Helper methods
extension BaseController{
    @objc func onBtnBack() {
        self.navigationController?.popViewController(animated: true)
    }
}
extension BaseController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isEqual(navigationController?.interactivePopGestureRecognizer) {
            navigationController?.popViewController(animated: true)
        }
        return false
    }
}
//MARK: Application flow
extension BaseController{
    func pushToEditProfile(){
        let controller = EditProfileVC()
        self.navigationController?.pushViewController(controller, animated: true)
    }
    func pushToBookingInvite(booking: BookingsDataSet?, isFromSettings: Bool = false){
        let controller = BookingInvites()
        controller.booking = booking
        controller.isFromSettings = isFromSettings
        Utility.main.topViewController()?.navigationController?.pushViewController(controller, animated: true)
    }
    func pushToVIPBookingInvite(){
        let controller = VIPBookingInvite()
        Utility.main.topViewController()?.navigationController?.pushViewController(controller, animated: true)
    }
    func pushToPendingBookingAwait(data: BookingsDataSet?){
        let controller = PendingBookingAwait()
        Utility.main.topViewController()?.navigationController?.pushViewController(controller, animated: true)
    }
    func pushToTicketConfirmation(data: BookingsDataSet?, isFromSettings: Bool = false){
        let controller = TicketConfirmation()
        controller.screenType = .FromBooking
        controller.isFromSettings = isFromSettings
        Utility.main.topViewController()?.navigationController?.pushViewController(controller, animated: true)
    }
    func pushToAllEvents(){
        let controller = AllEvents()
        Utility.main.topViewController()?.navigationController?.pushViewController(controller, animated: true)
    }
    func pushToAllVenues(){
        let controller = AllVenues()
        Utility.main.topViewController()?.navigationController?.pushViewController(controller, animated: true)
    }
}


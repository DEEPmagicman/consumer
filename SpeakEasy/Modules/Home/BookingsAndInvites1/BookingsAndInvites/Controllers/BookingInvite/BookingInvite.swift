//
//  BookingInvite.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 31/08/2022.
//

import UIKit

class BookingInvite: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewHeader: UIView!
    @IBOutlet weak var viewPendingPayment: UIView!
    @IBOutlet weak var lblTitle: UILabelDeviceClass!
    @IBOutlet weak var viewCancelReques: UIView!
    @IBOutlet weak var viewSubmitRequest: UIView!
    @IBOutlet weak var btnCancelRequest: UIButton!
    @IBOutlet weak var btnSubmitRequest: UIButton!
    @IBOutlet weak var viewBookingRequestSent: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var booking: BookingsDataSet?
    var titleHead = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.collectionView.register(UINib(nibName: "FriendsListCVC", bundle: nil), forCellWithReuseIdentifier: "FriendsListCVC")
        self.lblTitle.text = titleHead
        self.setUI()
        UIView.animate(withDuration: 0.02, delay: 0, options: .curveEaseOut) {
            self.scrollView.alpha = 1.0
        } completion: { _ in
            
        }
    }
    
    
    @IBAction func onBtnClose(_ sender: UIButton) {
//        AppDelegate.shared.showHome(selectedIndex: 1)
    }
    
    @IBAction func onBtnCancelRequest(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onBtnSubmitRequest(_ sender: UIButton) {
//        guard let status = self.booking?.status else {return}
//
//        switch status {
//        case .PurchaseConfirmed:
//            self.navigationController?.popToRootViewController(animated: true)
//        case .AwaitingApproval:
//            self.navigationController?.popToRootViewController(animated: true)
//        case .TicketPurchasedConfirmed:
//            self.navigationController?.popToRootViewController(animated: true)
//        case .AwaitingVenueApproval:
//            self.navigationController?.popToRootViewController(animated: true)
//        case .SubmitRequest:
//            let bookingInvites = BookingInvite()
//            let booking = BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .BookingConfirmation)
//            bookingInvites.booking = booking
//
//            self.navigationController?.pushViewController(bookingInvites, animated: true)
//        case .BookingConfirmation:
//            AppDelegate.shared.showHome(selectedIndex: 1)
//        }
        self.navigationController?.pushViewController(BookingInvites(), animated: true)
    }
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

//MARK: Helper Method
extension BookingInvite {
    func setUI(){
        guard let status = self.booking?.status else {return}
        
        switch status {
        case .PurchaseConfirmed,.TicketPurchasedConfirmed:
            break
        case .AwaitingApproval:
            self.lblTitle.text = "Pending Booking"
            
             self.viewPendingPayment.isHidden = false
             self.viewCancelReques.isHidden = false
             self.btnCancelRequest.isHidden = false
             self.viewSubmitRequest.isHidden = true
             self.btnSubmitRequest.isHidden = true
            
            self.viewBookingRequestSent.isHidden = true

            
             self.btnBack.isHidden = false
             self.btnClose.isHidden = true

            
        case .AwaitingVenueApproval:
            self.lblTitle.text = "Booking Invite"
            
             self.viewPendingPayment.isHidden = true
             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false
            
            self.viewBookingRequestSent.isHidden = true

            
            self.btnBack.isHidden = false
            self.btnClose.isHidden = true

        case .SubmitRequest:
             self.lblTitle.text = "Submit Request"

             self.viewPendingPayment.isHidden = true
             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false
            
            self.viewBookingRequestSent.isHidden = true

            
            self.btnBack.isHidden = false
            self.btnClose.isHidden = true
        case .BookingConfirmation:
            self.lblTitle.text = "Confirmation"
            self.btnSubmitRequest.setTitle("View in Bookings", for: .normal)
            
             self.viewPendingPayment.isHidden = true
             self.viewCancelReques.isHidden = true
             self.btnCancelRequest.isHidden = true
             self.viewSubmitRequest.isHidden = false
             self.btnSubmitRequest.isHidden = false
            
            self.viewBookingRequestSent.isHidden = false
            
            self.btnBack.isHidden = true
            self.btnClose.isHidden = false

        }
        
        
        //        if status == BookingStatusType.AwaitingApproval {
        //            self.lblTitle.text = "Pending Booking"
        //
        //            self.viewPendingPayment.isHidden = false
        //            self.viewCancelReques.isHidden = false
        //            self.btnCancelRequest.isHidden = false
        //            self.viewSubmitRequest.isHidden = true
        //            self.btnSubmitRequest.isHidden = true
        //        }
        //        else {
        //            self.lblTitle.text = "Booking Invite"
        //
        //            self.viewPendingPayment.isHidden = true
        //            self.viewCancelReques.isHidden = true
        //            self.btnCancelRequest.isHidden = true
        //            self.viewSubmitRequest.isHidden = false
        //            self.btnSubmitRequest.isHidden = false
        //        }

    }
}

//MARK: CollectionView
extension BookingInvite: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendsListCVC", for: indexPath) as! FriendsListCVC
        return cell
        
    }
}
extension BookingInvite: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize = CGSize(width: 66, height: collectionView.frame.height)
            return cellSize
    }
}

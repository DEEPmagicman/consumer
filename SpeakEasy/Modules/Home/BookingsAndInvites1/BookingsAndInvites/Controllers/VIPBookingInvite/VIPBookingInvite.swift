//
//  VIPBookingInvite.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 01/09/2022.
//

import UIKit



class VIPBookingInvite: BaseController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var arrOthersInvite = [OthersInvites(image: UIImage(named: "user1-others"), name: "You", percentage: "50%", isVerified: false), OthersInvites(image: UIImage(named: "user2-others"), name: "Henry", percentage: "0%", isVerified: true), OthersInvites(image: UIImage(named: "user3-others"), name: "Abby", percentage: "0%", isVerified: true), OthersInvites(image: UIImage(named: "user4-others"), name: "Madison", percentage: "0%", isVerified: false)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.collectionView.register(UINib(nibName: "OthersCVC", bundle: nil), forCellWithReuseIdentifier: "OthersCVC")
    }
    @IBAction func onBtnAccept(_ sender: Any) {
        let bookingInvites = BookingInvite()
        let booking = BookingsDataSet(brand: UIImage(named: "ic-prism"), bookingName: "PRYSM Chicago", performerCover: UIImage(named: "ic-await-approval-bg"), isTicket: false, date: "Sunday, August 7", status: .SubmitRequest)
        bookingInvites.booking = booking
        
        Utility.main.topViewController()?.navigationController?.pushViewController(bookingInvites, animated: true)
    }
    @IBAction func onBtnReject(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}



//MARK: CollectionView
extension VIPBookingInvite: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrOthersInvite.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OthersCVC", for: indexPath) as! OthersCVC
        cell.setData(userData: self.arrOthersInvite[indexPath.row])
        return cell
    }
}
extension VIPBookingInvite: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize = CGSize(width: 66, height: 100)
        return cellSize
    }
}

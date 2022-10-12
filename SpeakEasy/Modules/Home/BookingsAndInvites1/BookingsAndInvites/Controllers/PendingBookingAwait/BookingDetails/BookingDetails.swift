//
//  BookingDetails.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 03/09/2022.
//

import UIKit

class BookingDetails: BaseController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.collectionView.register(UINib(nibName: "FriendsListCVC", bundle: nil), forCellWithReuseIdentifier: "FriendsListCVC")
    }

    @IBAction func onBtnCancelRequest(_ sender: UIButton) {
        Utility.main.topViewController()?.navigationController?.popViewController(animated: true)
    }
}


//MARK: CollectionView
extension BookingDetails: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendsListCVC", for: indexPath) as! FriendsListCVC
        return cell
        
    }
}
extension BookingDetails: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize = CGSize(width: 66, height: collectionView.frame.height)
            return cellSize
    }
}

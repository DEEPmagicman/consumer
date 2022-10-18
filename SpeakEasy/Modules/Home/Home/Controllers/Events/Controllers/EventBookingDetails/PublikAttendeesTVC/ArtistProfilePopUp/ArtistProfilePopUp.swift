//
//  ArtistProfilePopUp.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/10/22.
//

import Foundation
import UIKit

class ArtistProfilePopUp: UIViewController {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var upcomingEventCollectionView: UICollectionView!
    
    var arrayTopEventsList = [
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG1"), lblPerformerName: "Steve Aoki", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Tonight!", currentLiveEventFires: nil, isLive: true),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG2"), lblPerformerName: "Qrion", lblVenueName: "PRYSM Chicago", imgBrandLogo: UIImage(named: "TopEventBrandLogo2"), lblEventDate: "Friday, July 8", currentLiveEventFires: nil, isLive: false),
        TopEventDataSet(imgEventCover: UIImage(named: "TopEventBG3"), lblPerformerName: "Worship Thursdays", lblVenueName: "TAO Chicago", imgBrandLogo: UIImage(named: "TaoLogo"), lblEventDate: "Thursday, July 21", currentLiveEventFires: nil, isLive: false)
    ]
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        self.upcomingEventCollectionView.register(UINib(nibName: "TopEventCVC", bundle: nil), forCellWithReuseIdentifier: "TopEventCVC")
    }
    
    @IBAction func onClickAddFavorite(_ sender: Any) {
        
    }
    
    @IBAction func onClickCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ArtistProfilePopUp: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayTopEventsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TopEventCVC", for: indexPath) as! TopEventCVC
        let data = arrayTopEventsList[indexPath.row]
        cell.setData(data: data)
        
        return cell
    }
}

extension ArtistProfilePopUp: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width * 0.65
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}

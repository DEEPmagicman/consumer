//
//  All.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 15/09/2022.
//

import UIKit

class All: BaseController {

    @IBOutlet weak var collectionView: UICollectionView!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
        // Do any additional setup after loading the view.
    }

}

extension All {
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "EventCVC", bundle: nil), forCellWithReuseIdentifier: "EventCVC")
    }
}

extension All: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if Constants.localizedCity == "Chicago" {
            return Constants.arrayAllEventsChicago.count
        }else {
            return Constants.arrayAllEventsCleveland.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventCVC", for: indexPath) as! EventCVC
        if Constants.localizedCity == "Chicago" {
            let data = Constants.arrayAllEventsChicago[indexPath.item]
            cell.setData(data: data)
            return cell
        }else {
            let data = Constants.arrayAllEventsCleveland[indexPath.item]
            cell.setData(data: data)
            return cell
        }

    }
}
extension All: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2.07
        let size = CGSize(width: width, height: width * 1.43)
        return size
    }
}

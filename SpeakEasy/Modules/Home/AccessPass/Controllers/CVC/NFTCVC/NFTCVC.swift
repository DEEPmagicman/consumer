//
//  NFTCVC.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 06/09/2022.
//

import UIKit

class NFTCVC: UICollectionViewCell {

    @IBOutlet weak var lblIssueNo: UILabel!
    @IBOutlet weak var imgNFT: UIImageView!
    @IBOutlet weak var lblGroup: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var imgSpeakEasy: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setData(nft: NFT){
        self.lblName.text = nft.nftName
        self.lblIssueNo.text = nft.issueNo
        self.lblGroup.text = nft.groupName
        self.imgNFT.image = nft.image
        if nft.nftName == "Sapphire 44" {
            self.imgSpeakEasy.isHidden = false
        }else{
            self.imgSpeakEasy.isHidden = true
        }
    }
}

//
//  NFTAssets.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 05/09/2022.
//

import UIKit

struct NFT {
    var image: UIImage?
    var groupName: String?
    var nftName: String?
    var issueNo: String?
}

class NFTAssets: BaseController {

    @IBOutlet weak var viewGetStarted: UIView!
    @IBOutlet weak var lblGetStarted: UILabelDeviceClass!
    @IBOutlet weak var btnGetStarted: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var externalNFTCollectionView: UICollectionView!
    @IBOutlet weak var lblVerified: UILabelDeviceClass!
    @IBOutlet weak var lblDisplayNFTs: UILabelDeviceClass!
    @IBOutlet weak var viewOpenNFTMarketPlace: UIView!
    @IBOutlet weak var btnOpenNFTMarketPlace: UIButton!
    @IBOutlet var myView: UIView!
    
    var arrExternalNFT = [NFT(image: UIImage(named: "NFT-Monkey"), groupName: "Yuga Labs", nftName: "Bored Ape Yacht Club 1771", issueNo: ""),
                          NFT(image: UIImage(named: "NFT-Person"), groupName: "CloneX - x Takashi Murakami", nftName: "CloneX #2621", issueNo: ""),
                          NFT(image: UIImage(named: "NFT-Monkey"), groupName: "Yuga Labs", nftName: "Bored Ape Yacht Club 1771", issueNo: ""),
                          NFT(image: UIImage(named: "NFT-Person"), groupName: "CloneX - x Takashi Murakami", nftName: "CloneX #2621", issueNo: "")]
    
    var arrNFT = [NFT(image: UIImage(named: "NFT-3"), groupName: "TAO Group Hospitality", nftName: "Sapphire 44", issueNo: "Issue No. 1,244 / 4,333"),
                          NFT(image: UIImage(named: "nft-1"), groupName: "CloneX - x Takashi Murakami", nftName: "CloneX #2621", issueNo: ""),
                          NFT(image: UIImage(named: "NFT-3"), groupName: "TAO Group Hospitality", nftName: "Sapphire 44", issueNo: "Issue No. 1,244 / 4,333"),
                          NFT(image: UIImage(named: "nft-1"), groupName: "CloneX - x Takashi Murakami", nftName: "CloneX #2621", issueNo: "")]

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.collectionView.register(UINib(nibName: "NFTCVC", bundle: nil), forCellWithReuseIdentifier: "NFTCVC")
        self.externalNFTCollectionView.register(UINib(nibName: "NFTCVC", bundle: nil), forCellWithReuseIdentifier: "NFTCVC")

        self.addTapGesture()
    }
    @IBAction func onBtnOpenNFTMarketPlace(_ sender: UIButton) {
        self.lblVerified.isHidden = true
        self.viewOpenNFTMarketPlace.isHidden = true
        self.btnOpenNFTMarketPlace.isHidden = true
        self.collectionView.isHidden = false
    }
    @IBAction func onBtnGetStart(_ sender: UIButton) {
        let controller = NFTsonSpeakEasy()
        controller.callback = { isOpenNFTMarket in
            if isOpenNFTMarket {
                self.openNFTMarket()
            }
        }
        self.navigationController?.present(controller, animated: true)
    }
    @IBAction func onBtnOpenGlobalNFTMarketPlace(_ sender: UIButton) {
        self.openNFTMarket()
    }
    
}

//MARK: - Helper Methods
extension NFTAssets {
    private func reloadUI(){
        self.lblVerified.isHidden = false
        self.viewOpenNFTMarketPlace.isHidden = false
        self.btnOpenNFTMarketPlace.isHidden = false
        self.collectionView.isHidden = true
        self.externalNFTCollectionView.isHidden = true
        self.lblDisplayNFTs.isHidden = false
        self.viewGetStarted.isHidden = false
        self.lblGetStarted.isHidden = false
        self.btnGetStarted.isHidden = false
    }
    func addTapGesture(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        myView.addGestureRecognizer(tapGesture)

    }
    @objc func handleTap(sender: UITapGestureRecognizer) {
        self.reloadUI()
    }
    func openNFTMarket(){
        self.lblVerified.isHidden = true
        self.lblDisplayNFTs.isHidden = true
        self.viewOpenNFTMarketPlace.isHidden = true
        self.btnOpenNFTMarketPlace.isHidden = true
        self.collectionView.isHidden = false
        self.externalNFTCollectionView.isHidden = false
        self.viewGetStarted.isHidden = true
        self.lblGetStarted.isHidden = true
        self.btnGetStarted.isHidden = true
    }
}


extension NFTAssets: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrExternalNFT.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NFTCVC", for: indexPath) as! NFTCVC
            cell.lblIssueNo.isHidden = false
            cell.setData(nft: self.arrNFT[indexPath.row])
            return cell
        case self.externalNFTCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NFTCVC", for: indexPath) as! NFTCVC
            cell.lblIssueNo.isHidden = true
            cell.setData(nft: self.arrExternalNFT[indexPath.row])
            return cell
        default:
            return UICollectionViewCell()
        }
        
    }
}
extension NFTAssets: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2.07
        let height = collectionView.frame.height
        let size = CGSize(width: width, height: height)
        return size
    }
}

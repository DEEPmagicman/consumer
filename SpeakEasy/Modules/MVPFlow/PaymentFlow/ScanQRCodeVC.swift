//
//  ScanQRCodeVC.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 29/02/24.
//

import UIKit
import FSPagerView

class ScanQRCodeVC: UIViewController {
    
    @IBOutlet weak var buyAnotherTicket: UIButton!
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var pagerView: FSPagerView!{
        didSet {
            self.pagerView.register(UINib(nibName: "CustomPagerViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setPageController()
        let attributedString = NSAttributedString(string: "Buy another ticket", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        buyAnotherTicket.setAttributedTitle(attributedString, for: .normal)
    }
    
    func setPageController(){
        pagerView.delegate = self
        pagerView.dataSource = self
        //        pagerView.itemSize = CGSize(width: 200, height: 180)
        pageControl.numberOfPages = 2
        pageControl.itemSpacing = 8
        pageControl.contentHorizontalAlignment = .center
        pageControl.contentInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
        
    }
    
}

extension ScanQRCodeVC: FSPagerViewDelegate, FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return 2
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! CustomPagerViewCell
        
        // add dummy data
        let newElement = AppClipTicket(id: "abc", name: "Comped Ticket", price: 10.0,description: "Valid with door approval only!",selectedQuantity:2)
        let newElement2 = AppClipTicket(id: "abcd", name: "Reduced GA - Male", price: 15.0 , description: "Only valid with guest list invite",selectedQuantity:2)
        let newElement3 = AppClipTicket(id: "abcde", name: "Coat Check", price: 15.0 , description: "Required for each guest with coat",selectedQuantity:2)
        
        if index == 0 {
            cell.appClipTickets.append(newElement)
            cell.appClipTickets.append(newElement2)
        }else if index == 1{
            cell.appClipTickets.append(newElement3)
        }
        
        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}


//
//  NFTsonSpeakEasy.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 06/09/2022.
//

import UIKit

class NFTsonSpeakEasy: UIViewController {

    var callback:((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func onBtnDismiss(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onBtnOpenNFTMarket(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.callback!(true)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

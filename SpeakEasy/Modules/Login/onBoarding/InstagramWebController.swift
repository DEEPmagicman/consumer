//
//  InstagramWebController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 30/12/22.
//

import UIKit
import WebKit

protocol InstagramConnectedDelegate {
    func instaConnect()
}

class InstagramWebController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var instaConnectedDelegate: InstagramConnectedDelegate?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        setNevigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupWebview()
    }
    
    func setNevigationBar() {
        self.navigationItem.leftBarButtonItem?.action = #selector(leftAction)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc func leftAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupWebview() {
        webView.navigationDelegate = self
        webView.load(URLRequest(url: URL(string: APIBuilder.getInstagramCode)!))
    }

}

extension InstagramWebController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let link = navigationAction.request.url?.description, link.contains("code="),
            let code = link.components(separatedBy: "code=").last?.components(separatedBy: "#_").joined() {
            InstagramManager.getInstagramToken(code: code) {
                self.dismiss(animated: true, completion: nil)
                self.instaConnectedDelegate?.instaConnect()
            }
            
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    }
}

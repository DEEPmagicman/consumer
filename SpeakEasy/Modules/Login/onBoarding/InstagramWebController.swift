//
//  InstagramWebController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 30/12/22.
//

import UIKit
import WebKit

class InstagramWebController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
        
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
//        userViewModel?.isLoading = true
        if let link = navigationAction.request.url?.description, link.contains("code="),
            let code = link.components(separatedBy: "code=").last?.components(separatedBy: "#_").joined() {
            InstagramManager.getInstagramToken(code: code)
            navigationController?.dismiss(animated: true)
//            self.dismiss(animated: true, completion: nil)
            
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        userViewModel?.isLoading = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        userViewModel?.isLoading = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        userViewModel?.isLoading = false
    }
}

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
    private var isInstaApiCall = false
    
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
        WebCacheCleaner.clear()

        webView.navigationDelegate = self
        webView.load(URLRequest(url: URL(string: APIBuilder.getInstagramCode)!))
    }

}

extension InstagramWebController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let link = navigationAction.request.url?.description, link.contains("code="),
            let code = link.components(separatedBy: "code=").last?.components(separatedBy: "#_").joined() {
            if isInstaApiCall == false {
                InstagramManager.getInstagramToken(code: code) {
                    self.dismiss(animated: true, completion: nil)
                    self.instaConnectedDelegate?.instaConnect()
                    self.isInstaApiCall = true
                }

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

final class WebCacheCleaner {
    class func clear() {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }
    }
}


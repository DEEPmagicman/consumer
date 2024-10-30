//
//  TokenManager.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 17/10/24.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()
    private init() {}

    var accessToken: String?
    private var isRefreshingToken = false
    private var pendingRequests: [() -> Void] = []
    
    private let lock = DispatchSemaphore(value: 1)

    func getAccessToken(completion: @escaping (String?) -> Void) {
        guard let token = accessToken else {
            refreshToken(completion: { _ in
                completion(self.accessToken)
            })
            return
        }
        completion(token)
    }

    func refreshToken(completion: @escaping (Bool) -> Void) {
        lock.wait()
        if isRefreshingToken {
            lock.signal()
            return
        }
        isRefreshingToken = true
        lock.signal()
        
        let param = ["accessToken": UserDefault.shared.accessToken ?? "", "refreshToken": UserDefault.shared.refreshToken ?? ""] as [String: Any]
        
        AFWrapper.postRequestRefreshToken(APIBuilder.refreshTokenAPI, params: param, headers: Header.header()) { response in
            guard let responseDic = response as? [String: Any], let accessToken = responseDic["accessToken"] as? String, let refreshToken = responseDic["refreshToken"] as? String else {
                return
            }
            self.accessToken = accessToken
            UserDefault.shared.accessToken = accessToken
            UserDefault.shared.refreshToken = refreshToken
            self.isRefreshingToken = false
            self.pendingRequests.forEach { $0() }
            self.pendingRequests.removeAll()
            completion(true)
        } failure: { _ in
            self.isRefreshingToken = false
            completion(false)
        }
    }

    func addPendingRequest(_ request: @escaping () -> Void) {
        pendingRequests.append(request)
    }
}


//
//  SettingsService.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 02/06/26.
//

import Foundation

final class SettingsService {

    // MARK: - Email

    func requestEmailChangeOTP(
        email: String,
        completion: @escaping (
            _ otp: String,
            _ otpRef: String,
            _ isSuccess: Bool,
            _ errorMsg: String?
        ) -> Void
    ) {
        let params = [
            "email": email
        ]

        AFWrapper.postRequest(
            APIBuilder.changeEmailURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion("", "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String ?? "",
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError,
               err.code == 0 {

                completion("", "", false, err.domain)
                return
            }

            completion("", "", false, nil)
        }
    }

    // MARK: - Phone

    func requestPhoneChangeOTP(
        phone: String,
        countryCode: String,
        completion: @escaping (
            _ otp: String,
            _ otpRef: String,
            _ isSuccess: Bool,
            _ errorMsg: String?
        ) -> Void
    ) {

        let params = [
            "phone": phone.replacingOccurrences(of: "-", with: ""),
            "code": countryCode
        ]

        AFWrapper.postRequest(
            APIBuilder.changePhoneNumURL,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion("", "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String ?? "",
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError,
               err.code == 0 {

                completion("", "", false, err.domain)
                return
            }

            completion("", "", false, nil)
        }
    }

    // MARK: - Verify OTP

    func verifyPhoneOrEmailOTP(
        otp: String,
        otpRef: String,
        isPhone: Bool = false,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errorMsg: String?
        ) -> Void
    ) {

        let params: [String: Any] = [
            "otp": otp,
            "otpRef": otpRef
        ]

        let url = isPhone
            ? APIBuilder.changePhoneOTPVerifyURL
            : APIBuilder.changeEmailOTPVerifyURL

        AFWrapper.postRequest(
            url,
            params: params,
            headers: Header.header()
        ) { response in

            guard let userDic = response as? [String: Any] else {
                completion(false, nil)
                return
            }

            let imageDic = userDic["consumerUserImage"] as? [String: Any]

            let user = User(fromDictionary: userDic)

            UserDefault.shared.user = user
            UserDefault.shared.isGuest = false
            UserDefault.shared.user?.image = ImageDetail(
                fromDictionary: imageDic ?? [:]
            )

            completion(true, nil)

        } failure: { error in

            if let err = error as? NSError,
               err.code == 0 {

                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }

    // MARK: - Resend OTP

    func resendPhoneOrEmailOTP(
        otpRef: String,
        isPhone: Bool = false,
        completion: @escaping (
            _ otp: String?,
            _ otpRef: String,
            _ isSuccess: Bool,
            _ errorMsg: String?
        ) -> Void
    ) {

        let params = [
            "otpRef": otpRef
        ]

        let url = isPhone
            ? APIBuilder.changePhoneResendOTPURL
            : APIBuilder.changeEmailResendOTPURL

        AFWrapper.postRequest(
            url,
            params: params,
            headers: Header.header()
        ) { response in

            guard
                let responseDic = response as? [String: Any],
                let otpRef = responseDic["otpRef"] as? String
            else {
                completion(nil, "", false, nil)
                return
            }

            completion(
                responseDic["otp"] as? String,
                otpRef,
                true,
                nil
            )

        } failure: { error in

            if let err = error as? NSError,
               err.code == 0 {

                completion(nil, "", false, err.domain)
                return
            }

            completion(nil, "", false, nil)
        }
    }

    // MARK: - Password

    func changePassword(
        currentPassword: String,
        newPassword: String,
        confirmPassword: String,
        completion: @escaping (
            _ isSuccess: Bool,
            _ errorMsg: String?
        ) -> Void
    ) {
        let params = [
            "currentPassword": currentPassword,
            "newPassword": newPassword,
            "confirmPassword": confirmPassword
        ]

        AFWrapper.patchRequest(
            APIBuilder.changePasswordURL,
            params: params,
            headers: Header.header()
        ) { _ in

            completion(true, nil)

        } failure: { error in

            if let err = error as? NSError,
               err.code == 0 {

                completion(false, err.domain)
                return
            }

            completion(false, nil)
        }
    }
}

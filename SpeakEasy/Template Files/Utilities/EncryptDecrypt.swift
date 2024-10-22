//
//  File.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 06/03/24.
//

import Foundation
import CommonCrypto

struct EncryptKeys {
    static let key = Data(base64Encoded: "j2bQhJar8pQnfYqhRtm7oQ/Q6jccysoXhjRl5Z5u05s=")!
    static let iv = Data(base64Encoded: "1lSi0HuO7qs2+n0AMEyioQ==")!
    
    static let headerKey = Data(base64Encoded: "0nKT8pkl4RnlNlbfQQQjsddse4zQP08IHFk7x0u72rA=")!
    static let headerIV = Data(base64Encoded: "33JIHSC0bjItzjGhT8olkg==")!
}

func encrypt(data: Data, key: Data, iv: Data) throws -> Data {
    let bufferSize = data.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesEncrypted: Int = 0
    let status = key.withUnsafeBytes { keyBytes in
        iv.withUnsafeBytes { ivBytes in
            data.withUnsafeBytes { dataBytes in
                buffer.withUnsafeMutableBytes { bufferBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        key.count,
                        ivBytes.baseAddress, // Provide IV
                        dataBytes.baseAddress,
                        data.count,
                        bufferBytes.baseAddress,
                        bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }
    }
    buffer.count = numBytesEncrypted
    return buffer
}


func decrypt(data: Data, key: Data, iv: Data) throws -> Data {
    let bufferSize = data.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesDecrypted: Int = 0
    let status = key.withUnsafeBytes { keyBytes in
        iv.withUnsafeBytes { ivBytes in
            data.withUnsafeBytes { dataBytes in
                buffer.withUnsafeMutableBytes { bufferBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        key.count,
                        ivBytes.baseAddress, // Provide IV
                        dataBytes.baseAddress,
                        data.count,
                        bufferBytes.baseAddress,
                        bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
    }
    buffer.count = numBytesDecrypted
    return buffer
}

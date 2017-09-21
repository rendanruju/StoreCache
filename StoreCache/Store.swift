//
//  Store.swift
//  VPNGo2
//
//  Created by admin on 2017/6/9.
//  Copyright © 2017年 lez. All rights reserved.
//


import Foundation
import CryptoSwift
import ObjectMapper

public protocol LZMappable: Mappable {
    init()
}

open class Store {
    open static let shareInstance = Store()
    
    open var cryptStore : CryptStore
    
    init() {
        cryptStore = CryptStore(storeName: "Aes_Store", crypt: AesCrypt(key: key, iv: iv)!)
    }
}

let key: [UInt8] = [1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4]
let iv: [UInt8] = [1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4]

extension Data {
    
    public func toHexString() -> String {
        return self.arrayOfBytes().toHexString()
    }
    
    public func arrayOfBytes() -> [UInt8] {
        let count = self.count / MemoryLayout<UInt8>.size
        var bytesArray = [UInt8](repeating: 0, count: count)
        (self as NSData).getBytes(&bytesArray, length:count * MemoryLayout<UInt8>.size)
        return bytesArray
    }
    
    public init(bytes: [UInt8]) {
        self = Data.withBytes(bytes)
    }
    
    static public func withBytes(_ bytes: [UInt8]) -> Data {
        return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
}

open class CryptStore: StoreProtocol {
    
    //MARK: - Property
    var crypt: CryptProtocol
    var userDefaults: UserDefaults
    /// 是否需要对key进行编码
    var needEncodeKey: Bool
    
    //MARK: - Lifecycle
    
    public init(storeName: String? = nil, crypt: CryptProtocol, needEncodeKey: Bool = true) {
        self.needEncodeKey = needEncodeKey
        self.crypt = crypt
        self.userDefaults = UserDefaults(suiteName: storeName)!
    }
    
    //MARK: - StoreProtocol
    
    open func setInteger(_ value: Int, forKey defaultName: String) -> Bool {
        return self.setObject("\(value)".data(using: String.Encoding.utf8), forKey: defaultName)
    }
    
    open func setFloat(_ value: Float, forKey defaultName: String) -> Bool {
        return self.setObject("\(value)".data(using: String.Encoding.utf8), forKey: defaultName)
    }
    
    open func setDouble(_ value: Double, forKey defaultName: String) -> Bool {
        return self.setObject("\(value)".data(using: String.Encoding.utf8), forKey: defaultName)
    }
    
    open func setBool(_ value: Bool, forKey defaultName: String) -> Bool {
        return self.setObject("\(value)".data(using: String.Encoding.utf8), forKey: defaultName)
    }
    
    open func setString(_ value: String, forKey defaultName: String) -> Bool {
        return self.setObject(value.data(using: String.Encoding.utf8), forKey: defaultName)
    }
    
    open func setObject(_ data: Data?, forKey defaultName: String) -> Bool {
        let key = needEncodeKey ? defaultName.md5() : defaultName
        if data == nil || data!.count == 0 {
            self.userDefaults.removeObject(forKey: key)
            return true
        }
        self.userDefaults.set(crypt.encrypt(data), forKey: key)
        return true
    }
    
    
    open func integerForKey(_ defaultName: String, defaultValue: Int) -> Int {
        if let decryptedData = self.objectForKey(defaultName) {
            if let value = String(data: decryptedData, encoding: String.Encoding.utf8) {
                return (value as NSString).integerValue
            }
        }
        return defaultValue
    }
    
    open func floatForKey(_ defaultName: String, defaultValue: Float) -> Float {
        if let decryptedData = self.objectForKey(defaultName) {
            if let value = String(data: decryptedData, encoding: String.Encoding.utf8) {
                return (value as NSString).floatValue
            }
        }
        return defaultValue
    }
    
    open func doubleForKey(_ defaultName: String, defaultValue: Double) -> Double {
        if let decryptedData = self.objectForKey(defaultName) {
            if let value = String(data: decryptedData, encoding: String.Encoding.utf8) {
                return (value as NSString).doubleValue
            }
        }
        return defaultValue
    }
    
    open func boolForKey(_ defaultName: String, defaultValue: Bool) -> Bool {
        if let decryptedData = self.objectForKey(defaultName) {
            if let value = String(data: decryptedData, encoding: String.Encoding.utf8) {
                return (value as NSString).boolValue
            }
        }
        return defaultValue
    }
    
    open func stringForKey(_ defaultName: String) -> String {
        if let decryptedData = self.objectForKey(defaultName) {
            return String(data: decryptedData, encoding: String.Encoding.utf8) ?? ""
        } else {
            return ""
        }
    }
    
    open func objectForKey(_ defaultName: String) -> Data? {
        let data = self.userDefaults.object(forKey: needEncodeKey ? defaultName.md5() : defaultName) as? Data
        return crypt.decrypt(data)
    }
    
    open func removeObjectForKey(_ defaultName: String) {
        self.userDefaults.removeObject(forKey: defaultName)
    }
    
    open func removeAllObjects() {
        for (key, _) in userDefaults.dictionaryRepresentation() {
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
    }
    
    open func setMapper(_ data:LZMappable, forKey defaultName: String) ->Bool {
        if let value = data.toJSONString() {
            return setString(value, forKey: defaultName);
        }
        else {
            return false
        }
    }
    
    open func mapperForKeyString(_ defaultName: String) ->String {
        return stringForKey(defaultName)
    }
    
    open func mapperForKeyObject<Element:LZMappable>(_ defaultName: String) ->Element? {
        return Mapper<Element>().map(JSONString: stringForKey(defaultName))
    }
    
    open func mapperForKeyObject<Element:LZMappable>(_ defaultName: String, defaultObject:Element) ->Element {
        return Mapper<Element>().map(JSONString: stringForKey(defaultName),toObject: defaultObject)
    }
    
    open func setMapperArray<Element:LZMappable>(_ data: [Element], forKey defaultName: String) ->Bool {
        if let value = data.toJSONString() {
            return setString(value, forKey: defaultName);
        }
        else {
            return false
        }
    }
    
    open func mapperArrayForKey<Element:LZMappable>(_ defaultName: String) -> [Element] {
        if let value = [Element](JSONString: stringForKey(defaultName)) {
            return value
        }
        else {
            return []
        }
    }
}

public protocol CryptProtocol {
    func encrypt(_ data: Data?) -> Data?
    func decrypt(_ data: Data?) -> Data?
}


open class AesCrypt: CryptProtocol {
    
    var aes: AES!
    
    public init?(key: [UInt8], iv: [UInt8]) {
        do {
            self.aes = try AES(key: key, iv: iv)
        } catch {
            return nil
        }
    }
    
    open func encrypt(_ data: Data?) -> Data? {
        if let data = data {
            do {
                let encryptedBytes = try self.aes.encrypt(data.arrayOfBytes())
                let encryptedData = Data(bytes: encryptedBytes)
                return encryptedData.base64EncodedData(options: NSData.Base64EncodingOptions(rawValue: 0))
            } catch {
                return nil
            }
        }
        return nil
    }
    
    open func decrypt(_ data: Data?) -> Data? {
        if let data = data {
            if let encryptedData = Data(base64Encoded: data,
                                        options: NSData.Base64DecodingOptions(rawValue: 0)) {
                do {
                    let decryptedBytes = try self.aes.decrypt(encryptedData.arrayOfBytes())
                    return Data(bytes: decryptedBytes)
                } catch {
                    return nil
                }
            }
        }
        return nil
    }
}

protocol StoreProtocol {
    func setInteger(_ value: Int, forKey defaultName: String) -> Bool
    func setFloat(_ value: Float, forKey defaultName: String) -> Bool
    func setDouble(_ value: Double, forKey defaultName: String) -> Bool
    func setBool(_ value: Bool, forKey defaultName: String) -> Bool
    func setString(_ value: String, forKey defaultName: String) -> Bool
    func setObject(_ data: Data?, forKey defaultName: String) -> Bool
    func stringForKey(_ defaultName: String) -> String
    func integerForKey(_ defaultName: String, defaultValue: Int) -> Int
    func floatForKey(_ defaultName: String, defaultValue: Float) -> Float
    func doubleForKey(_ defaultName: String, defaultValue: Double) -> Double
    func boolForKey(_ defaultName: String, defaultValue: Bool) -> Bool
    func objectForKey(_ defaultName: String) -> Data?
    func removeObjectForKey(_ defaultName: String)
    func removeAllObjects()
}

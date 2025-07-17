//
//  LocalKeyChainService.swift
//  Utils
//
//  Created by Andriy Biguniak on 17.07.2025.
//

import Foundation


// MARK: - ISecurePersistenceService

public protocol ISecurePersistenceService: Actor, Sendable
{
    nonisolated
    func secureSave<T: Encodable>(_ data: T, key: String) throws

    nonisolated
    func secureRetrieve<T: Decodable>(_ type: T.Type, key: String) throws -> T?

    nonisolated
    func secureRemove<T: Decodable>(_ type: T.Type, key: String) throws
}


// MARK: - SecurePersistenceService

actor SecurePersistenceService: ISecurePersistenceService
{
    enum ErrorDomain: Error, CustomDebugStringConvertible, Equatable
    {
        case operationIsNotAvailable
        case keychainOperationError(OSStatus)
        case inconsistent

        var debugDescription: String {
            switch self {
                case .operationIsNotAvailable:
                    return "PersistenceService: operationIsNotAvailable"
                case .keychainOperationError(let status):
                    let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
                    return "PersistenceService: unexpectedStatus - \(message)"
                case .inconsistent:
                    return "PersistenceService: inconsistent"
            }
        }
    }
    
    nonisolated
    func secureSave<T: Encodable>(_ data: T, key: String) throws {
        if Thread.isMainThread {
            print("keychain operation was executed on main actor")
            throw ErrorDomain.operationIsNotAvailable
        }
        let encoder = JSONEncoder()
        let encoded_data = try encoder.encode(data)
        var query = Dictionary<CFString, Any>()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = String(reflecting: type(of: data))
        query[kSecAttrAccount] = key
        query[kSecValueData] = encoded_data
        var status = SecItemAdd(query as CFDictionary, nil)
        switch status {
            case errSecSuccess:
                return
            case errSecDuplicateItem:
                query.removeValue(forKey: kSecValueData)
                let attributes_to_update: Dictionary<CFString, Any> = [
                    kSecValueData: encoded_data
                ]
                status = SecItemUpdate(query as CFDictionary, attributes_to_update as CFDictionary)
                guard status == errSecSuccess else {
                    throw ErrorDomain.keychainOperationError(status)
                }
            default:
                throw ErrorDomain.keychainOperationError(status)
        }
    }
    
    nonisolated
    func secureRetrieve<T: Decodable>(_ type: T.Type, key: String) throws -> T? {
        if Thread.isMainThread {
            print("keychain operation was executed on main actor")
            throw ErrorDomain.operationIsNotAvailable
        }
        let query: Dictionary<CFString, Any> = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: String(reflecting: type),
            kSecAttrAccount: key,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
        var item_copy: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item_copy)
        switch status {
            case errSecItemNotFound:
                return nil
            case errSecSuccess:
                break
            default:
                throw ErrorDomain.keychainOperationError(status)
        }
        let decoder = JSONDecoder()
        if let data = item_copy as? Data {
            return try decoder.decode(type, from: data)
        } else {
            throw ErrorDomain.inconsistent
        }
    }
    
    nonisolated
    func secureRemove<T: Decodable>(_ type: T.Type, key: String) throws {
        if Thread.isMainThread {
            print("keychain operation was executed on main actor")
            throw ErrorDomain.operationIsNotAvailable
        }
        let query: Dictionary<CFString, Any> = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: String(reflecting: type),
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw ErrorDomain.keychainOperationError(status)
        }
    }
}

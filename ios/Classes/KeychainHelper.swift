//
//  KeychainHelper.swift
//  tnexkeychain
//
//  Created by Tnex on 15/09/2022.
//

import Foundation
import LocalAuthentication

class KeychainHelper {
    
    private init() {}
    
    static func remove(key: String) {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key]
        
        SecItemDelete(query as CFDictionary)
    }
    
    static func getBioSecAccessControl() -> SecAccessControl {
        var access: SecAccessControl?
        var error: Unmanaged<CFError>?
        
        if #available(iOS 11.3, *) {
            access = SecAccessControlCreateWithFlags(nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error)
        } else {
            access = SecAccessControlCreateWithFlags(nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .touchIDCurrentSet,
                &error)
        }
        precondition(access != nil, "SecAccessControlCreateWithFlags failed")
        return access!
    }
    
    static func available(key: String) -> Bool {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne,
            kSecUseAuthenticationUI as String : kSecUseAuthenticationUIFail] as CFDictionary
        
        var dataTypeRef: AnyObject? = nil
        
        let status = SecItemCopyMatching(query, &dataTypeRef)
        
        // errSecInteractionNotAllowed - for a protected item
        // errSecAuthFailed - when touch Id is locked
        return status == noErr || status == errSecInteractionNotAllowed || status == errSecAuthFailed
    }
    
    
    static func createBioProtectedEntry(key: String, data: Data) -> OSStatus {
        remove(key: key)
        
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecAttrAccessControl as String: getBioSecAccessControl(),
            kSecValueData as String   : data ] as CFDictionary
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadBioProtected(key: String, context: LAContext? = nil,
                                 prompt: String? = nil) -> Data? {
        var query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecAttrAccessControl as String: getBioSecAccessControl(),
            kSecMatchLimit as String  : kSecMatchLimitOne ]
        
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
            
            // Prevent system UI from automatically requesting Touc ID/Face ID authentication
            // just in case someone passes here an LAContext instance without
            // a prior evaluateAccessControl call
            query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUISkip
        }
        
        if let prompt = prompt {
            query[kSecUseOperationPrompt as String] = prompt
        }

        var dataTypeRef: AnyObject? = nil
        
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return (dataTypeRef! as! Data)
        } else {
            return nil
        }
    }
    
}

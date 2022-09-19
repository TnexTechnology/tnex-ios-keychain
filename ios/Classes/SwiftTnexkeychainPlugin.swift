import Flutter
import UIKit
import LocalAuthentication



public class SwiftTnexkeychainPlugin: NSObject, FlutterPlugin {
    
    enum BiometryState: CustomStringConvertible {
        case available, locked, notAvailable
        
        var description: String {
            switch self {
            case .available:
                return "available"
            case .locked:
                return "locked (temporarily)"
            case .notAvailable:
                return "notAvailable (turned off/not enrolled)"
            }
        }
    }
    
    let entryName = "keychain-tnex.login_entry_bio"
    let entryContents = "Tnex login bio!"
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tnexkeychain", binaryMessenger: registrar.messenger())
    let instance = SwiftTnexkeychainPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
          case "authenticate":
            authenticate(arguments: call.arguments as! Dictionary<String, Any>, result: result)
              break
          case "createEntry":
            createEntry(result: result)
              break
          default:
              result(FlutterMethodNotImplemented)
      }
  }
    
    private func createEntry(result: @escaping FlutterResult) {
        let r = KeychainHelper.createBioProtectedEntry(key: entryName, data: Data(entryContents.utf8))
        print(r == noErr ? "Entry created" : "Entry creation failed, osstatus=\(r)")
        if(r == noErr){
            result(true)
        }else{
            result(false)
        }
    }
    
    private func authenticate(arguments: Dictionary<String, Any>, result: @escaping FlutterResult) {
        var localizedReason = "Vui lòng cài đặt vân tay."
        if let argLocalizedReason = arguments["localizedReason"] as? String, !argLocalizedReason.isEmpty {
            localizedReason = argLocalizedReason
        }
        
        let isBioState = checkBiometryState(localizedReason: localizedReason, arguments: arguments, result: result)
        if(isBioState){
            let authContext = LAContext()
            if let localizedFallbackTitle = arguments["localizedFallbackTitle"] as? String, !localizedFallbackTitle.isEmpty {
                authContext.localizedFallbackTitle = localizedFallbackTitle
            }
            
            let accessControl = KeychainHelper.getBioSecAccessControl()
            authContext.evaluateAccessControl(accessControl,
                                              operation: .useItem,
                                              localizedReason: localizedReason) {
                (success, error) in
                if success, let data = KeychainHelper.loadBioProtected(key: self.entryName,
                                                                       context: authContext) {
                    let dataStr = String(decoding: data, as: UTF8.self)
                    print("Keychain entry contains: \(dataStr)")
                    result(true)
                } else {
                    print("Can't read entry, error: \(error?.localizedDescription ?? "-")")
                    result(false)
                }
            }
        }
    }
    
    private func alertMessage(message: String, firstButton: String, result: @escaping FlutterResult, secondButton: String?){
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: firstButton, style: .default, handler: { (_) in
            result(false)
        }))
        if let sButton = secondButton, !sButton.isEmpty{
            alert.addAction(UIAlertAction(title: sButton, style: .default, handler: { (_) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                result(false);
            }))
        }

        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: {
                    print("completion block")
                })
    }
    
    
    private func checkBiometryState(localizedReason: String, arguments: Dictionary<String, Any> , result: @escaping FlutterResult) -> Bool {
        let authContext = LAContext()
        var error: NSError?
        var errorCode = "NotAvailable"
        
        let biometryAvailable = authContext.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let laError = error as? LAError {
            if(laError.code == LAError.Code.biometryLockout){
                alertMessage(message: arguments["lockOut"] as? String ?? "Lock out", firstButton: arguments["okButton"] as? String ?? "OK", result: result, secondButton: nil)
                result(false)
                return false
            }else if(laError.code == LAError.Code.biometryNotEnrolled){
                if (arguments["useErrorDialogs"] as? Bool) != nil {
                    alertMessage(message: arguments["goToSettingDescriptionIOS"] as? String ?? "Go to setting", firstButton: arguments["okButton"] as? String ?? "OK", result: result, secondButton: arguments["goToSetting"] as? String)
                    result(false)
                    return false
                }
                
                errorCode = laError.code == LAError.Code.passcodeNotSet ? "PasscodeNotSet" : "NotEnrolled";
            }
        }
        
        if(biometryAvailable){
            return true
        }else{
            result(FlutterError( code: errorCode, message: error?.localizedDescription, details: error?.domain ))
            return false
        }
    }
    
}

#import "TnexkeychainPlugin.h"
#if __has_include(<tnexkeychain/tnexkeychain-Swift.h>)
#import <tnexkeychain/tnexkeychain-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "tnexkeychain-Swift.h"
#endif

@implementation TnexkeychainPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTnexkeychainPlugin registerWithRegistrar:registrar];
}
@end

//
//  WWDeviceInfo.m
//  strongvpn
//
//  Created by witworkapp on 12/17/20.
//  Copyright © 2020 witworkapp. All rights reserved.
//


#include <ifaddrs.h>
#include <arpa/inet.h>
#import <mach/mach.h>
#import <mach-o/arch.h>
#import <CoreLocation/CoreLocation.h>
    
#import "WWDeviceInfo.h"
#import "DeviceUID.h"
#import <DeviceCheck/DeviceCheck.h>

#if !(TARGET_OS_TV)
#import <WebKit/WebKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#endif

typedef NS_ENUM(NSInteger, DeviceType) {
    DeviceTypeHandset,
    DeviceTypeTablet,
    DeviceTypeTv,
    DeviceTypeUnknown
};

#define DeviceTypeValues [NSArray arrayWithObjects: @"Handset", @"Tablet", @"Tv", @"unknown", nil]

#if !(TARGET_OS_TV)
@import CoreTelephony;
@import Darwin.sys.sysctl;
#endif

@implementation WWDeviceInfo
{
    bool hasListeners;
}

+ (BOOL)requiresMainQueueSetup
{
   return NO;
}


- (id)init
{
    if (self = [super init]) {
#if !TARGET_OS_TV
        _lowBatteryThreshold = 0.20;
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(batteryLevelDidChange:)
                                                     name:UIDeviceBatteryLevelDidChangeNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(powerStateDidChange:)
                                                     name:UIDeviceBatteryStateDidChangeNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(powerStateDidChange:)
                                                     name:NSProcessInfoPowerStateDidChangeNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(headphoneConnectionDidChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object: [AVAudioSession sharedInstance]];
#endif
    }

    return self;
}

- (void)startObserving {
    hasListeners = YES;
}

- (void)stopObserving {
    hasListeners = NO;
}

- (DeviceType) getDeviceType
{
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) {
        case UIUserInterfaceIdiomPhone: return DeviceTypeHandset;
        case UIUserInterfaceIdiomPad: return DeviceTypeTablet;
        case UIUserInterfaceIdiomTV: return DeviceTypeTv;
        default: return DeviceTypeUnknown;
    }
}

- (NSDictionary *) getStorageDictionary {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: nil];
}

- (NSString *) getSystemName {
    UIDevice *currentDevice = [UIDevice currentDevice];
    return currentDevice.systemName;
}

- (NSString *) getSystemVersion {
    UIDevice *currentDevice = [UIDevice currentDevice];
    return currentDevice.systemVersion;
}

- (NSString *) getDeviceName {
    UIDevice *currentDevice = [UIDevice currentDevice];
    return currentDevice.name;
}

- (NSString *) getAppName {
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return displayName ? displayName : bundleName;
}

- (NSString *) getBundleId {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *) getAppVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *) getBuildNumber {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSDictionary *) getDeviceNamesByCode {
    return @{
        @"iPod1,1": @"iPod Touch", // (Original)
        @"iPod2,1": @"iPod Touch", // (Second Generation)
        @"iPod3,1": @"iPod Touch", // (Third Generation)
        @"iPod4,1": @"iPod Touch", // (Fourth Generation)
        @"iPod5,1": @"iPod Touch", // (Fifth Generation)
        @"iPod7,1": @"iPod Touch", // (Sixth Generation)
        @"iPod9,1": @"iPod Touch", // (Seventh Generation)
        @"iPhone1,1": @"iPhone", // (Original)
        @"iPhone1,2": @"iPhone 3G", // (3G)
        @"iPhone2,1": @"iPhone 3GS", // (3GS)
        @"iPad1,1": @"iPad", // (Original)
        @"iPad2,1": @"iPad 2", //
        @"iPad2,2": @"iPad 2", //
        @"iPad2,3": @"iPad 2", //
        @"iPad2,4": @"iPad 2", //
        @"iPad3,1": @"iPad", // (3rd Generation)
        @"iPad3,2": @"iPad", // (3rd Generation)
        @"iPad3,3": @"iPad", // (3rd Generation)
        @"iPhone3,1": @"iPhone 4", // (GSM)
        @"iPhone3,2": @"iPhone 4", // iPhone 4
        @"iPhone3,3": @"iPhone 4", // (CDMA/Verizon/Sprint)
        @"iPhone4,1": @"iPhone 4S", //
        @"iPhone5,1": @"iPhone 5", // (model A1428, AT&T/Canada)
        @"iPhone5,2": @"iPhone 5", // (model A1429, everything else)
        @"iPad3,4": @"iPad", // (4th Generation)
        @"iPad3,5": @"iPad", // (4th Generation)
        @"iPad3,6": @"iPad", // (4th Generation)
        @"iPad2,5": @"iPad Mini", // (Original)
        @"iPad2,6": @"iPad Mini", // (Original)
        @"iPad2,7": @"iPad Mini", // (Original)
        @"iPhone5,3": @"iPhone 5c", // (model A1456, A1532 | GSM)
        @"iPhone5,4": @"iPhone 5c", // (model A1507, A1516, A1526 (China), A1529 | Global)
        @"iPhone6,1": @"iPhone 5s", // (model A1433, A1533 | GSM)
        @"iPhone6,2": @"iPhone 5s", // (model A1457, A1518, A1528 (China), A1530 | Global)
        @"iPhone7,1": @"iPhone 6 Plus", //
        @"iPhone7,2": @"iPhone 6", //
        @"iPhone8,1": @"iPhone 6s", //
        @"iPhone8,2": @"iPhone 6s Plus", //
        @"iPhone8,4": @"iPhone SE", //
        @"iPhone9,1": @"iPhone 7", // (model A1660 | CDMA)
        @"iPhone9,3": @"iPhone 7", // (model A1778 | Global)
        @"iPhone9,2": @"iPhone 7 Plus", // (model A1661 | CDMA)
        @"iPhone9,4": @"iPhone 7 Plus", // (model A1784 | Global)
        @"iPhone10,3": @"iPhone X", // (model A1865, A1902)
        @"iPhone10,6": @"iPhone X", // (model A1901)
        @"iPhone10,1": @"iPhone 8", // (model A1863, A1906, A1907)
        @"iPhone10,4": @"iPhone 8", // (model A1905)
        @"iPhone10,2": @"iPhone 8 Plus", // (model A1864, A1898, A1899)
        @"iPhone10,5": @"iPhone 8 Plus", // (model A1897)
        @"iPhone11,2": @"iPhone XS", // (model A2097, A2098)
        @"iPhone11,4": @"iPhone XS Max", // (model A1921, A2103)
        @"iPhone11,6": @"iPhone XS Max", // (model A2104)
        @"iPhone11,8": @"iPhone XR", // (model A1882, A1719, A2105)
        @"iPhone12,1": @"iPhone 11",
        @"iPhone12,3": @"iPhone 11 Pro",
        @"iPhone12,5": @"iPhone 11 Pro Max",
        @"iPhone13,1": @"iPhone 12 mini",
        @"iPhone13,2": @"iPhone 12",
        @"iPhone13,3": @"iPhone 12 Pro",
        @"iPhone13,4": @"iPhone 12 Pro Max",
        @"iPhone12,8": @"iPhone SE", // (2nd Generation iPhone SE)
        @"iPad4,1": @"iPad Air", // 5th Generation iPad (iPad Air) - Wifi
        @"iPad4,2": @"iPad Air", // 5th Generation iPad (iPad Air) - Cellular
        @"iPad4,3": @"iPad Air", // 5th Generation iPad (iPad Air)
        @"iPad4,4": @"iPad Mini 2", // (2nd Generation iPad Mini - Wifi)
        @"iPad4,5": @"iPad Mini 2", // (2nd Generation iPad Mini - Cellular)
        @"iPad4,6": @"iPad Mini 2", // (2nd Generation iPad Mini)
        @"iPad4,7": @"iPad Mini 3", // (3rd Generation iPad Mini)
        @"iPad4,8": @"iPad Mini 3", // (3rd Generation iPad Mini)
        @"iPad4,9": @"iPad Mini 3", // (3rd Generation iPad Mini)
        @"iPad5,1": @"iPad Mini 4", // (4th Generation iPad Mini)
        @"iPad5,2": @"iPad Mini 4", // (4th Generation iPad Mini)
        @"iPad5,3": @"iPad Air 2", // 6th Generation iPad (iPad Air 2)
        @"iPad5,4": @"iPad Air 2", // 6th Generation iPad (iPad Air 2)
        @"iPad6,3": @"iPad Pro 9.7-inch", // iPad Pro 9.7-inch
        @"iPad6,4": @"iPad Pro 9.7-inch", // iPad Pro 9.7-inch
        @"iPad6,7": @"iPad Pro 12.9-inch", // iPad Pro 12.9-inch
        @"iPad6,8": @"iPad Pro 12.9-inch", // iPad Pro 12.9-inch
        @"iPad6,11": @"iPad (5th generation)", // Apple iPad 9.7 inch (5th generation) - WiFi
        @"iPad6,12": @"iPad (5th generation)", // Apple iPad 9.7 inch (5th generation) - WiFi + cellular
        @"iPad7,1": @"iPad Pro 12.9-inch", // 2nd Generation iPad Pro 12.5-inch - Wifi
        @"iPad7,2": @"iPad Pro 12.9-inch", // 2nd Generation iPad Pro 12.5-inch - Cellular
        @"iPad7,3": @"iPad Pro 10.5-inch", // iPad Pro 10.5-inch - Wifi
        @"iPad7,4": @"iPad Pro 10.5-inch", // iPad Pro 10.5-inch - Cellular
        @"iPad7,5": @"iPad (6th generation)", // iPad (6th generation) - Wifi
        @"iPad7,6": @"iPad (6th generation)", // iPad (6th generation) - Cellular
        @"iPad7,11": @"iPad (7th generation)", // iPad 10.2 inch (7th generation) - Wifi
        @"iPad7,12": @"iPad (7th generation)", // iPad 10.2 inch (7th generation) - Wifi + cellular
        @"iPad8,1": @"iPad Pro 11-inch (3rd generation)", // iPad Pro 11 inch (3rd generation) - Wifi
        @"iPad8,2": @"iPad Pro 11-inch (3rd generation)", // iPad Pro 11 inch (3rd generation) - 1TB - Wifi
        @"iPad8,3": @"iPad Pro 11-inch (3rd generation)", // iPad Pro 11 inch (3rd generation) - Wifi + cellular
        @"iPad8,4": @"iPad Pro 11-inch (3rd generation)", // iPad Pro 11 inch (3rd generation) - 1TB - Wifi + cellular
        @"iPad8,5": @"iPad Pro 12.9-inch (3rd generation)", // iPad Pro 12.9 inch (3rd generation) - Wifi
        @"iPad8,6": @"iPad Pro 12.9-inch (3rd generation)", // iPad Pro 12.9 inch (3rd generation) - 1TB - Wifi
        @"iPad8,7": @"iPad Pro 12.9-inch (3rd generation)", // iPad Pro 12.9 inch (3rd generation) - Wifi + cellular
        @"iPad8,8": @"iPad Pro 12.9-inch (3rd generation)", // iPad Pro 12.9 inch (3rd generation) - 1TB - Wifi + cellular
        @"iPad11,1": @"iPad Mini 5", // (5th Generation iPad Mini)
        @"iPad11,2": @"iPad Mini 5", // (5th Generation iPad Mini)
        @"iPad11,3": @"iPad Air (3rd generation)",
        @"iPad11,4": @"iPad Air (3rd generation)",
        @"AppleTV2,1": @"Apple TV", // Apple TV (2nd Generation)
        @"AppleTV3,1": @"Apple TV", // Apple TV (3rd Generation)
        @"AppleTV3,2": @"Apple TV", // Apple TV (3rd Generation - Rev A)
        @"AppleTV5,3": @"Apple TV", // Apple TV (4th Generation)
        @"AppleTV6,2": @"Apple TV 4K" // Apple TV 4K
    };
}

- (NSString *) getModel {
    NSString* deviceId = [self getDeviceId];
    NSDictionary* deviceNamesByCode = [self getDeviceNamesByCode];
    NSString* deviceName =[deviceNamesByCode valueForKey:deviceId];

    // Return the real device name if we have it
    if (deviceName) {
        return deviceName;
    }

    // If we don't have the real device name, try a generic
    if ([deviceId hasPrefix:@"iPod"]) {
        return @"iPod Touch";
    } else if ([deviceId hasPrefix:@"iPad"]) {
        return @"iPad";
    } else if ([deviceId hasPrefix:@"iPhone"]) {
        return @"iPhone";
    } else if ([deviceId hasPrefix:@"AppleTV"]) {
        return @"Apple TV";
    }

    // If we could not even get a generic, it's unknown
    return @"unknown";
}

- (NSString *) getCarrier {
#if (TARGET_OS_TV || TARGET_OS_MACCATALYST)
    return @"unknown";
#else
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    if (carrier.carrierName != nil) {
        return carrier.carrierName;
    }
    return @"unknown";
#endif
}

- (NSString *) getBuildId {
#if TARGET_OS_TV
    return @"unknown";
#else
    size_t bufferSize = 64;
    NSMutableData *buffer = [[NSMutableData alloc] initWithLength:bufferSize];
    int status = sysctlbyname("kern.osversion", buffer.mutableBytes, &bufferSize, NULL, 0);
    if (status != 0) {
        return @"unknown";
    }
    NSString* buildId = [[NSString alloc] initWithCString:buffer.mutableBytes encoding:NSUTF8StringEncoding];
    return buildId;
#endif
}

- (NSString *) getUniqueId {
    return [DeviceUID uid];
}


- (NSString *) getDeviceId {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* deviceId = [NSString stringWithCString:systemInfo.machine
                                            encoding:NSUTF8StringEncoding];
    if ([deviceId isEqualToString:@"i386"] || [deviceId isEqualToString:@"x86_64"] ) {
        deviceId = [NSString stringWithFormat:@"%s", getenv("SIMULATOR_MODEL_IDENTIFIER")];
    }
    return deviceId;
}


- (BOOL) isEmulator {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* deviceId = [NSString stringWithCString:systemInfo.machine
                                            encoding:NSUTF8StringEncoding];

    if ([deviceId isEqualToString:@"i386"] || [deviceId isEqualToString:@"x86_64"] ) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) isTablet {
    if ([self getDeviceType] == DeviceTypeTablet) {
        return YES;
    } else {
        return NO;
    }
}


- (float) getFontScale {
    // Font scales based on font sizes from https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/
    float fontScale = 1.0;
    UITraitCollection *traitCollection = [[UIScreen mainScreen] traitCollection];

    // Shared application is unavailable in an app extension.
    if (traitCollection) {
        __block NSString *contentSize = nil;
        
        contentSize = traitCollection.preferredContentSizeCategory;

        if ([contentSize isEqual: @"UICTContentSizeCategoryXS"]) fontScale = 0.82;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryS"]) fontScale = 0.88;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryM"]) fontScale = 0.95;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryL"]) fontScale = 1.0;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryXL"]) fontScale = 1.12;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryXXL"]) fontScale = 1.23;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryXXXL"]) fontScale = 1.35;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryAccessibilityM"]) fontScale = 1.64;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryAccessibilityL"]) fontScale = 1.95;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryAccessibilityXL"]) fontScale = 2.35;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryAccessibilityXXL"]) fontScale = 2.76;
        else if ([contentSize isEqual: @"UICTContentSizeCategoryAccessibilityXXXL"]) fontScale = 3.12;
    }

    return fontScale;
}

- (double) getTotalMemory {
    return [NSProcessInfo processInfo].physicalMemory;
}

- (double) getTotalDiskCapacity {
    uint64_t totalSpace = 0;
    NSDictionary *storage = [self getStorageDictionary];

    if (storage) {
        NSNumber *fileSystemSizeInBytes = [storage objectForKey: NSFileSystemSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
    }
    return (double) totalSpace;
}

- (double) getFreeDiskStorage {
    uint64_t freeSpace = 0;
    NSDictionary *storage = [self getStorageDictionary];

    if (storage) {
        NSNumber *freeFileSystemSizeInBytes = [storage objectForKey: NSFileSystemFreeSize];
        freeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    }
    return (double) freeSpace;
}

- (NSString *) getDeviceTypeName {
    return [DeviceTypeValues objectAtIndex: [self getDeviceType]];
}

- (NSArray *) getSupportedAbis {
    /* https://stackoverflow.com/questions/19859388/how-can-i-get-the-ios-device-cpu-architecture-in-runtime */
    const NXArchInfo *info = NXGetLocalArchInfo();
    NSString *typeOfCpu = [NSString stringWithUTF8String:info->description];
    return @[typeOfCpu];
}

- (NSString *) getIpAddress {
    NSString *address = @"0.0.0.0";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                NSString* ifname = [NSString stringWithUTF8String:temp_addr->ifa_name];
                    if(
                        // Check if interface is en0 which is the wifi connection the iPhone
                        // and the ethernet connection on the Apple TV
                        [ifname isEqualToString:@"en0"] ||
                        // Check if interface is en1 which is the wifi connection on the Apple TV
                        [ifname isEqualToString:@"en1"]
                    ) {
                        // Get NSString from C String
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (BOOL) isPinOrFingerprintSet {
#if TARGET_OS_TV
    return NO;
#else
    LAContext *context = [[LAContext alloc] init];
    return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil];
#endif
}

- (void) batteryLevelDidChange:(NSNotification *)notification {
    if (!hasListeners) {
        return;
    }

    float batteryLevel = [self.powerState[@"batteryLevel"] floatValue];
    if ([self.delegate respondsToSelector:@selector(wwDeviceInfoBatteryLevelDidChange:)]) {
        [self.delegate wwDeviceInfoBatteryLevelDidChange:batteryLevel];
    }
    
    if (batteryLevel <= _lowBatteryThreshold) {
            [self.delegate wwDeviceInfoBatteryLevelDidChange:batteryLevel];
    }
}

- (void) powerStateDidChange:(NSNotification *)notification {
    if (!hasListeners) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(wwDeviceInfoPowerStateDidChange:)]) {
        [self.delegate wwDeviceInfoPowerStateDidChange:self.powerState];
    }
}

- (void) headphoneConnectionDidChange:(NSNotification *)notification {
    if (!hasListeners) {
        return;
    }
    BOOL isConnected = [self isHeadphonesConnected];
    if ([self.delegate respondsToSelector:@selector(wwDeviceInfoHeadphoneConnectionDidChange:)]) {
        [self.delegate wwDeviceInfoHeadphoneConnectionDidChange:isConnected];
    }
}


- (NSDictionary *) powerState {
#if RCT_DEV && (!TARGET_IPHONE_SIMULATOR) && !TARGET_OS_TV
    if ([UIDevice currentDevice].isBatteryMonitoringEnabled != true) {
        NSLog(@"Battery monitoring is not enabled. "
                   "You need to enable monitoring with `[UIDevice currentDevice].batteryMonitoringEnabled = TRUE`");
    }
#endif
#if RCT_DEV && TARGET_IPHONE_SIMULATOR && !TARGET_OS_TV
    if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnknown) {
        NSLog(@"Battery state `unknown` and monitoring disabled, this is normal for simulators and tvOS.");
    }
#endif

    return @{
#if TARGET_OS_TV
             @"batteryLevel": @1,
             @"batteryState": @"full",
#else
             @"batteryLevel": @([UIDevice currentDevice].batteryLevel),
             @"batteryState": [@[@"unknown", @"unplugged", @"charging", @"full"] objectAtIndex: [UIDevice currentDevice].batteryState],
             @"lowPowerMode": @([NSProcessInfo processInfo].isLowPowerModeEnabled),
#endif
             };
}

- (float) getBatteryLevel {
    return [self.powerState[@"batteryLevel"] floatValue];
}


- (BOOL) isBatteryCharging {
    return [self.powerState[@"batteryState"] isEqualToString:@"charging"];
}


- (BOOL) isLocationEnabled {
    return [CLLocationManager locationServicesEnabled];
}



- (BOOL) isHeadphonesConnected {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            return YES;
        }
        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            return YES;
        }
        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            return YES;
        }
    }
    return NO;
}

- (unsigned long) getUsedMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if (kerr != KERN_SUCCESS) {
      return -1;
    }

    return (unsigned long)info.resident_size;
}
- (NSDictionary *)constantsToExport {
    return @{
         @"uniqueId": [self getUniqueId],
         @"deviceId": [self getDeviceId],
         @"bundleId": [self getBundleId],
         @"systemName": [self getSystemName],
         @"systemVersion": [self getSystemVersion],
         @"appVersion": [self getAppVersion],
         @"buildNumber": [self getBuildNumber],
         @"isTablet": @([self isTablet]),
         @"appName": [self getAppName],
         @"brand": @"Apple",
         @"model": [self getModel],
         @"deviceType": [self getDeviceTypeName],
         @"carrier": [self getCarrier],
         @"buildId": [self getBuildId],
         @"uniqueId": [self getUniqueId],
         @"deviceId": [self getDeviceId],
         @"isEmulator": @([self isEmulator]),
         @"isTablet": @([self isTablet]),
         @"fontScale": @([self getFontScale]),
         @"totalMemory": @([self getTotalMemory]),
         @"totalDiskCapacity": @([self getTotalDiskCapacity]),
         @"freeDiskStorage": @([self getFreeDiskStorage]),
         @"deviceTypeName": [self getDeviceTypeName],
         @"supportedAbis": [self getSupportedAbis],
         @"ipAddress": [self getIpAddress],
         @"isPinOrFingerprintSet": @([self isPinOrFingerprintSet]),
         @"powerState": [self powerState],
         @"batteryLevel": @([self getBatteryLevel]),
         @"isBatteryCharging": @([self isBatteryCharging]),
         @"isLocationEnabled": @([self isLocationEnabled]),
         @"isHeadphonesConnected": @([self isHeadphonesConnected]),
         @"getUsedMemory": @([self getUsedMemory]),
         @"availableLocationProviders": [self getAvailableLocationProviders]
     };
}
- (NSDictionary *) getAvailableLocationProviders {
#if !TARGET_OS_TV
    return @{
              @"locationServicesEnabled": [NSNumber numberWithBool: [CLLocationManager locationServicesEnabled]],
              @"significantLocationChangeMonitoringAvailable": [NSNumber numberWithBool: [CLLocationManager significantLocationChangeMonitoringAvailable]],
              @"headingAvailable": [NSNumber numberWithBool: [CLLocationManager headingAvailable]],
              @"isRangingAvailable": [NSNumber numberWithBool: [CLLocationManager isRangingAvailable]]
              };
#else
    return @{
              @"locationServicesEnabled": [NSNumber numberWithBool: [CLLocationManager locationServicesEnabled]]
              };
#endif
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
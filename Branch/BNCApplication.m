/**
 @file          BNCApplication.m
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCApplication.h"
#import "BNCLog.h"
#import "BNCKeyChain.h"
#import "BNCSettings.h"

static NSString*const kBranchKeychainService          = @"BranchKeychainService";
static NSString*const kBranchKeychainDevicesKey       = @"BranchKeychainDevices";
static NSString*const kBranchKeychainFirstBuildKey    = @"BranchKeychainFirstBuild";
static NSString*const kBranchKeychainFirstInstalldKey = @"BranchKeychainFirstInstall";

#pragma mark - BNCApplication

@implementation BNCApplication

+ (BNCApplication*) currentApplication {
    static BNCApplication *bnc_currentApplication = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_currentApplication = [BNCApplication createCurrentApplication];
    });
    return bnc_currentApplication;
}

+ (BNCApplication*) createCurrentApplication {
    BNCApplication *application = [[BNCApplication alloc] init];
    if (!application) return application;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;

    application->_bundleID = [NSBundle mainBundle].bundleIdentifier;
    application->_displayName = info[@"CFBundleDisplayName"];
    application->_shortDisplayName = info[@"CFBundleName"];
    application->_teamID = info[@"AppIdentifierPrefix"];
    if ([application->_teamID hasSuffix:@"."]) {
        NSInteger l = application->_teamID.length - 1;
        application->_teamID = [application->_teamID substringToIndex:l];
    }

    application->_displayVersionString = info[@"CFBundleShortVersionString"];
    application->_versionString = info[@"CFBundleVersion"];

    // TODO: Fix these:
    application->_firstInstallBuildDate = nil; // [BNCApplication firstInstallBuildDate];
    application->_currentBuildDate = nil; // [BNCApplication currentBuildDate];

    application->_firstInstallDate = nil; // [BNCApplication firstInstallDate];
    application->_currentInstallDate = nil; // [BNCApplication currentInstallDate];

    application->_updateState = BNCApplicationUpdateStateInstall; // [BNCApplication updateStateForApplication:application];

    application->_extensionType =
        [[NSBundle mainBundle].infoDictionary[@"NSExtension"][@"NSExtensionPointIdentifier"] copy];

    if ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"]) {
        application->_isApplicationExtension = YES;
    }

    NSString*package = info[@"CFBundlePackageType"];
    if ([package isEqualToString:@"APPL"] && !application->_extensionType.length) {
        application->_extensionType = @"application";
        application->_isApplication = YES;
    }

    application->_defaultURLScheme = [self defaultURLScheme];

    return application;
}

+ (NSDate*) currentBuildDate {
    NSURL *appURL = nil;
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    NSString *appName = info[(__bridge NSString*)kCFBundleExecutableKey];
    if (appName.length > 0 && bundleURL) {
        appURL = [bundleURL URLByAppendingPathComponent:appName];
    } else {
        NSString *path = [[NSProcessInfo processInfo].arguments firstObject];
        if (path) appURL = [NSURL fileURLWithPath:path];
    }
    if (appURL == nil)
        return nil;

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:appURL.path error:&error];
    if (error) {
        BNCLogError(@"Can't get build date: %@.", error);
        return nil;
    }
    NSDate * buildDate = [attributes fileCreationDate];
    if (buildDate == nil || [buildDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid build date: %@.", buildDate);
    }
    return buildDate;
}

+ (NSDate*) firstInstallBuildDate {
    NSError *error = nil;
    NSDate *firstBuildDate =
        [BNCKeyChain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstBuildKey
            error:&error];
    if (firstBuildDate)
        return firstBuildDate;

    firstBuildDate = [self currentBuildDate];
    error = [BNCKeyChain storeValue:firstBuildDate
        forService:kBranchKeychainService
        key:kBranchKeychainFirstBuildKey
        cloudAccessGroup:nil];

    return firstBuildDate;
}

+ (NSDate*) currentInstallDate {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL =
        [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:libraryURL.path error:&error];
    if (error) {
        BNCLogError(@"Can't get library date: %@.", error);
        return nil;
    }
    NSDate *installDate = [attributes fileCreationDate];
    if (installDate == nil || [installDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid install date.");
    }
    return installDate;
}

+ (NSDate*) firstInstallDate {
    NSError *error = nil;
    NSDate* firstInstallDate =
        [BNCKeyChain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstInstalldKey
            error:&error];
    if (firstInstallDate)
        return firstInstallDate;

    firstInstallDate = [self currentInstallDate];
    error = [BNCKeyChain storeValue:firstInstallDate
        forService:kBranchKeychainService
        key:kBranchKeychainFirstInstalldKey
        cloudAccessGroup:nil];

    return firstInstallDate;
}

- (NSDictionary*) deviceKeyIdentityValueDictionary {
    @synchronized (self.class) {
        NSError *error = nil;
        NSDictionary *deviceDictionary =
            [BNCKeyChain retrieveValueForService:kBranchKeychainService
                key:kBranchKeychainDevicesKey
                error:&error];
        if (error) BNCLogWarning(@"While retrieving deviceKeyIdentityValueDictionary: %@.", error);
        if (!deviceDictionary) deviceDictionary = @{};
        return deviceDictionary;
    }
}

+ (BNCApplicationUpdateState) updateStateForApplication:(BNCApplication*)application {

    NSTimeInterval first_install_time   = application.firstInstallDate.timeIntervalSince1970;
    NSTimeInterval latest_install_time  = application.currentInstallDate.timeIntervalSince1970;
    NSTimeInterval latest_update_time   = application.currentBuildDate.timeIntervalSince1970;
    NSTimeInterval previous_update_time = application.previousAppBuildDate.timeIntervalSince1970;
    NSTimeInterval const kOneDay        = 1.0 * 24.0 * 60.0 * 60.0;

    BNCApplicationUpdateState update_state = 0;
    if (first_install_time <= 0.0 ||
        latest_install_time <= 0.0 ||
        latest_update_time <= 0.0 ||
        previous_update_time > latest_update_time)
        update_state = BNCApplicationUpdateStateNonUpdate; // Error: Send Non-update.
    else
    if ((latest_update_time - kOneDay) <= first_install_time && previous_update_time <= 0)
        update_state = BNCApplicationUpdateStateInstall;
    else
    if (first_install_time < latest_install_time && previous_update_time <= 0)
        update_state = BNCApplicationUpdateStateUpdate; // Re-install: Send Update.
    else
    if (latest_update_time > first_install_time && previous_update_time < latest_update_time)
        update_state = BNCApplicationUpdateStateUpdate;
    else
        update_state = BNCApplicationUpdateStateNonUpdate;

    return update_state;
}

+ (NSString*) defaultURLScheme {
    NSArray*ignoredURLSchemes = @[
        @"fb",          // Facebook
        @"db",          // DB?
        @"twitterkit-", // Twitter
        @"pdk",         // Pinterest
        @"pin",         // Pinterest
        @"com.googleusercontent.apps",  // Google
    ];
    NSDictionary*info = [NSBundle mainBundle].infoDictionary;
    NSArray *urlTypes = info[@"CFBundleURLTypes"];
    for (NSDictionary *urlType in urlTypes) {
        NSArray *urlSchemes = [urlType objectForKey:@"CFBundleURLSchemes"];
        for (NSString *uriScheme in urlSchemes) {
            for (NSString*ignoredScheme in ignoredURLSchemes) {
                if ([uriScheme hasPrefix:ignoredScheme])
                    continue;
                // Otherwise this must be it!
                return uriScheme;
            }
        }
    }
    return nil;
}

@end

@implementation BNCApplication (BNCTest)

- (void) setAppOriginalInstallDate:(NSDate*)originalInstallDate
        firstInstallDate:(NSDate*)firstInstallDate
        lastUpdateDate:(NSDate*)lastUpdateDate {
    self->_currentInstallDate = firstInstallDate;        // latest_install_time
    self->_firstInstallDate = originalInstallDate;       // first_install_time
    self->_currentBuildDate = lastUpdateDate;            // lastest_update_time
}

@end

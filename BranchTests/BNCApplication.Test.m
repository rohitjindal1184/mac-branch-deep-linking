/**
 @file          BNCApplication.Test.m
 @package       BranchTests
 @brief         Tests for BNCApplication.

 @author        Edward Smith
 @date          January 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCApplication.h"
#import "BNCKeyChain.h"
#import "BranchMainClass.h"
#import "BranchMainClass+Private.h"

@interface BNCApplication (BNCTestCase)
+ (BNCApplication*) createCurrentApplication;
@end

#pragma mark - BNCApplicationTest

@interface BNCApplicationTest : BNCTestCase
@end

@implementation BNCApplicationTest

- (void)testIsApplication {
    XCTAssertTrue([BNCApplication currentApplication].isApplication);
}

- (void)testApplication {
    // Test general info:
    BNCApplication *application = [BNCApplication currentApplication];
    if (!application.isApplication) {
        return;
    }
    NSDictionary*info = [NSBundle mainBundle].infoDictionary;
    XCTAssertEqualObjects(application.bundleID,                     info[@"CFBundleIdentifier"]);
    XCTAssertEqualObjects(application.displayName,                  info[@"CFBundleName"]);
    XCTAssertEqualObjects(application.shortDisplayName,             info[@"CFBundleName"]);
    XCTAssertEqualObjects(application.displayVersionString,         info[@"CFBundleShortVersionString"]);
    XCTAssertEqualObjects(application.versionString,                info[@"CFBundleVersion"]);

    XCTAssert(application.teamID.length > 0);
    XCTAssert(application.extensionType == nil);
    XCTAssert([application.branchExtensionType isEqualToString:@"FULL_APP"]);
    XCTAssert(application.defaultURLScheme.length > 0);
    XCTAssert(application.applicationID.length > 0);
    XCTAssert(application.pushNotificationEnvironment == nil);
    XCTAssert(application.keychainAccessGroups.count > 0);

    #if TARGET_OS_IPHONE
    XCTAssert(application.associatedDomains.count > 0);
    #elif TARGET_OS_OSX
    XCTAssert(application.associatedDomains.count == 0);
    #endif
}

// These are methods are numbered so they run in order:
- (void) testAppUpdate1Basic {
    BNCApplication *application = [BNCApplication currentApplication];
    if (!application.isApplication) {
        return;
    }

    //
    // App dates. Not a great test but tests basic function:
    //

    NSTimeInterval const kOneYearAgo = -365.0 * 24.0 * 60.0 * 60.0;

    XCTAssertTrue(application.firstInstallDate && [application.firstInstallDate timeIntervalSinceNow] > kOneYearAgo);
    XCTAssertTrue(application.firstInstallBuildDate && [application.firstInstallBuildDate timeIntervalSinceNow] > kOneYearAgo);
    XCTAssertTrue(application.currentInstallDate && [application.currentInstallDate timeIntervalSinceNow] > kOneYearAgo);
    XCTAssertTrue(application.currentBuildDate && [application.currentBuildDate timeIntervalSinceNow] > kOneYearAgo);

    NSString*const kBranchKeychainService          = @"BranchKeychainService";
    NSString*const kBranchKeychainFirstBuildKey    = @"BranchKeychainFirstBuild";
    NSString*const kBranchKeychainFirstInstalldKey = @"BranchKeychainFirstInstall";

    NSString*securityGroup = application.applicationID;
    BNCKeyChain*keychain = [[BNCKeyChain alloc] initWithSecurityAccessGroup:securityGroup];

    NSDate * firstBuildDate =
        [keychain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstBuildKey
            error:nil];
    XCTAssertEqualObjects(application.firstInstallBuildDate, firstBuildDate);

    NSDate * firstInstallDate =
        [keychain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstInstalldKey
            error:nil];
    XCTAssertEqualObjects(application.firstInstallDate, firstInstallDate);
}

@end

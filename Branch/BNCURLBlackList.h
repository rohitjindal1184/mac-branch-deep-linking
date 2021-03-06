/**
 @file          BNCURLBlackList.h
 @package       Branch
 @brief         Manages a list of sensitive URLs such as login data that should not be handled by Branch.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
@class Branch;

NS_ASSUME_NONNULL_BEGIN

@interface BNCURLBlackList : NSObject

- (instancetype) initWithBlackList:(NSArray<NSString*>*)blacklist_ version:(NSInteger)version_
    NS_DESIGNATED_INITIALIZER;

/**
 @brief         Checks if a given URL should be ignored (blacklisted).

 @param url     The URL to be checked.
 @return        Returns true if the provided URL should be ignored.
*/
- (BOOL) isBlackListedURL:(NSURL*_Nullable)url;

/**
 @brief         Returns the pattern that matches a URL, if any.

 @param url     The URL to be checked.
 @return        Returns the pattern matching the URL or `nil` if no patterns match.
*/
- (NSString*_Nullable) blackListPatternMatchingURL:(NSURL*_Nullable)url;

/// Refreshes the list of ignored URLs from the server.
- (void) refreshBlackListFromServerWithBranch:(Branch*)branch
    completion:(void (^_Nullable) (BNCURLBlackList*blackList, NSError*_Nullable error))completion;

@property (assign) NSInteger blackListVersion;
@property (strong) NSArray<NSString*>*_Nullable blackList;
@end

NS_ASSUME_NONNULL_END


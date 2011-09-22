//
//  FBFileCacheManager.h
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FBFileCachManager_VERSION   @"1.00"

@class FBCachedFile;
@class FBLockManager;

@interface FBFileCacheManager : NSObject {
 
    NSString* path_;
    NSUInteger size_;        // [MB]
    NSUInteger usingSize_;      // [B]
    
    BOOL includingParameters_;  // default: YES (include URL parameters for the hash key)
    
    NSUInteger hitCounter_;
    NSUInteger fetchCounter_;
    NSUInteger count_;
    
    FBLockManager* lockManager_;
    
    BOOL fileProtectionEnabled_;
}

#pragma mark -
#pragma mark Properties

@property (nonatomic, copy, readonly) NSString* path;
@property (assign, readonly) float cacheHitRate;
@property (assign, readonly) NSUInteger usingSize;
@property (assign, readonly) NSUInteger count;
@property (assign, readonly) NSUInteger size;
@property (assign) BOOL includingParameters;
@property (assign) BOOL fileProtectionEnabled;

// Initializing a New Object
- (id)initWithSize:(NSUInteger)size;
- (id)initWithPath:(NSString*)path size:(NSUInteger)size;

// Cache Management
- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL;
- (FBCachedFile*)putData:(NSData*)contentData forURL:(NSURL*)sourceURL;
- (FBCachedFile*)cachedFileForURL:(NSURL*)sourceURL;
- (void)removeCachedFileForURL:(NSURL*)sourceURL;
- (void)removeAllCachedFiles;
- (void)reload;
- (void)resizeTo:(NSUInteger)size;

// Cache Information
- (void)resetCacheHitRate;

// Etc
+ (NSString*)defaultPath;
+ (NSString*)version;

@end

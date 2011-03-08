//
//  FBFileCacheManager.h
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBCachedFile;

@interface FBFileCacheManager : NSObject {
 
    NSString* path_;
    NSUInteger maxSize_;        // [MB]
    NSUInteger usingSize_;      // [B]
    
    BOOL includingParameters_;  // default: YES (include URL parameters for the hash key)
    
    NSUInteger hitCounter_;
    NSUInteger fetchCounter_;
    NSUInteger count_;
}

#pragma mark -
#pragma mark Properties
@property (nonatomic, copy, readonly) NSString* path;
@property (nonatomic, assign) NSUInteger maxSize;
@property (nonatomic, assign, readonly) NSUInteger usingSize;
@property (nonatomic, assign) BOOL includingParameters;
@property (nonatomic, assign, readonly) NSUInteger count;

// Initializing a New Object
- (id)initWithSize:(NSUInteger)size;
- (id)initWithPath:(NSString*)path size:(NSUInteger)size;

// Cache Management
- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL;
- (FBCachedFile*)putData:(NSData*)contentData forURL:(NSURL*)sourceURL;
- (FBCachedFile*)cachedFileForURL:(NSURL*)sourceURL;


- (void)removeCachedFileForURL:(NSURL*)sourceURL;
- (void)removeAllCachedFiles;

+ (NSString*)defaultPath;

@end

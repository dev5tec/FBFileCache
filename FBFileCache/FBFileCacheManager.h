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
    NSUInteger maxSize_;    // [MB]
    NSUInteger usingSize_;  // [B]
}

#pragma mark -
#pragma mark Properties
@property (nonatomic, copy, readonly) NSString* path;
@property (nonatomic, assign) NSUInteger maxSize;
@property (nonatomic, assign, readonly) NSUInteger usingSize;

// Initializing a New Object
- (id)initWithSize:(NSUInteger)size;
- (id)initWithPath:(NSString*)path size:(NSUInteger)size;

// Cache Management
- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL;
- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL moveFile:(BOOL)moveFile;
- (FBCachedFile*)cachedFileForURL:(NSURL*)sourceURL;

//- (FBCachedFile*)putData:(NSData*)contentData forURL:(NSURL*)sourceURL;

- (void)removeCachedFileForURL:(NSURL*)sourceURL;
- (void)removeAllCachedFiles;

+ (NSString*)defaultPath;

@end

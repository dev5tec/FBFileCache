//
//  FBFileCacheManager.h
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBCachedFile;

@interface FBFileCacheManager : NSObject {
 
    NSString* path_;
    NSUInteger maxSize_;    // [MB]
}

#pragma mark -
#pragma mark Properties
@property (nonatomic, copy, readonly) NSString* path;
@property (nonatomic, assign) NSUInteger maxSize;


// Initializing a New Object
- (id)initWithPath:(NSString*)path size:(NSUInteger)size;
- (id)initWithRelativePath:(NSString*)relativePath size:(NSUInteger)size;

// Cache Management
- (FBCachedFile*)putFile:(NSString*)path forKey:(id)key;
- (FBCachedFile*)putFile:(NSString*)path forKey:(id)key moveFile:(BOOL)moveFile;
- (FBCachedFile*)cachedFileForKey:(id)key;

- (void)removeCachedFileForKey:(id)key;
- (void)removeAllCachedFiles;

// Retriving Cache Information
- (NSUInteger)usingSize;

@end

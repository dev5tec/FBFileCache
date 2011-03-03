//
//  FBFileCacheManager.m
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//

#import "FBFileCacheManager.h"


@implementation FBFileCacheManager

@synthesize path = path_;
@synthesize maxSize = maxSize_;

- (id)initWithPath:(NSString*)path size:(NSUInteger)size
{
    return nil;
}

- (id)initWithRelativePath:(NSString*)relativePath size:(NSUInteger)size
{
    return nil;
}


#pragma mark -
#pragma mark Properties
- (void)setMaxSize:(NSUInteger)size
{
    // not implementated
}

- (FBCachedFile*)putFile:(NSString*)path forKey:(id)key
{
    return nil;
}

- (FBCachedFile*)putFile:(NSString*)path forKey:(id)key moveFile:(BOOL)moveFile
{
    return nil;
}

- (FBCachedFile*)cachedFileForKey:(id)key
{
    return nil;
}

- (void)removeCachedFileForKey:(id)key
{
    
}

- (void)removeAllCachedFiles
{
    
}

- (NSUInteger)usingSize
{
    return -1;
}

@end

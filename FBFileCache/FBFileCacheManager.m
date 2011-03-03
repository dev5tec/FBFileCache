//
//  FBFileCacheManager.m
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>

#import "FBFileCacheManager.h"
#import "FBCachedFile.h"

#define FB_CACHE_PATH   @"_FBFileCache_"

@interface FBFileCacheManager()
@property (nonatomic, copy) NSString* path;
@property (nonatomic, assign) NSUInteger usingSize;
@end


@implementation FBFileCacheManager

@synthesize path = path_;
@synthesize maxSize = maxSize_;
@synthesize usingSize = usingSize_;

#pragma mark -
#pragma mark Private
- (NSString*)_hashStringFromURL:(NSURL*)url
{
    const char *cStr = [[url absoluteString] UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			]; 
}

- (NSUInteger)_calculateUsingSize
{
    // not implementated
    return 0;
}

+ (NSString*)defaultPath
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:FB_CACHE_PATH];
}

- (BOOL)_createDirectoryAtPath:(NSString*)path
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    BOOL result = [fileManager createDirectoryAtPath:path
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&error];
    if (!result) {
        NSLog(@"[ERROR] %@", error);
    }
    return result;
}

- (NSString*)_cachedFilePathForURL:(NSURL*)sourceURL
{
    NSString* filename = [[self _hashStringFromURL:sourceURL]
                          stringByAppendingPathExtension:[sourceURL pathExtension]];
    return [self.path stringByAppendingPathComponent:filename];
}


#pragma mark -
#pragma mark Initialization and Deallocation

- (id)initWithPath:(NSString*)path size:(NSUInteger)size
{
    self = [super init];
    BOOL result = [self _createDirectoryAtPath:path];
    if (self && result) {
        self.path = path;
        self.maxSize = size;
        self.usingSize = [self _calculateUsingSize];

    }
    return self;
}

- (id)initWithSize:(NSUInteger)size
{
    return [self initWithPath:[[self class] defaultPath]
                         size:size];
}


#pragma mark -
#pragma mark Properties

- (void)setMaxSize:(NSUInteger)size
{
    // not implementated
    maxSize_ = size;
}

- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL
{
    return [self putFile:contentFilePath forURL:sourceURL moveFile:NO];
}

- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL moveFile:(BOOL)moveFile
{
    // TODO: checking contentFilePath is a file not a directory

    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;

    if ([fileManager fileExistsAtPath:cachedFilePath]) {
        if (![fileManager removeItemAtPath:cachedFilePath error:&error]) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
            return nil;
        }
    }
    
    if (moveFile) {
        [fileManager moveItemAtPath:contentFilePath
                             toPath:cachedFilePath
                              error:&error];
    } else {
        [fileManager copyItemAtPath:contentFilePath
                             toPath:cachedFilePath
                              error:&error];
    }

    if (error) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        return nil;
    }

    FBCachedFile* cachedFile = 
        [[[FBCachedFile alloc] initWithFile:cachedFilePath] autorelease];

    
    // TODO: update information

    return cachedFile;
}

- (FBCachedFile*)cachedFileForURL:(NSURL*)sourceURL
{
    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];

    NSFileManager* fileManager = [NSFileManager defaultManager];
    FBCachedFile* cachedFile = nil;

    if ([fileManager fileExistsAtPath:cachedFilePath]) {
        cachedFile = [[[FBCachedFile alloc] initWithFile:cachedFilePath] autorelease];
    }
    return cachedFile;
}

- (void)removeCachedFileForURL:(NSURL*)sourceURL
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;

    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];
    if ([fileManager fileExistsAtPath:cachedFilePath]) {
        if (![fileManager removeItemAtPath:cachedFilePath error:&error]) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        }
    }
    
    // TODO: update information
}

- (void)removeAllCachedFiles
{    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    if ([fileManager fileExistsAtPath:self.path]) {
        if (![fileManager removeItemAtPath:self.path error:&error]) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        }
    }
    [self _createDirectoryAtPath:self.path];
    
    // TODO: update information
}



@end

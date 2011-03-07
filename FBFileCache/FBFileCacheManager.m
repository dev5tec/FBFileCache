//
//  FBFileCacheManager.m
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
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

- (BOOL)_createDirectoryAtPath:(NSString*)path
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    BOOL result = [fileManager createDirectoryAtPath:path
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&error];
    if (!result) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
    }
    return result;
}

- (NSString*)_cachedFilePathForURL:(NSURL*)sourceURL
{
    NSString* filename = [[self _hashStringFromURL:sourceURL]
                          stringByAppendingPathExtension:[sourceURL pathExtension]];
    return [self.path stringByAppendingPathComponent:filename];
}

- (NSUInteger)_calculateUsingSize
{
    // TODO: recursive
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSUInteger totalSize = 0;
    
    NSError* error = nil;
    NSArray* files = [fileManager contentsOfDirectoryAtPath:self.path error:&error];
    if (error) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        return 0;
    }
    for (NSString* file in files) {
        error =nil;
        NSDictionary* attributes =
        [fileManager attributesOfItemAtPath:[self.path stringByAppendingPathComponent:file]
                                      error:&error];
        if (error) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        } else {
            totalSize += [[attributes objectForKey:NSFileSize] unsignedIntegerValue];
        }
    }
    return totalSize;
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
    // TODO: not implementated
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

    NSDictionary* attributes = [fileManager attributesOfItemAtPath:cachedFilePath error:&error];
    self.usingSize += [[attributes objectForKey:NSFileSize] unsignedIntegerValue];

    return cachedFile;
}

- (FBCachedFile*)putData:(NSData*)contentData forURL:(NSURL*)sourceURL
{
    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];
    NSError* error = nil;
    [contentData writeToFile:cachedFilePath
                     options:NSDataWritingAtomic
                       error:&error];
    if (error) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        return nil;        
    }
    FBCachedFile* cachedFile = 
        [[[FBCachedFile alloc] initWithFile:cachedFilePath] autorelease];
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
        NSDictionary* attributes =
            [fileManager attributesOfItemAtPath:cachedFilePath error:&error];
        self.usingSize -= [[attributes objectForKey:NSFileSize] unsignedIntegerValue];

        if (![fileManager removeItemAtPath:cachedFilePath error:&error]) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        }
    }
    
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
    self.usingSize = 0;
}

+ (NSString*)defaultPath
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:FB_CACHE_PATH];
}



@end

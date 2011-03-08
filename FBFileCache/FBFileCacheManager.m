//
//  FBFileCacheManager.m
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fts.h>

#import "FBFileCacheManager.h"
#import "FBCachedFile.h"

#define FB_CACHE_PATH   @"_FBFileCache_"

#define FB_MEGA_BYTE    (1024 * 1024)

@interface FBFileCacheManager()
@property (nonatomic, copy) NSString* path;
@property (nonatomic, assign) NSUInteger usingSize;
@end


@implementation FBFileCacheManager

@synthesize path = path_;
@synthesize maxSize = maxSize_;
@synthesize usingSize = usingSize_;
@synthesize includingParameters = includingParameters_;

#pragma mark -
#pragma mark Private
- (NSString*)_hashStringFromURL:(NSURL*)url
{
    NSString* urlString = [url absoluteString];
    const char *cStr = [urlString UTF8String];

    if (!self.includingParameters) {
        NSRange range = [urlString rangeOfString:@"?"];
        if (range.location != NSNotFound) {
            cStr = [[urlString substringToIndex:range.location] UTF8String];
        }
    }

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
    NSUInteger usingSize = 0;
    
    FTS* fts;
    FTSENT* entry;
    
    // fts_open(char* const*, ...)
    const char* paths[] = { [self.path UTF8String], NULL };

    fts = fts_open(paths, 0, NULL);
    while ((entry = fts_read(fts))) {
        if (entry->fts_info & FTS_F) {
            usingSize += entry->fts_statp->st_size;
        }
    }
    fts_close(fts);

    return usingSize;
}

int _compareWithLastAccessTime(const FTSENT **a, const FTSENT **b)
{
    __darwin_time_t atime1 = (*a)->fts_statp->st_atimespec.tv_sec;
    __darwin_time_t atime2 = (*b)->fts_statp->st_atimespec.tv_sec;
    
    if (atime1 < atime2) {
        return -1;
    } else if (atime1 > atime2) {
        return 1;
    } else {
        return 0;   // equals
    }
}

- (BOOL)_makeSpaceForSize:(NSUInteger)fileSize
{
    NSUInteger maxByteSize = self.maxSize * FB_MEGA_BYTE;
    if (maxByteSize < fileSize) {
        return NO;  // no enough space
    }
    
    NSUInteger spaceSize = maxByteSize - self.usingSize;
    if (fileSize <= spaceSize) {
        return YES; // enough space
    }

    NSUInteger targetSize = maxByteSize - fileSize;

    BOOL result = YES;
    FTS* fts;
    FTSENT* entry;
   
    // fts_open(char* const*, ...)
    const char* paths[] = { [self.path UTF8String], NULL };
    
    fts = fts_open(paths, 0, _compareWithLastAccessTime);
    while ((entry = fts_read(fts))) {
        if (entry->fts_info & FTS_F) {
//            NSLog(@"#### %u", entry->fts_statp->st_size);
            
            if (unlink(entry->fts_path)) {
                NSLog(@"%s|[ERROR] failed to remove %@", __PRETTY_FUNCTION__, entry->fts_path);
                result = NO;
                break;
            }
            usingSize_ -= entry->fts_statp->st_size;
            if (usingSize_ <= targetSize) {
                break;  // enough space
            }
        }
    }
    fts_close(fts);

    return result;
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
        self.includingParameters = YES;
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
    if (size < maxSize_) {
        [self _makeSpaceForSize:(maxSize_-size)*FB_MEGA_BYTE];
    }
    maxSize_ = size;
}

- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL
{
    // TODO: checking contentFilePath is a file not a directory

    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;

    // [1] make space for putting the file
    NSDictionary* attributes = [fileManager attributesOfItemAtPath:contentFilePath error:&error];
    NSUInteger fileSize = [[attributes objectForKey:NSFileSize] unsignedIntegerValue];

    if (![self _makeSpaceForSize:fileSize]) {
        NSLog(@"%s|[ERROR] There is not enough space for %@ [%u]", __PRETTY_FUNCTION__, sourceURL, fileSize);
        return nil;
    }

    // [2] remove old file to overwrite
    if ([fileManager fileExistsAtPath:cachedFilePath]) {
        if (![fileManager removeItemAtPath:cachedFilePath error:&error]) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
            return nil;
        }
    }

    // [3] copy the file to cahced file
    if (![fileManager copyItemAtPath:contentFilePath
                              toPath:cachedFilePath
                               error:&error]) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        return nil;
    }

    
    // [4] after follow
    self.usingSize += fileSize;
    return [FBCachedFile cachedFile:cachedFilePath];
    
}

- (FBCachedFile*)putData:(NSData*)contentData forURL:(NSURL*)sourceURL
{
    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];
    NSError* error = nil;
    
    // [1] make space for putting the file
    NSUInteger fileSize = [contentData length];
    if (![self _makeSpaceForSize:fileSize]) {
        NSLog(@"%s|[ERROR] There is not enough space for %@ [%u]", __PRETTY_FUNCTION__, sourceURL, fileSize);
        return nil;
    }

    // [2] write data
    ;
    if (![contentData writeToFile:cachedFilePath
                          options:NSDataWritingAtomic
                            error:&error]) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        return nil;        
    }
    
    // [3] after follow
    self.usingSize += fileSize;
    return [FBCachedFile cachedFile:cachedFilePath];

}


- (FBCachedFile*)cachedFileForURL:(NSURL*)sourceURL
{
    FBCachedFile* cachedFile =
        [FBCachedFile cachedFile:[self _cachedFilePathForURL:sourceURL]];
//    [cachedFile updateAccessTime];
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
// TODO
        // must be positive value !
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

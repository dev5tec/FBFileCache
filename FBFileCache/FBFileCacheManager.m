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
#import "FBLockManager.h"

#define FB_CACHE_PATH   @"_FBFileCache_"

#define FB_MEGA_BYTE    (1024 * 1024)

@interface FBFileCacheManager()
@property (nonatomic, copy) NSString* path;
@property (assign) NSUInteger fetchedCounter;
@property (assign) NSUInteger hitCounter;

@property (assign) NSUInteger usingSize;
@property (assign) NSUInteger count;

@property (nonatomic, retain) FBLockManager* lockManager;

@end


@implementation FBFileCacheManager

@synthesize path = path_;
@synthesize size = size_;
@synthesize usingSize = usingSize_;
@synthesize includingParameters = includingParameters_;
@synthesize count = count_;
@synthesize fetchedCounter = fetchCounter_;
@synthesize hitCounter = hitCounter_;

@synthesize lockManager = lockManager_;

@synthesize fileProtectionEnabled = fileProtectionEnabled_;

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
    NSUInteger maxByteSize = self.size * FB_MEGA_BYTE;
    if (maxByteSize < fileSize) {
        return NO;  // no enough space
    }
    
    NSUInteger spaceSize = maxByteSize - self.usingSize;
    if (fileSize <= spaceSize) {
        return YES; // enough space
    }
    BOOL result = YES;
    FTS* fts;
    FTSENT* entry;
    const char* paths[] = { [self.path UTF8String], NULL };
    
    NSUInteger decreaseOfSize = 0;
    
    fts = fts_open((char* const*)paths, 0, _compareWithLastAccessTime);
    while ((entry = fts_read(fts))) {
        if (entry->fts_info & FTS_F) {
//            NSLog(@"#### %s, %u", entry->fts_path, entry->fts_statp->st_size); // DEBUG
            
            if (unlink(entry->fts_path)) {
                NSLog(@"%s|[ERROR] failed to remove %@",
                      __PRETTY_FUNCTION__, entry->fts_path);
                result = NO;
                break;
            } else {
                self.count--;
            }
            decreaseOfSize += entry->fts_statp->st_size;
            if (fileSize <= (decreaseOfSize + spaceSize)) {
                break;  // enough space
            }   
        }
    }
    fts_close(fts);

    self.usingSize -= decreaseOfSize;

    return result;
}


- (FBCachedFile*)_putForResourceURL:(NSURL*)sourceURL size:(NSUInteger)fileSize block:(BOOL(^)(NSString* cachedFilePath))block
{
    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;

    // make space
    if (![self _makeSpaceForSize:fileSize]) {
        NSLog(@"%s|[ERROR] There is not enough space for %@ [%ubytes / maxsize:%u]",
              __PRETTY_FUNCTION__, sourceURL, fileSize, self.size);
        return nil;
    }

    // remove old file to overwrite
    BOOL fileExisted = [fileManager fileExistsAtPath:cachedFilePath];
    if (fileExisted) {
        if (![fileManager removeItemAtPath:cachedFilePath error:&error]) {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
            return nil;
        }
    }
    
    // do action
    if (block(cachedFilePath)) {
        self.usingSize += fileSize;
        if (!fileExisted) {
            self.count++;
        }
        FBCachedFile* cachedFile = [FBCachedFile cachedFile:cachedFilePath];
        return cachedFile;
    } else {
        return nil;
    }
}


#pragma mark -
#pragma mark Initialization and Deallocation

- (id)initWithPath:(NSString*)path size:(NSUInteger)size
{
    self = [super init];
    BOOL result = [self _createDirectoryAtPath:path];
    if (self && result) {
        self.path = path;
        [self resizeTo:size];
        self.includingParameters = YES;
        self.fileProtectionEnabled = NO;
        [self reload];
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

- (void)resizeTo:(NSUInteger)size
{
    if (size < size_) {

        [self.lockManager lock];
        //
        // start critical secion (whole) -->
        //
        [self _makeSpaceForSize:(size_-size)*FB_MEGA_BYTE];
        //
        // <-- critical secion (whole)
        //
        [self.lockManager unlock];

    }
    size_ = size;
}

- (FBCachedFile*)putFile:(NSString*)contentFilePath forURL:(NSURL*)sourceURL
{
    struct stat fileStat;
    if (stat([contentFilePath UTF8String], &fileStat) == -1) {
        if (errno == ENOENT) {
            NSLog(@"%s|[WARN] The file does not exist ('%@')",
                  __PRETTY_FUNCTION__, contentFilePath);
        } else {
            NSLog(@"%s|[ERROR] stat error ('%@')",
                  __PRETTY_FUNCTION__, contentFilePath);
        }
        return nil;        
    }
    
    if(fileStat.st_mode & S_IFDIR) {
        NSLog(@"%s|[WARN] contentFilePath must be file ('%@' is a directory).",
              __PRETTY_FUNCTION__, contentFilePath);
        return nil;
    }


    [self.lockManager lockForURL:sourceURL];
    //
    // start critical section -->
    //
    
    FBCachedFile* cachedFile =
        [self _putForResourceURL:sourceURL size:fileStat.st_size
        block:^BOOL(NSString* cachedFilePath) {
            NSFileManager* fileManager = [NSFileManager defaultManager];
            NSError* error = nil;
            if (![fileManager copyItemAtPath:contentFilePath
                                     toPath:cachedFilePath
                                      error:&error]) {
                NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
                return NO;
            }
            if (self.fileProtectionEnabled) {
                NSDictionary* attributes =
                    [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                forKey:NSFileProtectionKey];
                if (![fileManager setAttributes:attributes
                                  ofItemAtPath:cachedFilePath
                                         error:&error]) {
                    NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
                    return NO;
                }
            }
            return YES;
        }];
    
    //
    // <-- end critical section
    //
    [self.lockManager unlockForURL:(NSURL*)sourceURL];

    return cachedFile;    
}

- (FBCachedFile*)putData:(NSData*)contentData forURL:(NSURL*)sourceURL
{
    [self.lockManager lockForURL:sourceURL];
    //
    // start critical section -->
    //

    NSUInteger fileSize = [contentData length];    
    FBCachedFile* cachedFile = [self _putForResourceURL:sourceURL size:fileSize
          block:^BOOL(NSString* cachedFilePath) {
              // [3] copy the file to cahced file
              NSError* error = nil;
              if ([contentData writeToFile:cachedFilePath
                                   options:NSDataWritingAtomic | (self.fileProtectionEnabled?NSDataWritingFileProtectionComplete:NSDataWritingFileProtectionNone)
                                     error:&error]) {
                  return YES;
              } else {
                  NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
                  return NO;
              }            
          }];
    
    //
    // <-- end critical section
    //
    [self.lockManager unlockForURL:(NSURL*)sourceURL];

    return cachedFile;
}


- (FBCachedFile*)cachedFileForURL:(NSURL*)sourceURL
{
    FBCachedFile* cachedFile =
        [FBCachedFile cachedFile:[self _cachedFilePathForURL:sourceURL]];
    self.fetchedCounter++;
    if (cachedFile) {
        self.hitCounter++;
    }
    return cachedFile;
}

//
// <<locking>>
// mutex: [sourceURL absoluteString]  **not sourceURL only
//
- (void)removeCachedFileForURL:(NSURL*)sourceURL
{
    [self.lockManager lockForURL:sourceURL];
    //
    // start critical section -->
    //

    NSString* cachedFilePath = [self _cachedFilePathForURL:sourceURL];

    struct stat fileStat;
    if (stat([cachedFilePath UTF8String], &fileStat) == -1) {
        NSLog(@"%s|[ERROR] failed to get stat for %@",
              __PRETTY_FUNCTION__, cachedFilePath);
    } else {
        NSUInteger removingFileSize = fileStat.st_size;
        if (self.usingSize >= removingFileSize) {
            self.usingSize -= removingFileSize;
        } else {
            self.usingSize = 0;
            NSLog(@"%s|[ERROR] usingSize is wrong ?", __PRETTY_FUNCTION__);
        }

        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSError* error = nil;
        if ([fileManager removeItemAtPath:cachedFilePath error:&error]) {
            self.count--;
        } else {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        }
    }
 
    //
    // <-- end critical section
    //
    [self.lockManager unlockForURL:(NSURL*)sourceURL];
}

- (void)removeAllCachedFiles
{    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    if ([fileManager fileExistsAtPath:self.path]) {
        
        [self.lockManager lock];
        //
        // start critical secion (whole) -->
        //
        
        if ([fileManager removeItemAtPath:self.path error:&error]) {
            [self _createDirectoryAtPath:self.path];
            self.usingSize = 0;
            self.count = 0;
        } else {
            NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        }
        //
        // <-- end critical section (whole)
        //
        [self.lockManager unlock];
    }
}

+ (NSString*)defaultPath
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:FB_CACHE_PATH];
}

- (float)cacheHitRate
{
    if (self.fetchedCounter) {
        return (float)self.hitCounter/(float)self.fetchedCounter;
    } else {
        return 0.0f;
    }
}

- (void)resetCacheHitRate
{
    self.hitCounter = 0;
    self.fetchedCounter = 0;
}

- (void)reload
{
    FTS* fts;
    FTSENT* entry;

    NSUInteger usingSize = 0;
    NSUInteger count = 0;

    const char* const paths[] = { [self.path UTF8String], NULL };

    @synchronized (self) {
        fts = fts_open((char* const*)paths, 0, NULL);
        while ((entry = fts_read(fts))) {
            if (entry->fts_info & FTS_F) {
                usingSize += entry->fts_statp->st_size;
                count++;
            }
        }
        fts_close(fts);
        
        self.usingSize = usingSize;
        self.count = count;
    }
}

+ (NSString*)version
{
    return FBFileCachManager_VERSION;
}

@end

//
//  FBFileCacheManagerTestCase.m
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//

#import "FBFileCacheManagerTestCase.h"
#import "FBCachedFile.h"
#import "FBFileCacheManager.h"

#define TEST_IMAGE_NUM  10
#define TEST_TEMPORARY_DIRECTORY @"_FBFileCacheTests_Temporary_"
#define TEST_CACHE_DIRECTORY @"_FBFileCacheTests_Cache_"

@implementation FBFileCacheManagerTestCase

@synthesize temporaryPath = temporaryPath_;
@synthesize baseURL = baseURL_;

#pragma mark -
#pragma mark Utilities

- (NSString*)temporaryPath
{
    if (temporaryPath_ == nil) {
        NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        temporaryPath_ = [[path stringByAppendingPathComponent:TEST_TEMPORARY_DIRECTORY] retain];
    }
    return temporaryPath_;
}

- (void)removeTemporary
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    if ([fileManager fileExistsAtPath:self.temporaryPath]) {
        [fileManager removeItemAtPath:self.temporaryPath error:&error];
        if (error) {
            NSLog(@"[ERROR] %@", error);
        }
    }
}

- (void)setupTemporary
{
    [self removeTemporary];

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    NSLog(@"[INFO] Setup Temporary directory...");
    [fileManager createDirectoryAtPath:self.temporaryPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    if (error) {
        NSLog(@"[ERROR] %@", error);
    }
    
    NSLog(@"[INFO] Copying images to Temporary directory...");
    NSString* originalPath = [[NSBundle bundleForClass:[self class]] resourcePath];
    error = nil;
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        [fileManager copyItemAtPath:[originalPath stringByAppendingPathComponent:filename]
                             toPath:[self.temporaryPath stringByAppendingPathComponent:filename]
                              error:&error];
        if (error) {
            NSLog(@"[ERROR] %@", error);
        }
    }

}

- (NSString*)cachePath
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:TEST_CACHE_DIRECTORY];
}

- (BOOL)compareFile:(NSString*)path1 withFile:(NSString*)path2
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    NSDictionary* attrs1 = [fileManager attributesOfItemAtPath:path1 error:&error];
    NSDictionary* attrs2 = [fileManager attributesOfItemAtPath:path2 error:&error];
    
    if ([attrs1 objectForKey:NSFileSize] == [attrs2 objectForKey:NSFileSize]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)fileExistsPath:(NSString*)path
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}


#pragma mark -
#pragma mark Pre-Post functions
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    self.baseURL = [NSURL URLWithString:@"https://www.hoge.hoge.com/some/where/"];
}

- (void)tearDown
{
    // Tear-down code here.
    [self removeTemporary];
    
    self.temporaryPath = nil;
    self.baseURL = nil;
    
    [super tearDown];
}



#pragma mark -
#pragma mark Test cases

- (void)testInitWithPath_size
{
    FBFileCacheManager* manager = [[FBFileCacheManager alloc] initWithPath:[self cachePath] size:100];
    STAssertEqualObjects(manager.path, [self cachePath], nil);
    STAssertEquals((NSUInteger)manager.maxSize, (NSUInteger)100, nil);    
}

- (void)testInitWithRelativePath_size
{
    FBFileCacheManager* manager = [[FBFileCacheManager alloc] initWithRelativePath:@"test" size:100];
    STAssertEqualObjects(manager.path, [[self cachePath] stringByAppendingPathComponent:@"test"], nil);
    STAssertEquals((NSUInteger)manager.maxSize, (NSUInteger)100, nil);    

}

- (void)testPutFile_forKey
{
    [self setupTemporary];

    FBFileCacheManager* manager = [[FBFileCacheManager alloc]
                                   initWithPath:[self cachePath] size:100];
    NSString* filename = nil;
    NSURL* url = nil;
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [manager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forKey:url];
    }
    
    // test
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [manager cachedFileForKey:url];

        NSString* cachedFilePath = [manager.path stringByAppendingPathComponent:filename];
        STAssertEqualObjects(cachedFile.path, cachedFilePath, nil);

        NSURL* cachedFileURL = [NSURL URLWithString:cachedFilePath];
        STAssertEqualObjects(cachedFile.URL, cachedFileURL, nil);
        
        NSString* temporaryPath = [self.temporaryPath stringByAppendingPathComponent:filename];
        STAssertTrue([self compareFile:temporaryPath
                              withFile:cachedFilePath], @"%@", temporaryPath);
    }
    
}

- (void)testPutFile_forKey_moveFile
{
    [self setupTemporary];

    FBFileCacheManager* manager = [[FBFileCacheManager alloc]
                                   initWithPath:[self cachePath] size:100];
    NSString* filename = nil;
    NSURL* url = nil;
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [manager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forKey:url];
    }
    
    // test
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [manager cachedFileForKey:url];
        
        NSString* cachedFilePath = [manager.path stringByAppendingPathComponent:filename];
        STAssertEqualObjects(cachedFile.path, cachedFilePath, nil);
        
        NSURL* cachedFileURL = [NSURL URLWithString:cachedFilePath];
        STAssertEqualObjects(cachedFile.URL, cachedFileURL, nil);
        
        NSString* temporaryPath = [self.temporaryPath stringByAppendingPathComponent:filename];
        STAssertTrue(![self fileExistsPath:temporaryPath], @"%@", temporaryPath);

        NSString* originalPath = [[NSBundle bundleForClass:[self class]] resourcePath];
        STAssertTrue([self compareFile:[originalPath stringByAppendingPathComponent:filename]
                              withFile:cachedFilePath], @"%@", originalPath);
    }
}

- (void)testRemoveCachedFileForKey
{
    [self setupTemporary];
    
    FBFileCacheManager* manager = [[FBFileCacheManager alloc]
                                   initWithPath:[self cachePath] size:100];
    NSString* filename = nil;
    int i;
    NSURL* url = nil;
    
    // (1) put image files to cache
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [manager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forKey:url];
    }

    // (2) remove some image files when the file number is odd
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        if ((i % 2) == 0) {
            filename = [NSString stringWithFormat:@"image-%02d.png", i];
            url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
            [manager removeCachedFileForKey:url];            
        }
    }

    // (3) check to exist or not
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        if ((i % 2) == 0) {
            STAssertTrue(![self fileExistsPath:[url path]], @"%@", [url path]);
        } else {
            STAssertTrue([self fileExistsPath:[url path]], @"%@", [url path]);
        }
    }
}

- (void)testRemoveAllCachedFiles
{
    [self setupTemporary];
    
    FBFileCacheManager* manager = [[FBFileCacheManager alloc]
                                   initWithPath:[self cachePath] size:100];
    NSString* filename = nil;
    int i;
    NSURL* url = nil;
    
    // (1) put image files to cache
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [manager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forKey:url];
    }
    
    // (2) remove some image files when the file number is odd
    [manager removeAllCachedFiles]; 
    
    // (3) check to exist or not
    NSError* error = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* files = [fileManager contentsOfDirectoryAtPath:[self cachePath]
                                                      error:&error];
    NSLog(@"files: %@", files);
    if (error) {
        NSLog(@"[ERROR] %@", error);
    }
    STAssertNotNil(files, nil);
    STAssertTrue([files count] == 0, @"%@", files);
}


// Retriving Cache Information
- (void)testUsingSize
{
    NSLog(@"%@", [self cachePath]);
}



@end

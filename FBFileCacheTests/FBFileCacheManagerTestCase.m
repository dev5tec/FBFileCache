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
#define TEST_IMAGE_TOTAL_NUM  20
#define TEST_TEMPORARY_DIRECTORY @"_FBFileCacheTests_Temporary_"
#define TEST_CACHE_DIRECTORY @"_FBFileCacheTests_Cache_"

@implementation FBFileCacheManagerTestCase

@synthesize fileCacheManager = fileCacheManager_;
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

- (NSString*)cachePath
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [path stringByAppendingPathComponent:TEST_CACHE_DIRECTORY];
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
    for (i=0; i < TEST_IMAGE_TOTAL_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        [fileManager copyItemAtPath:[originalPath stringByAppendingPathComponent:filename]
                             toPath:[self.temporaryPath stringByAppendingPathComponent:filename]
                              error:&error];
        if (error) {
            NSLog(@"[ERROR] %@", error);
        }
    }
}

- (void)putAllTestFilesWithManager:(FBFileCacheManager*)fileCacheManager
{
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [fileCacheManager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forKey:url];
    }   
}

// overwrite old cache files (image-00..09.png) by (image-10..11.png)
- (void)putAllTestFiles2WithManager:(FBFileCacheManager*)fileCacheManager
{
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSString* filename2 = [NSString stringWithFormat:@"image-%02d.png", i+10];
        NSURL* url = [NSURL URLWithString:filename2 relativeToURL:self.baseURL];
        [fileCacheManager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forKey:url];
    }   
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

- (NSUInteger)usingSize
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    NSArray* files = [fileManager contentsOfDirectoryAtPath:[self cachePath] error:&error];
    
    NSUInteger usingSize = 0;
    for (NSString* file in files) {
        NSLog(@"file=%@", file);
        NSDictionary* attributes = [fileManager attributesOfItemAtPath:file error:&error];
        NSNumber* size = [attributes objectForKey:NSFileSize];
        usingSize += [size unsignedIntegerValue];
    }
    return usingSize;
}


#pragma mark -
#pragma mark Pre-Post functions
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    self.baseURL = [NSURL URLWithString:@"https://www.hoge.hoge.com/some/where/"];
    self.fileCacheManager = [[[FBFileCacheManager alloc]
                              initWithPath:[self cachePath] size:100] autorelease];
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

//
// Initialize
//
- (void)testInit
{    
    STAssertEqualObjects(self.fileCacheManager.path, [self cachePath], nil);
    STAssertEquals((NSUInteger)self.fileCacheManager.maxSize, (NSUInteger)100, nil);    
}

- (void)testInitWithRelativePath
{

    FBFileCacheManager* manager = [[FBFileCacheManager alloc]
                                   initWithRelativePath:@"test" size:100];
    STAssertEqualObjects(manager, [[self cachePath] stringByAppendingPathComponent:@"test"], nil);
    STAssertEquals((NSUInteger)manager.maxSize, (NSUInteger)100, nil);    

}

- (void)testInitWhenResume
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    
    FBFileCacheManager* manager2 = [[FBFileCacheManager alloc]
                                    initWithPath:[self cachePath] size:100];
    [self putAllTestFilesWithManager:manager2];
    
    STAssertEquals(self.fileCacheManager.usingSize, [self usingSize], nil);
}


//
// put
//
- (void)testPutAtFirst
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];

    NSString* filename = nil;
    NSURL* url = nil;
    int i;
    
    // test
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForKey:url];

        NSString* cachedFilePath = [self.fileCacheManager.path stringByAppendingPathComponent:filename];
        STAssertEqualObjects(cachedFile.path, cachedFilePath, nil);

        NSURL* cachedFileURL = [NSURL URLWithString:cachedFilePath];
        STAssertEqualObjects(cachedFile.URL, cachedFileURL, nil);
        
        NSString* temporaryPath = [self.temporaryPath stringByAppendingPathComponent:filename];
        STAssertTrue([self compareFile:temporaryPath
                              withFile:cachedFilePath], @"%@", temporaryPath);
    }
    
}

- (void)testPutWithMoveFile
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];

    NSString* filename = nil;
    NSURL* url = nil;
    int i;
    
    // test
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForKey:url];
        
        NSString* cachedFilePath = [self.fileCacheManager.path stringByAppendingPathComponent:filename];
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

- (void)testPutByUpdating
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    [self putAllTestFiles2WithManager:self.fileCacheManager];

    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSString* filename2 = [NSString stringWithFormat:@"image-%02d.png", i+10];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForKey:url];

        NSString* originalPath = [[NSBundle bundleForClass:[self class]] resourcePath];
        STAssertTrue([self compareFile:[originalPath stringByAppendingPathComponent:filename2]
                              withFile:cachedFile.path], @"%@", originalPath);
    }
}

//
// remove
//
- (void)testRemove
{
    [self setupTemporary];
    
    NSString* filename = nil;
    int i;
    NSURL* url = nil;
    
    // (1) put image files to cache
    [self putAllTestFilesWithManager:self.fileCacheManager];

    // (2) remove some image files when the file number is odd
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        if ((i % 2) == 0) {
            filename = [NSString stringWithFormat:@"image-%02d.png", i];
            url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
            [self.fileCacheManager removeCachedFileForKey:url];            
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

- (void)testRemoveAll
{
    [self setupTemporary];
    
    // (1) put image files to cache
    [self putAllTestFilesWithManager:self.fileCacheManager];
    
    // (2) remove some image files when the file number is odd
    [self.fileCacheManager removeAllCachedFiles]; 
    
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


//
// properties
//
- (void)testUsingSize
{
    // setup files
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    
    STAssertEquals(self.fileCacheManager.usingSize, [self usingSize], nil);
}


@end

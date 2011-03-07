//
//  FBFileCacheManagerTestCase.m
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
//

#import "FBFileCacheManagerTestCase.h"
#import "FBCachedFile.h"
#import "FBFileCacheManager.h"

#define TEST_IMAGE_NUM  10
#define TEST_IMAGE_TOTAL_NUM  20
#define TEST_TEMPORARY_DIRECTORY @"_FBFileCacheTests_Temporary_"
#define TEST_CACHE_DIRECTORY @"_FBFileCacheTests_Cache_"
#define TEST_CACHE_URL @"https://www.hoge.hoge.com/some/where/"
#define TEST_DUMMY_URL @"https://www.dummy.dummy.com/some/where"

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

- (void)removeAtPath:(NSString*)path
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"[ERROR] %@", error);
        }
    }
}

- (void)removeAllDirectories
{
    [self removeAtPath:self.temporaryPath];
    [self removeAtPath:[self cachePath]];
    [self removeAtPath:[FBFileCacheManager defaultPath]];
}

- (void)setupTemporary
{
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

- (void)putAllTestFilesWithManager:(FBFileCacheManager*)fileCacheManager moveFile:(BOOL)moveFile
{
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [fileCacheManager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forURL:url moveFile:moveFile];
    }   
    
}

- (void)putAllTestFilesWithManager:(FBFileCacheManager*)fileCacheManager
{
    [self putAllTestFilesWithManager:fileCacheManager moveFile:NO];
}

// overwrite old cache files (image-00..09.png) by (image-10..11.png)
- (void)putAllTestFiles2WithManager:(FBFileCacheManager*)fileCacheManager
{
    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSString* filename2 = [NSString stringWithFormat:@"image-%02d.png", i+10];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [fileCacheManager putFile:[self.temporaryPath stringByAppendingPathComponent:filename2] forURL:url];
    }   
}


- (BOOL)compareFile:(NSString*)path1 withFile:(NSString*)path2
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error1 = nil;
    NSError* error2 = nil;
    NSDictionary* attrs1 = [fileManager attributesOfItemAtPath:path1 error:&error1];
    if (error1) {
        NSLog(@"[ERROR] %@", error1);
    }
    NSDictionary* attrs2 = [fileManager attributesOfItemAtPath:path2 error:&error2];
    if (error2) {
        NSLog(@"[ERROR] %@", error2);
    }
    if ([[attrs1 objectForKey:NSFileSize] unsignedIntegerValue]
        == [[attrs2 objectForKey:NSFileSize] unsignedIntegerValue]) {
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
        NSDictionary* attributes = [fileManager attributesOfItemAtPath:[[self cachePath] stringByAppendingPathComponent:file] error:&error];
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
    [self removeAllDirectories];
    self.baseURL = [NSURL URLWithString:TEST_CACHE_URL];
    self.fileCacheManager = [[[FBFileCacheManager alloc]
                              initWithPath:[self cachePath] size:100] autorelease];

}

- (void)tearDown
{
    // Tear-down code here.
    [self removeAllDirectories];
    
    self.temporaryPath = nil;
    self.baseURL = nil;
    
    [super tearDown];
}



#pragma mark -
#pragma mark Test cases

//
// Initialize
//
- (void)testInitWithPathSize
{
    STAssertEqualObjects(self.fileCacheManager.path, [self cachePath], nil);
    STAssertEquals((NSUInteger)self.fileCacheManager.maxSize, (NSUInteger)100, nil);    
}

- (void)testInitWithSize
{
    self.fileCacheManager = [[FBFileCacheManager alloc] initWithSize:100];

    STAssertEqualObjects(self.fileCacheManager.path, [FBFileCacheManager defaultPath], nil);
    STAssertEquals((NSUInteger)self.fileCacheManager.maxSize, (NSUInteger)100, nil);        
}

- (void)testInitWhenResume
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    
    FBFileCacheManager* manager2 = [[FBFileCacheManager alloc]
                                    initWithPath:[self cachePath] size:100];
    STAssertEquals(manager2.usingSize, [self usingSize], nil);
}


//
// put
//
- (void)testPutAndGetAtFirst
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
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];

        NSString* temporaryPath = [self.temporaryPath stringByAppendingPathComponent:filename];
        STAssertTrue([self compareFile:temporaryPath
                              withFile:cachedFile.path], @"%@", temporaryPath);
    }
}

- (void)testPutAndGetWithMoveFile
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager moveFile:YES];

    NSString* filename = nil;
    NSURL* url = nil;
    int i;
    
    // test
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];

        NSString* temporaryPath = [self.temporaryPath stringByAppendingPathComponent:filename];
        STAssertTrue(![self fileExistsPath:temporaryPath], @"%@", temporaryPath);

        NSString* originalPath = [[NSBundle bundleForClass:[self class]] resourcePath];
        STAssertTrue([self compareFile:[originalPath stringByAppendingPathComponent:filename]
                              withFile:cachedFile.path], @"%@", originalPath);
    }
}

- (void)testPutAndGetByUpdating
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    [self putAllTestFiles2WithManager:self.fileCacheManager];

    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSString* filename2 = [NSString stringWithFormat:@"image-%02d.png", i+10];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];

        NSString* originalPath = [[NSBundle bundleForClass:[self class]] resourcePath];
        STAssertTrue([self compareFile:[originalPath stringByAppendingPathComponent:filename2]
                              withFile:cachedFile.path], @"%@", originalPath);
/*
        NSLog(@"[1] %@", cachedFile.path);
        NSLog(@"[2] %@", [originalPath stringByAppendingPathComponent:filename2]);
*/
    }
}

// at first and update
- (void)testPutDataAndGetData
{
    NSURL* url = [NSURL URLWithString:@"test.file"
                        relativeToURL:[NSURL URLWithString:TEST_CACHE_URL]];

    // 1st
    NSString* filePath = [[NSBundle bundleForClass:[self class]]
                           pathForResource:@"sample" ofType:@"jpg"];
    NSData* data1 = [NSData dataWithContentsOfFile:filePath];
    [self.fileCacheManager putData:data1 forURL:url];

    FBCachedFile* cachedFile1 = [self.fileCacheManager cachedFileForURL:url];
    STAssertEqualObjects(cachedFile1.data, data1, nil);

    // 2nd (update)
    NSString* filePath2 = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"image-00" ofType:@"png"];
    NSData* data2 = [NSData dataWithContentsOfFile:filePath2];
    [self.fileCacheManager putData:data2 forURL:url];

    FBCachedFile* cachedFile2 = [self.fileCacheManager cachedFileForURL:url];
    STAssertEqualObjects(cachedFile2.data, data2, nil);
}




- (void)testGetNull
{
    NSURL* url = [NSURL URLWithString:TEST_DUMMY_URL];
    FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
    STAssertNil(cachedFile, nil);
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
            [self.fileCacheManager removeCachedFileForURL:url];            
        }
    }

    // (3) check to exist or not
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        filename = [NSString stringWithFormat:@"image-%02d.png", i];
        url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        if ((i % 2) == 0) {
            STAssertTrue(![self fileExistsPath:cachedFile.path], @"%@", cachedFile.path);
        } else {
            STAssertTrue([self fileExistsPath:cachedFile.path], @"%@", cachedFile.path);
        }
    }

    // (4) check size after removing
    STAssertEquals(self.fileCacheManager.usingSize, [self usingSize], nil);
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
    if (error) {
        NSLog(@"[ERROR] %@", error);
    }
    STAssertNotNil(files, nil);
    STAssertTrue([files count] == 0, @"%@", files);
    STAssertTrue(self.fileCacheManager.usingSize == 0, @"%@", files);
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

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

// 1024*1024 = 1MB
#define TEST_LIMIT_SIZE  (1024*1024)
#define TEST_LIMIT_URL  @"https://www.limitation.com/limit/"
#define TEST_LIMIT_MAX  6


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

- (void)createTemporary
{
    NSLog(@"[INFO] Setup Temporary directory...");
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;

    [fileManager createDirectoryAtPath:self.temporaryPath
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:&error];
    if (error) {
        NSLog(@"[ERROR] %@", error);
    }
}
- (void)setupTemporary
{
    NSLog(@"[INFO] Copying images to Temporary directory...");

    [self createTemporary];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
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
        [fileCacheManager putFile:[self.temporaryPath stringByAppendingPathComponent:filename] forURL:url];
    }   
    STAssertEquals(fileCacheManager.count, (NSUInteger)TEST_IMAGE_NUM, nil);
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

static char* buff[TEST_LIMIT_SIZE*TEST_LIMIT_MAX];
- (void)createLimitData
{
    [self createTemporary];
    int i; 
    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSString* filePath = [self.temporaryPath stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"DAT-%d", i]];
        
        NSData* data = [NSData dataWithBytes:buff length:TEST_LIMIT_SIZE*i];
        [data writeToFile:filePath atomically:NO];
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
    STAssertEquals((NSUInteger)self.fileCacheManager.size, (NSUInteger)100, nil);    
}

- (void)testInitWithSize
{
    self.fileCacheManager = [[FBFileCacheManager alloc] initWithSize:100];

    STAssertEqualObjects(self.fileCacheManager.path, [FBFileCacheManager defaultPath], nil);
    STAssertEquals((NSUInteger)self.fileCacheManager.size, (NSUInteger)100, nil);        
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

- (void)testPutAndGetByUpdating
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    [self putAllTestFiles2WithManager:self.fileCacheManager];
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)TEST_IMAGE_NUM, nil);

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
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)1, nil);

    // 2nd (update)
    NSString* filePath2 = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"image-00" ofType:@"png"];
    NSData* data2 = [NSData dataWithContentsOfFile:filePath2];
    [self.fileCacheManager putData:data2 forURL:url];

    FBCachedFile* cachedFile2 = [self.fileCacheManager cachedFileForURL:url];
    STAssertEqualObjects(cachedFile2.data, data2, nil);
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)1, nil);
}

- (void)testPutAndGetWithIncludingParameters1
{
    // case1: includingParameters == NO
    self.fileCacheManager.includingParameters = NO;
    NSURL* url11 = [NSURL URLWithString:@"https://www.test.com/test1/action"];
    NSURL* url12 = [NSURL URLWithString:@"https://www.test.com/test1/action?a=1&b=2"];
    NSString* filePath11 = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"image-01" ofType:@"png"];
    NSData* data11 = [NSData dataWithContentsOfFile:filePath11];
    NSString* filePath12 = [[NSBundle bundleForClass:[self class]]
                           pathForResource:@"image-02" ofType:@"png"];
    NSData* data12 = [NSData dataWithContentsOfFile:filePath12];

    FBCachedFile* cachedFile11 = [self.fileCacheManager putData:data11 forURL:url11];
    FBCachedFile* cachedFile12 = [self.fileCacheManager putData:data12 forURL:url12];
    
    STAssertEqualObjects(cachedFile11.data, data12, nil); // over written
    STAssertEqualObjects(cachedFile12.data, data12, nil);
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)1, nil);
}

- (void)testPutAndGetWithIncludingParameters2
{
    // case2: includingParameters == YES;
    self.fileCacheManager.includingParameters = YES;

    NSURL* url21 = [NSURL URLWithString:@"https://www.test.com/test2/action"];
    NSURL* url22 = [NSURL URLWithString:@"https://www.test.com/test2/action?a=1&b=2"];
    NSString* filePath21 = [[NSBundle bundleForClass:[self class]]
                            pathForResource:@"image-03" ofType:@"png"];
    NSData* data21 = [NSData dataWithContentsOfFile:filePath21];
    NSString* filePath22 = [[NSBundle bundleForClass:[self class]]
                            pathForResource:@"image-04" ofType:@"png"];
    NSData* data22 = [NSData dataWithContentsOfFile:filePath22];
    
    FBCachedFile* cachedFile21 = [self.fileCacheManager putData:data21 forURL:url21];
    FBCachedFile* cachedFile22 = [self.fileCacheManager putData:data22 forURL:url22];
    
    STAssertEqualObjects(cachedFile21.data, data21, nil); // not over written
    STAssertEqualObjects(cachedFile22.data, data22, nil);
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)2, nil);
}

- (void)testLargeSize
{
    [self.fileCacheManager resizeTo:1];
    NSData* data = [NSData dataWithBytes:buff length:TEST_LIMIT_SIZE*2];
    NSURL* url = [NSURL URLWithString:TEST_CACHE_URL];
    FBCachedFile* cachedFile = [self.fileCacheManager putData:data forURL:url];
    STAssertNil(cachedFile, nil);
}


- (void)testGetNull
{
    NSURL* url = [NSURL URLWithString:TEST_DUMMY_URL];
    FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
    STAssertNil(cachedFile, nil);
}

- (void)testFileExtension
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];

    int i;
    for (i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        
        NSString* originalPath = [[NSBundle bundleForClass:[self class]] resourcePath];
        
        STAssertEqualObjects([cachedFile.path pathExtension],
                             [[originalPath stringByAppendingPathComponent:filename] pathExtension], nil);
    }
}


// limit test (1) does not over limit
- (void)testLimit1
{
    [self createLimitData];
    
    NSURL* baseURL = [NSURL URLWithString:TEST_LIMIT_URL];
    NSUInteger maxSize = 21;    // 21MB
    NSUInteger usingSize = 0;
    [self.fileCacheManager resizeTo:maxSize];
    
    int i;
    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSString* filePath = [[self temporaryPath] stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"DAT-%d", i]];
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        [self.fileCacheManager putFile:filePath forURL:url];
    }
    
    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        STAssertNotNil(cachedFile, [url description]);
        usingSize += TEST_LIMIT_SIZE*i;
    }
    STAssertEquals(self.fileCacheManager.usingSize, usingSize, nil);
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)TEST_LIMIT_MAX, nil);
}

// limit test (2) over limit and change max size
//
// file    file  total  (2a)   (2b)   (2c)   (2d_
// name    size  size   15MB   10MB   20MB access2,put 1
// [DAT-1] 1MB    1MB    x      x      x      o
// [DAT-2] 2MB    3MB    x      x      o      o
// [DAT-3] 3MB    6MB    x      x      o      x
// [DAT-4] 4MB   10MB    o      x      o      o
// [DAT-5] 5MB   15MB    o      x      o      o
// [DAT-6] 6MB   21MB    o      o      o      o

- (void)testLimit2
{
    [self createLimitData];

    NSURL* baseURL = [NSURL URLWithString:TEST_LIMIT_URL];
    NSUInteger maxSize = 15;    // 15MB
    NSUInteger totalSize = 0;
    NSUInteger usingSize = 0;
    NSUInteger count = 0;
    [self.fileCacheManager resizeTo:maxSize];

    // (2a) new files remain and old files are removed
    int i;
    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSString* filePath = [[self temporaryPath] stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"DAT-%d", i]];
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        [self.fileCacheManager putFile:filePath forURL:url];
        [NSThread sleepForTimeInterval:1.5];    // delay for atime
    }
    for (i=TEST_LIMIT_MAX; i > 0; i--) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        totalSize += i;
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        if (totalSize <= maxSize) {
            STAssertNotNil(cachedFile, [url description]);
            usingSize += TEST_LIMIT_SIZE*i;
            count++;
        } else {
            STAssertNil(cachedFile, [url description]);
        }
    }
    STAssertEquals(self.fileCacheManager.usingSize, usingSize, nil);
    STAssertEquals(self.fileCacheManager.count, count, nil);

    // adjust atime order
    /*
    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        [self.fileCacheManager cachedFileForURL:url];
        [NSThread sleepForTimeInterval:1.5];
    }
     */

    // (2b) change max size (be less)
    maxSize = 10;      // 10MB
    totalSize = 0;
    usingSize = 0;
    count = 0;
    [self.fileCacheManager resizeTo:maxSize];


    for (i=TEST_LIMIT_MAX; i > 0; i--) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        totalSize += i;
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        if (totalSize <= maxSize) {
            STAssertNotNil(cachedFile, [url description]);
            usingSize += TEST_LIMIT_SIZE*i;
            count++;
        } else {
            STAssertNil(cachedFile, [url description]);
        }
    }
    STAssertEquals(self.fileCacheManager.usingSize, usingSize, nil);
    STAssertEquals(self.fileCacheManager.count, count, nil);

    // (2c) change max size (be more)

    maxSize = 20;      // 20MB
    totalSize = 0;
    usingSize = 0;
    count = 0;
    [self.fileCacheManager resizeTo:maxSize];

    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSString* filePath = [[self temporaryPath] stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"DAT-%d", i]];
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];

        [self.fileCacheManager putFile:filePath forURL:url];
        [NSThread sleepForTimeInterval:1.5];    // delay for atime
    }
    for (i=TEST_LIMIT_MAX; i > 0; i--) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        totalSize += i;
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        if (totalSize <= maxSize) {
            STAssertNotNil(cachedFile, [url description]);
            usingSize += TEST_LIMIT_SIZE*i;
            count++;
        } else {
            STAssertNil(cachedFile, nil);
        }
    }
    STAssertEquals(self.fileCacheManager.usingSize, usingSize, nil);
    STAssertEquals(self.fileCacheManager.count, count, nil);

    // (2d) validate atime sorting
    count = 0;
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", 2]
                        relativeToURL:baseURL];
    FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
    [cachedFile data];  // update atime (read file)

    NSString* filePath = [[self temporaryPath] stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"DAT-%d", 1]];
    url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", 1]
                        relativeToURL:baseURL];
    [self.fileCacheManager putFile:filePath forURL:url];

    for (i=1; i <= TEST_LIMIT_MAX; i++) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"DAT-%d", i]
                            relativeToURL:baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        if (i == 3) {
            STAssertNil(cachedFile, [url description]);
        } else {
            STAssertNotNil(cachedFile, [url description]);
            count++;
        }
    }
    STAssertEquals(self.fileCacheManager.count, count, nil);
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
    STAssertEquals(self.fileCacheManager.count, (NSUInteger)(TEST_IMAGE_NUM/2), nil);
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
    STAssertEquals([files count], (NSUInteger)0, @"%@", files);
    STAssertTrue(self.fileCacheManager.usingSize == 0, @"%@", files);
    STAssertEquals(self.fileCacheManager.count,(NSUInteger)0, nil);
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

- (void)testCacheHitRate
{
    STAssertEquals(self.fileCacheManager.cacheHitRate, 0.0f, nil);

    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    
    int i;
    for (i=0; i < TEST_IMAGE_NUM*2; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        [self.fileCacheManager cachedFileForURL:url];
    }
    STAssertEquals(self.fileCacheManager.cacheHitRate, 0.5f, nil);

    [self.fileCacheManager resetCacheHitRate];
    STAssertEquals(self.fileCacheManager.cacheHitRate, 0.0f, nil);
}

- (void)testFileProtectionEnabled
{
    // setup files
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    
    for (int i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        NSError* error = nil;
        NSDictionary* attributes = [[NSFileManager defaultManager]
                                    attributesOfItemAtPath:cachedFile.path
                                    error:&error];
        NSLog(@"%@", attributes);
        STAssertEquals([attributes objectForKey:NSFileProtectionKey], NSFileProtectionNone, nil);
    }

    self.fileCacheManager.fileProtectionEnabled = YES;
    [self putAllTestFilesWithManager:self.fileCacheManager];

    for (int i=0; i < TEST_IMAGE_NUM; i++) {
        NSString* filename = [NSString stringWithFormat:@"image-%02d.png", i];
        NSURL* url = [NSURL URLWithString:filename relativeToURL:self.baseURL];
        FBCachedFile* cachedFile = [self.fileCacheManager cachedFileForURL:url];
        NSError* error = nil;
        NSDictionary* attributes = [[NSFileManager defaultManager]
                                    attributesOfItemAtPath:cachedFile.path
                                    error:&error];
        STAssertEquals([attributes objectForKey:NSFileProtectionKey], NSFileProtectionComplete, nil);
    }
}



//
// test reload
//
- (void)testReload
{
    [self setupTemporary];
    [self putAllTestFilesWithManager:self.fileCacheManager];
    NSUInteger usingSize = self.fileCacheManager.usingSize;
    NSUInteger count = self.fileCacheManager.count;

    [self.fileCacheManager reload];
    
    STAssertEquals(self.fileCacheManager.usingSize, usingSize, nil);
    STAssertEquals(self.fileCacheManager.count, count, nil);
}

@end

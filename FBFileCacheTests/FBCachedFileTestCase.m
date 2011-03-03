//
//  FBCachedFileTestCase.m
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//

#import "FBCachedFileTestCase.h"

#import "FBCachedFile.h"

@implementation FBCachedFileTestCase


#pragma mark -
#pragma mark Pre-Post functions
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}


#pragma mark -
#pragma mark Utilities

- (NSString*)samplePath
{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"sample" ofType:@"jpg"];
    return path;
}

- (NSURL*)sampleURL
{
    NSURL* url = [NSURL fileURLWithPath:[self samplePath]];
    return url;
}
- (FBCachedFile*)sampleCachedFile
{
    FBCachedFile* cachedFile = [[[FBCachedFile alloc] initWithFile:[self sampleURL]] autorelease];
    return cachedFile;
}

- (NSDictionary*)attributesOfSample
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;

    return [fileManager attributesOfItemAtPath:[self samplePath] error:&error];
}

#pragma mark -
#pragma mark Test cases
- (void)testPath
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    STAssertEqualObjects(cachedFile.path, [self samplePath], @".path does not mache.");
}

- (void)testURL
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    STAssertEqualObjects(cachedFile.URL, [self sampleURL], @".URL does not mache.");
}

- (void)testCreationDate
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    NSDictionary* attributes = [self attributesOfSample];
    NSDate* creationDate = [attributes objectForKey:NSFileCreationDate];
    STAssertEqualObjects(cachedFile.creationDate, creationDate, @".creationDate does not mache.");
    
}

- (void)testTimeIntervalSinceNow {

    FBCachedFile* cachedFile = [self sampleCachedFile];
    NSDictionary* attributes = [self attributesOfSample];
    NSDate* creationDate = [attributes objectForKey:NSFileCreationDate];
    STAssertEquals((NSInteger)cachedFile.timeIntervalSinceNow,
                   (NSInteger)[creationDate timeIntervalSinceNow],
                   @".timeIntervalSinceNow does not mache.");
    
}



@end

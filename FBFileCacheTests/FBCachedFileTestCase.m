//
//  FBCachedFileTestCase.m
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
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
    FBCachedFile* cachedFile = [[[FBCachedFile alloc] initWithFile:[self samplePath]] autorelease];
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
- (void)testProperty_Path
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    STAssertEqualObjects(cachedFile.path, [self samplePath], @".path does not mache.");
}

- (void)testProperty_URL
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    STAssertEqualObjects(cachedFile.URL, [self sampleURL], @".URL does not mache.");
}

- (void)testProperty_CreationDate
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    NSDictionary* attributes = [self attributesOfSample];
    NSDate* creationDate = [attributes objectForKey:NSFileCreationDate];
    STAssertEqualObjects(cachedFile.creationDate, creationDate, @".creationDate does not mache.");
    
}

- (void)testProperty_TimeIntervalSinceNow {

    FBCachedFile* cachedFile = [self sampleCachedFile];
    NSDictionary* attributes = [self attributesOfSample];
    NSDate* creationDate = [attributes objectForKey:NSFileCreationDate];
    STAssertEquals((NSInteger)cachedFile.timeIntervalSinceNow,
                   (NSInteger)[creationDate timeIntervalSinceNow],
                   @".timeIntervalSinceNow does not mache.");
    
}

- (void)testPropery_Data
{
    FBCachedFile* cachedFile = [self sampleCachedFile];
    NSData* data = [NSData dataWithContentsOfFile:cachedFile.path];
    STAssertEqualObjects(cachedFile.data, data, nil);
}

@end

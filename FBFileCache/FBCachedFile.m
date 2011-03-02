//
//  FBCachedFile.m
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//

#import "FBCachedFile.h"

@interface FBCachedFile()
@property (nonatomic, retain) NSURL* URL;
@end

@implementation FBCachedFile

@synthesize URL = url_;

#pragma mark -
#pragma mark Initialization and deallocation

- (id)initWithFile:(NSURL*)URL
{
    self = [super init];
    if (self) {
        self.URL = URL;
    }
    return self;
}

- (void)dealloc {
    self.URL = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Properties
- (NSString*)path
{
    return [self.URL path];
}

- (NSURL*)URL
{
    return url_;
}

- (NSDate*)creationDate
{
    NSError* error = nil;
    NSDictionary* attributes = [[NSFileManager defaultManager]
                                attributesOfItemAtPath:self.path error:&error];
    return [attributes objectForKey:NSFileCreationDate];
}

- (NSTimeInterval)timeIntervalSinceNow
{
    return [self.creationDate timeIntervalSinceNow];
}

@end

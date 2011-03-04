//
//  FBCachedFile.m
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
//

#import "FBCachedFile.h"

@interface FBCachedFile()
@property (nonatomic, retain) NSURL* URL;
@end

@implementation FBCachedFile

@synthesize URL = url_;

#pragma mark -
#pragma mark Initialization and deallocation

- (id)initWithFile:(NSString*)filePath
{
    self = [super init];
    if (self) {
        self.URL = [NSURL fileURLWithPath:filePath];
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
    if (error) {
        NSLog(@"%s|[ERROR] %@", __PRETTY_FUNCTION__, error);
        return nil;
    }
    return [attributes objectForKey:NSFileCreationDate];
}

- (NSTimeInterval)timeIntervalSinceNow
{
    return [self.creationDate timeIntervalSinceNow];
}

@end

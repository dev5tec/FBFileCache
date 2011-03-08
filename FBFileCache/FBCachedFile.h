//
//  FBCachedFile.h
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/03/02.
//  Copyright 2011 Five-technology Co.,Ltd.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBCachedFile : NSObject {
    
    NSURL* url_;
}

@property (readonly) NSString* path;
@property (nonatomic, retain, readonly) NSURL* URL;
@property (readonly) NSDate* creationDate;
@property (readonly) NSTimeInterval timeIntervalSinceNow;
@property (readonly) NSData* data;

// API
+ (FBCachedFile*)cachedFile:(NSString*)filePath;
- (void)updateAccessTime;
@end

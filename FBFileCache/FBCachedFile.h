//
//  FBCachedFile.h
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBCachedFile : NSObject {
    
    NSURL* url_;
}

@property (readonly) NSString* path;
@property (nonatomic, retain, readonly) NSURL* URL;
@property (readonly) NSDate* creationDate;
@property (readonly) NSTimeInterval timeIntervalSinceNow;

- (id)initWithFile:(NSString*)filePath;
//- (NSData*)data;

@end

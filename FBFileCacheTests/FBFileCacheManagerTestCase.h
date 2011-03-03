//
//  FBFileCacheManagerTestCase.h
//  FBFileCache
//
//  Created by 橋口 湖 on 11/03/02.
//  Copyright 2011 ファイブテクノロジー株式会社. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import <UIKit/UIKit.h>
//#import "application_headers" as required

@class FBFileCacheManager;
@interface FBFileCacheManagerTestCase : SenTestCase {
    
    FBFileCacheManager* fileCacheManager_;

    NSString* temporaryPath_;
    NSURL* baseURL_;
}

@property (nonatomic, retain) FBFileCacheManager* fileCacheManager;
@property (nonatomic, copy) NSString* temporaryPath;
@property (nonatomic, retain) NSURL* baseURL;

@end

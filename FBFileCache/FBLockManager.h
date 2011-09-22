//
//  FBLockManager.h
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/04/13.
//

#import <Foundation/Foundation.h>


@interface FBLockManager : NSObject {

    NSMutableDictionary* lockMap_;
    NSLock* wholeLock_;
    
    NSMutableSet* lockPool_;
    NSMutableSet* usingLockPool_;
}

- (void)lockForKey:(NSString*)key;
- (void)unlockForKey:(NSString*)key;
- (void)lockForURL:(NSURL*)url;
- (void)unlockForURL:(NSURL*)url;

// whole locking
- (void)lock;
- (void)unlock;

@end

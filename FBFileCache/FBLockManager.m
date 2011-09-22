//
//  FBLockManager.m
//  FBFileCache
//
//  Created by Hiroshi Hashiguchi on 11/04/13.
//

#import "FBLockManager.h"

@interface FBLockManager ()
@property (nonatomic, retain) NSMutableDictionary* lockMap;
@property (nonatomic, retain) NSLock* wholeLock;
@property (nonatomic, retain) NSMutableSet* lockPool;
@property (nonatomic, retain) NSMutableSet* usingLockPool;
@end

#define INITIAL_LOCK_NUMBER     5


@implementation FBLockManager

@synthesize lockMap = lockMap_;
@synthesize wholeLock = wholeLock_;
@synthesize lockPool = lockPool_;
@synthesize usingLockPool = usingLockPool_;

#pragma mark -
#pragma mark Initialization and deallocation

- (id)init {
    self = [super init];
    if (self) {
        self.lockMap = [NSMutableDictionary dictionary];
        NSLock* lock;
        
        lock = [[NSLock alloc] init];
        self.wholeLock = lock;
        [lock release];
        
        self.lockPool = [NSMutableSet setWithCapacity:INITIAL_LOCK_NUMBER];
        self.usingLockPool = [NSMutableSet setWithCapacity:INITIAL_LOCK_NUMBER];
        int i;
        for (i=0; i < INITIAL_LOCK_NUMBER; i++) {
            lock = [[NSLock alloc] init];
            [self.lockPool addObject:lock];
            [lock release];
        }
    }
    return self;
}

- (void)dealloc {
    self.lockMap = nil;
    self.wholeLock = nil;
    self.lockPool = nil;
    self.usingLockPool = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Manage lock pool (thread no-safe)

- (NSLock*)_getLockFromPool
{
    NSLock* lock = [self.lockPool anyObject];
    if (lock) {
        [self.lockPool removeObject:lock];
    } else {
        lock = [[[NSLock alloc] init] autorelease];
    }
    [self.usingLockPool addObject:lock];

    return lock;
}

- (void)_releaseToPoolWithLock:(NSLock*)lock
{
    if ([lock tryLock]) {
        [lock unlock];
    }
    [self.usingLockPool removeObject:lock];
    [self.lockPool addObject:lock];
}


#pragma mark -
#pragma mark API

- (void)lockForKey:(NSString*)key
{
    // implemetation of shared lock
    [self.wholeLock lock];
    [self.wholeLock unlock];

    
    NSLock* currentLock = nil;

    @synchronized (self) {

        currentLock = [self.lockMap objectForKey:key];
        if (currentLock == nil) {
            currentLock = [self _getLockFromPool];
            [self.lockMap setObject:currentLock forKey:key];
        }
    }

    [currentLock lock];
}

- (void)unlockForKey:(NSString*)key
{
    @synchronized (self) {

        NSLock* currentLock = [self.lockMap objectForKey:key];
        if (currentLock) {
            [currentLock unlock];
            [self.lockMap removeObjectForKey:key];
            [self _releaseToPoolWithLock:currentLock];
        }
    }
}

- (void)lockForURL:(NSURL*)url
{
    [self lockForKey:[url absoluteString]];
}

- (void)unlockForURL:(NSURL*)url
{
    [self unlockForKey:[url absoluteString]];    
}


- (void)lock
{
    [self.wholeLock lock];
}

- (void)unlock
{
    [self.wholeLock unlock];
}

@end

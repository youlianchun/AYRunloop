//
//  NCRunloop.m
//  NCRunloop
//
//  Created by YLCHUN on 2017/2/14.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "NCRunloop.h"

@interface NCRunloop ()
@property (nonatomic, retain) NSThread *thread;
@property (nonatomic) CFRunLoopRef runLoop;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL runing;
@end

@interface _NCRunloop : NSObject
@property (nonatomic, weak)NCRunloop *runLoop;
@end
@implementation _NCRunloop
@end

static NSMutableDictionary *kRunLoopDict = nil;
NSMutableDictionary* runLoopDict(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (kRunLoopDict == nil) {
            kRunLoopDict = [NSMutableDictionary dictionary];
        }
    });
    return kRunLoopDict;
}

void weakRunLoop(NCRunloop *runloop, BOOL isWeak) {
    NSString *key = [NSString stringWithFormat:@"%p", runloop.runLoop];
    if (isWeak) {
        _NCRunloop *_runloop = [[_NCRunloop alloc] init];
        _runloop.runLoop = runloop;
        runLoopDict()[key] = _runloop;
    }else{
        runLoopDict()[key] = nil;
    }
}


NCRunloop *runLoop() {
    NSString *key = [NSString stringWithFormat:@"%p", CFRunLoopGetCurrent()];
    _NCRunloop *_runloop = runLoopDict()[key];
    NCRunloop * runLoop = _runloop.runLoop;
    if (!runLoop) {
        runLoop = [[NCRunloop alloc] init];
    }
    return runLoop;
}


@implementation NCRunloop

-(void)run {
    if (self.runing) {
        return;
    }
    self.runing = YES;
    self.thread = [NSThread currentThread];
    if (self.time > 0) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:self.time target:self selector:@selector(timerOut) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
    
    weakRunLoop(self,YES);
    self.runLoop = CFRunLoopGetCurrent();
    // Add custom mode
    CFRunLoopAddCommonMode(self.runLoop, (__bridge CFStringRef)(@"CustomRunLoopMode"));
    while (!self.isCancelled) {
        BOOL ret = [[NSRunLoop currentRunLoop] runMode:@"CustomRunLoopMode"  beforeDate:[NSDate distantFuture]];
        if (!ret) {
            NSLog(@"停止失败");
        }else{
            self.runing = YES;
        }
    }
}

- (void)timerOut {
    [self stop];
}

-(void)stop {
    self.isCancelled = YES;
    if (self.thread) {
        weakRunLoop(self,NO);
        CFRunLoopStop(self.runLoop);
        [self.thread cancel];
    }
}

+(NCRunloop*)currentRunloop {
    NSThread *thread = [NSThread currentThread];
    if ([thread isMainThread]) {
        return nil;
    }
    return runLoop();
}

@end

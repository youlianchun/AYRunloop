//
//  AYRunloop.m
//  AYRunloop
//
//  Created by YLCHUN on 2017/2/14.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import "AYRunloop.h"

@interface AYRunloop ()
@property (nonatomic, retain) NSThread *thread;
@property (nonatomic) CFRunLoopRef runLoop;
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL runing;
@end

@interface _AYRunloop : NSObject
@property (nonatomic, weak)AYRunloop *runLoop;
@end
@implementation _AYRunloop
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

void weakRunLoop(AYRunloop *runloop, BOOL isWeak) {
    NSString *key = [NSString stringWithFormat:@"%p", runloop.runLoop];
    if (isWeak) {
        _AYRunloop *_runloop = [[_AYRunloop alloc] init];
        _runloop.runLoop = runloop;
        runLoopDict()[key] = _runloop;
    }else{
        runLoopDict()[key] = nil;
    }
}


AYRunloop *runLoop() {
    NSString *key = [NSString stringWithFormat:@"%p", CFRunLoopGetCurrent()];
    _AYRunloop *_runloop = runLoopDict()[key];
    AYRunloop * runLoop = _runloop.runLoop;
    if (!runLoop) {
        runLoop = [[AYRunloop alloc] init];
    }
    return runLoop;
}


@implementation AYRunloop

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

+(AYRunloop*)currentRunloop {
    NSThread *thread = [NSThread currentThread];
    if ([thread isMainThread]) {
        return nil;
    }
    return runLoop();
}

@end

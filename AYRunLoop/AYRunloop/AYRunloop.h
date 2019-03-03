//
//  AYRunloop.h
//  AYRunloop
//
//  Created by YLCHUN on 2017/2/14.
//  Copyright © 2017年 ylchun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AYRunloop : NSObject
@property (nonatomic, readonly) NSThread *thread;
@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, readonly) BOOL isCancelled;

+(AYRunloop*)currentRunloop;
-(void)run;
-(void)stop;
@end

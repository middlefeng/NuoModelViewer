//
//  NuoScheduler.m
//  ModelViewer
//
//  Created by Dong on 12/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoScheduler.h"



@implementation NuoScheduler
{
    void (^_task)(NSTimer* timer);
    void (^_idleTask)();
    
    NSTimer* _timer;
    NSTimer* _idleTimer;
}


- (void)scheduleWithInterval:(float)interval task:(void(^)())task;
{
    NSDate* scheduleDate = [NSDate date];
    
    __block struct NuoSchedule schedule = _schedule;
    __weak auto scheduler = self;
    
    _idleTask = ^()
            {
                NuoScheduler* localScheduler = scheduler;
                localScheduler->_idleTimer = nil;
                localScheduler->_timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                                         repeats:YES block:localScheduler->_task];
            };
    
    _task = ^(NSTimer* timer)
            {
                NSTimeInterval duration = [scheduleDate timeIntervalSinceNow];
                float durationInMin = duration / 60.0;
            
                if (durationInMin < schedule._duration)
                {
                    task();
                }
                else
                {
                    [timer invalidate];
                     
                    NuoScheduler* localScheduler = scheduler;
                    localScheduler->_timer = nil;
                    localScheduler->_idleTimer = [NSTimer scheduledTimerWithTimeInterval:localScheduler.schedule._idle * 60.0
                                                                                 repeats:NO block:^(NSTimer* timer)
                                                                                    {
                                                                                        localScheduler->_idleTask();
                                                                                    }];
                }
            };
    
    // kick off the schedule as it is in idle at first
    //
    _idleTask();
}


- (void)invalidate
{
    [_idleTimer invalidate];
    [_timer invalidate];
    
    _idleTimer = nil;
    _timer = nil;
    
    _task = nil;
    _idleTask = nil;
}


@end

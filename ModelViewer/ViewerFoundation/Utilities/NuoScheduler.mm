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
    void (^_task)();
    void (^_idleTask)();
    
    bool _valid;
    NSDate* _scheduleDate;
}


- (void)scheduleWithInterval:(float)interval task:(void(^)())task;
{
    __weak auto scheduler = self;
    
    _valid = true;
    
    _idleTask = ^()
            {
                NuoScheduler* localScheduler = scheduler;
                
                if (!localScheduler || !localScheduler->_valid)
                    return;
                
                NSDate* scheduleDate = [NSDate date];
                localScheduler->_scheduleDate = scheduleDate;
                
                localScheduler->_task();
            };
    
    _task = ^()
            {
                NuoScheduler* localScheduler = scheduler;
                
                if (!localScheduler || !localScheduler->_valid)
                    return;
                
                NSTimeInterval duration = [localScheduler->_scheduleDate timeIntervalSinceNow];
                float durationInMin = -duration / 60.0;
            
                if (durationInMin < localScheduler.schedule._duration)
                {
                    task();
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), localScheduler->_task);
                }
                else
                {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                                 (int64_t)(localScheduler.schedule._idle *
                                                           60.0 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), localScheduler->_idleTask);
                }
            };
    
    // kick off the schedule as it is in idle at first
    //
    _idleTask();
}


- (void)invalidate
{
    _valid = false;
    
    _task = nil;
    _idleTask = nil;
}


@end

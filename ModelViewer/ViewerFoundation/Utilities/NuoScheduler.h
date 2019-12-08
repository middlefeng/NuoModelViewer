//
//  NuoScheduler.h
//  ModelViewer
//
//  Created by Dong on 12/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>


struct NuoSchedule
{
    float _duration;
    float _idle;
};


@interface NuoScheduler : NSObject

@property (nonatomic, assign) NuoSchedule schedule;

- (void)scheduleWithInterval:(float)interval task:(void(^)())task;
- (void)invalidate;

@end



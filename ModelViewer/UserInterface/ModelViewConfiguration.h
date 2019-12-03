//
//  ModelViewConfiguration.h
//  ModelViewer
//
//  Created by Dong on 2/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>



struct ModelRenderSchedule
{
    float _renderDuration;
    float _idleDuration;
};



@interface ModelViewConfiguration : NSObject

@property (nonatomic, assign) CGRect windowFrame;
@property (nonatomic, strong) NSString* deviceName;
@property (nonatomic, assign) ModelRenderSchedule renderSchedule;

- (instancetype)initWithFile:(NSString*)path;
- (void)save;

- (id<MTLDevice>)device;
- (NSArray<NSString*>*)deviceNames;

@end

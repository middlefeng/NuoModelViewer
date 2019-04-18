//
//  NuoBufferVisualizeMesh.m
//  ModelViewer
//
//  Created by Dong on 4/18/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoBufferVisualizeMesh.h"
#import "NuoTypes.h"



@implementation NuoBufferVisualizeMesh
{
    __weak id<MTLBuffer> _buffer;
    NSArray<id<MTLBuffer>>* _rangeUniform;
    
    NuoRangeUniform _range;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        id<MTLBuffer> buffers[3];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
        {
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(NuoRangeUniform)
                                                          options:MTLResourceStorageModeManaged];
        }
        
        _rangeUniform = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
    }
    
    return self;
}


- (void)updateBuffer:(id<MTLBuffer>)buffer withRange:(const NuoRangeUniform&)range
{
    _buffer = buffer;
    _range = range;
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    memcpy(_rangeUniform[index].contents, &_range, sizeof(NuoRangeUniform));
    [_rangeUniform[index] didModifyRange:NSMakeRange(0, sizeof(NuoRangeUniform))];
    
    [renderPass setFragmentBuffer:_buffer offset:0 atIndex:0];
    [renderPass setFragmentBuffer:_rangeUniform[index] offset:0 atIndex:0];
    [super drawMesh:renderPass indexBuffer:index];
}


@end

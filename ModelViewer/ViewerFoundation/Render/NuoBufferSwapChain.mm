//
//  NuoBufferSwapChain.m
//  ModelViewer
//
//  Created by Dong on 5/4/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoBufferSwapChain.h"

#import "NuoRenderInFlight.h"



@implementation NuoBufferSwapChain
{
    NSArray<id<MTLBuffer>>* _buffers;
    MTLResourceOptions _options;
    size_t _contentSize;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
                WithBufferSize:(size_t)size
                   withOptions:(MTLResourceOptions)options
                 withChainSize:(uint)chainSize
{
    self = [super init];
    
    if (self)
    {
        id<MTLBuffer> buffers[chainSize];
        for (uint i = 0; i < chainSize; ++i)
            buffers[i] = [device newBufferWithLength:size options:options];
        
        _buffers = [[NSArray alloc] initWithObjects:buffers count:chainSize];
        _options = options;
        _contentSize = size;
    }
    
    return self;
}



- (void)updateBufferWithInFlight:(id<NuoRenderInFlight>)inFlight withContent:(void*)content
{
    id<MTLBuffer> buffer = _buffers[[inFlight inFlight]];
    memcpy(buffer.contents, content, _contentSize);
    
    if (_options != MTLResourceStorageModeShared)
        [buffer didModifyRange:NSMakeRange(0, _contentSize)];
}



- (id<MTLBuffer>)bufferForInFlight:(id<NuoRenderInFlight>)inFlight
{
    return _buffers[inFlight.inFlight];
}



@end

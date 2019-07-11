//
//  NuoArgumentBuffer.m
//  ModelViewer
//
//  Created by Dong on 7/10/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoArgumentBuffer.h"




@implementation NuoArgumentBuffer
{
    id<MTLBuffer> _buffer;
    id<MTLArgumentEncoder> _encoder;
    NSMutableArray<NuoArgumentUsage*>* _usages;
}



- (id<MTLBuffer>)buffer
{
    return _buffer;
}


- (NSArray<NuoArgumentUsage*>*)argumentsUsage
{
    return _usages;
}


- (void)encodeWith:(id<MTLArgumentEncoder>)encoder
{
    _buffer = [encoder.device newBufferWithLength:encoder.encodedLength options:0];
    
    [encoder setArgumentBuffer:_buffer offset:0];
    _encoder = encoder;
}


- (void)setBuffer:(id<MTLBuffer>)buffer for:(MTLResourceUsage)usage atIndex:(uint)index
{
    [_encoder setBuffer:buffer offset:0 atIndex:index];
    
    NuoArgumentUsage* usageEntry = [NuoArgumentUsage new];
    usageEntry.argument = buffer;
    usageEntry.usage = usage;
    
    [_usages addObject:usageEntry];
}



@end






@implementation NuoArgumentUsage


@end

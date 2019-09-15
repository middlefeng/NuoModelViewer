//
//  NuoArgumentBuffer.h
//  ModelViewer
//
//  Created by Dong on 7/10/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@interface NuoArgumentUsage : NSObject

@property (weak, nonatomic) id<MTLResource> argument;
@property (assign, nonatomic) MTLResourceUsage usage;

@end



@interface NuoArgumentBuffer : NSObject

- (id<MTLBuffer>)buffer;
- (NSArray<NuoArgumentUsage*>*)argumentsUsage;

- (void)encodeWith:(id<MTLArgumentEncoder>)encoder;
- (void)setBuffer:(id<MTLBuffer>)buffer for:(MTLResourceUsage)usage atIndex:(uint)index;
- (void)setTexture:(id<MTLTexture>)texture for:(MTLResourceUsage)usage atIndex:(uint)index;
- (void)setInt:(uint32_t)value atIndex:(uint)index;

@end



//
//  NuoArgumentBuffer.h
//  ModelViewer
//
//  Created by Dong on 7/10/19.
//  Updated on 7/15/23.
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@interface NuoArgumentUsage : NSObject

@property (weak, nonatomic) id<MTLResource> argument;
@property (assign, nonatomic) MTLResourceUsage usage;

@end


@class NuoComputePipeline;


@interface NuoArgumentBuffer : NSObject

@property (readonly) int index;

- (instancetype)initWithName:(NSString*)name;

- (id<MTLBuffer>)buffer;
- (NSArray<NuoArgumentUsage*>*)argumentsUsage;

- (void)encodeWith:(NuoComputePipeline*)pipeline forIndex:(int)index withSize:(uint)size;
- (void)setBuffer:(id<MTLBuffer>)buffer for:(MTLResourceUsage)usage atIndex:(uint)index;
- (void)setTexture:(id<MTLTexture>)texture for:(MTLResourceUsage)usage atIndex:(uint)index;
- (void)setInt:(uint32_t)value atIndex:(uint)index;

/**
 *  specify which item in an array typed argument buffer the subsequent functions will
 *  encode onto
 *
 *  figured by Dong, and confirmed by
 *  https://stackoverflow.com/questions/68171243/how-to-bind-a-variable-number-of-textures-to-metal-shader
 */
- (void)encodeItem:(uint)index;

@end



//
//  NuoComputeEncoder.h
//  ModelViewer
//
//  Created by middleware on 7/8/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoRenderInFlight.h"



@class NuoComputeEncoder;
@class NuoCommandBuffer;
@class NuoArgumentBuffer;



@interface NuoComputePipeline : NSObject



@property (nonatomic, strong) NSString* name;
@property (nonatomic, readonly) id<MTLIntersectionFunctionTable> intersectionFuncTable;

- (instancetype)initWithDevice:(id<MTLDevice>)device withFunction:(NSString*)function;


- (NuoComputeEncoder*)encoderWithCommandBuffer:(NuoCommandBuffer*)commandBuffer;
- (id<MTLArgumentEncoder>)argumentEncoder:(NSUInteger)index;
- (void)setFunctionConstantBool:(BOOL)value at:(NSUInteger)index;
- (void)addIntersectionFunction:(NSString*)intersectFunction;
- (void)setIntersectionResource:(id<MTLBuffer>)resource atIndex:(uint)index;


@end



@interface NuoComputeEncoder : NSObject < NuoRenderInFlight >


@property (nonatomic, assign) CGSize dataSize;


- (void)pushParameterState:(NSString*)name;
- (void)popParameterState;

- (void)setTargetTexture:(id<MTLTexture>)texture atIndex:(uint)index;
- (void)setTexture:(id<MTLTexture>)texture atIndex:(uint)index;
- (void)setSamplerState:(id<MTLSamplerState>)sampler atIndex:(uint)index;
- (void)setBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index;
- (void)setArgumentBuffer:(NuoArgumentBuffer*)buffer;
- (void)setAccelerateStruct:(id<MTLAccelerationStructure>)acStruct atIndex:(uint)index;
- (void)setIntersectionTable:(id<MTLIntersectionFunctionTable>)table atIndex:(uint)index;

- (void)dispatch;


@end


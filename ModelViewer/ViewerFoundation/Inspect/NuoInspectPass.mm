//
//  NuoInspectPass.m
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoInspectPass.h"
#import "NuoTextureMesh.h"
#import "NuoComputeEncoder.h"
#import "NuoRenderPassAttachment.h"



@implementation NuoInspectPass
{
    NuoTextureMesh* _inspect;
    
    id<MTLBuffer> _inspectBuffer;
    NuoComputePipeline* _bufferVisualize;
    NuoRangeUniform _bufferRange;
    id<MTLBuffer> _bufferRangeUniform;
    NuoRenderPassTarget* _bufferVisualizeTarget;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                         withProcess:(NSString*)inspectMean
                           forBuffer:(BOOL)forBuffer
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        _inspect = [[NuoTextureMesh alloc] initWithCommandQueue:commandQueue];
        _inspect.sampleCount = 1;
        
        if (forBuffer)
        {
            _bufferVisualize = [[NuoComputePipeline alloc] initWithDevice:self.commandQueue.device
                                                             withFunction:inspectMean withParameter:NO];
            
            _bufferVisualizeTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                                       withPixelFormat:pixelFormat
                                                                       withSampleCount:1];
            
            _bufferVisualizeTarget.manageTargetTexture = YES;
            _bufferVisualizeTarget.sharedTargetTexture = NO;
            _bufferVisualizeTarget.clearColor = MTLClearColor { 0, 0, 0, 0 };
            _bufferVisualizeTarget.colorAttachments[0].needWrite = YES;
            _bufferVisualizeTarget.name = @"Buffer Visualization";
            
            [_inspect makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
            
            _bufferRange = { 0, 0 };
        }
        else if (inspectMean)
        {
            [_inspect makePipelineAndSampler:pixelFormat withFragementShader:inspectMean withBlendMode:kBlend_Alpha];
        }
        else
        {
            [_inspect makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha];
        }
    }
    
    return self;
}



- (void)updateBuffer:(id<MTLBuffer>)buffer withRange:(const NuoRangeUniform&)range
{
    [_bufferVisualizeTarget setDrawableSize:CGSizeMake(range.w, range.h)];
    
    if (_bufferRange.w != range.w || _bufferRange.h != range.h)
    {
        _bufferRangeUniform = [self.commandQueue.device newBufferWithLength:sizeof(NuoRangeUniform)
                                                                    options:MTLResourceStorageModeManaged];
        memcpy(&_bufferRange, &range, sizeof(NuoRangeUniform));
        memcpy(_bufferRangeUniform.contents, &range, sizeof(NuoRangeUniform));
        
        [_bufferRangeUniform didModifyRange:NSMakeRange(0, sizeof(NuoRangeUniform))];
    }
    
    _inspectBuffer = buffer;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    if (_bufferVisualize && _inspectBuffer)
    {
        NuoComputeEncoder* computeEncoder = [_bufferVisualize encoderWithCommandBuffer:commandBuffer];
        
        [computeEncoder setBuffer:_bufferRangeUniform offset:0 atIndex:0];
        [computeEncoder setBuffer:_inspectBuffer offset:0 atIndex:1];
        [computeEncoder setTexture:_bufferVisualizeTarget.targetTexture atIndex:0];
        [computeEncoder dispatch];
    }
    
    id<MTLTexture> visualizeResult = _bufferVisualize ? _bufferVisualizeTarget.targetTexture :
                                                        self.sourceTexture;
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    // super for background checker
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    [_inspect setModelTexture:visualizeResult];
    [_inspect drawMesh:renderPass indexBuffer:inFlight];
    
    [self releaseDefaultEncoder];
}

@end

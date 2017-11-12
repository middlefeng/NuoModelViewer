//
//  MotionBlurRenderer.m
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "MotionBlurRenderer.h"
#import "NuoTextureAverageMesh.h"



@implementation MotionBlurRenderer
{
    id<MTLTexture> _latestSource;
    NuoTextureAverageMesh* _averageMesh;
}



- (void)setSourceTexture:(id<MTLTexture>)sourceTexture
{
    if (_latestSource == sourceTexture)
        return;
    
    _latestSource = sourceTexture;
    [_averageMesh appendTexture:sourceTexture];
}


- (id<MTLTexture>)sourceTexture
{
    return _latestSource;
}


@end

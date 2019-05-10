//
//  NuoRenderPassAttachment.h
//  ModelViewer
//
//  Created by Dong on 5/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>


/**
 *  attachment is the sum of all information and resources need for an attachment to start
 *  a render pass (i.e. an encoder in Metal). it includes a texture (sometimes a frame buffer),
 *  optionally with a resolving target (for MSAA), and the information such as clear color,
 *  load/store action.
 */


enum NuoRenderPassAttachmentType
{
    kNuoRenderPassAttachment_Color,
    kNuoRenderPassAttachment_Depth,
};


@interface NuoRenderPassAttachment : NSObject


@property (strong, nonatomic) NSString* name;

@property (assign, nonatomic) CGSize drawableSize;

@property (weak, nonatomic) id<MTLDevice> device;

@property (assign, nonatomic) BOOL manageTexture;
@property (assign, nonatomic) BOOL sharedTexture;
@property (strong, nonatomic) id<MTLTexture> texture;
@property (assign, nonatomic) MTLPixelFormat pixelFormat;

@property (assign, nonatomic) NSUInteger sampleCount;
@property (assign, nonatomic) BOOL needResolve;
@property (assign, nonatomic) BOOL needStore;
@property (assign, nonatomic) BOOL needClear;
@property (assign, nonatomic) BOOL needWrite;
@property (assign, nonatomic) MTLClearColor clearColor;

@property (assign, nonatomic) NuoRenderPassAttachmentType type;


- (void)makeTexture;
- (MTLRenderPassAttachmentDescriptor*)descriptor;

@end

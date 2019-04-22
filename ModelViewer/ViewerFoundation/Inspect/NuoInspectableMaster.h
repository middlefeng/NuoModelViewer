//
//  NuoInspectableMaster.h
//  ModelViewer
//
//  Created by middleware on 9/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoUniforms.h"


@class NuoTextureMesh;


extern NSString* const kInspectable_Immediate;
extern NSString* const kInspectable_ImmediateAlpha;
extern NSString* const kInspectable_Illuminate;
extern NSString* const kInspectable_Ambient;
extern NSString* const kInspectable_Shadow;
extern NSString* const kInspectable_ShadowTranslucent;
extern NSString* const kInspectable_ShadowOverlay;



@protocol NuoInspector <NSObject>

- (void)inspect;
- (void)setInspectAspectRatio:(CGFloat)aspectRatio;

@end




@interface NuoInspectable : NSObject

/**
 *  texture visualization
 */
@property (nonatomic, weak) id<MTLTexture> inspectedTexture;
@property (nonatomic, strong) NSString* inspectingTextureMean;

/**
 *  buffer visualization
 */
@property (nonatomic, weak) id<MTLBuffer> inspectedBuffer;
@property (nonatomic, assign) NuoRangeUniform inspectedBufferRange;
@property (nonatomic, strong) NSString* inspectingBufferMean;

@property (nonatomic, strong) NSString* displayTitle;
@property (nonatomic, strong) id<NuoInspector> inspector;


+ (NuoInspectable*)inspectableTextureWithTitle:(NSString*)title withMean:(NSString*)mean;
+ (NuoInspectable*)inspectableBufferWithTitle:(NSString*)title withMean:(NSString*)mean;

@end





@interface NuoInspectableMaster : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString*, NuoInspectable*>* inspectables;

+ (NuoInspectableMaster*)sharedMaster;
+ (NSDictionary<NSString*, NuoInspectable*>*)inspectableList;

- (NuoInspectable*)setInspector:(id<NuoInspector>)inspector forName:(NSString*)name;
- (void)removeInspectorForName:(NSString*)name;
- (void)updateTexture:(id<MTLTexture>)texture forName:(NSString*)name;

- (void)inspect;

@end



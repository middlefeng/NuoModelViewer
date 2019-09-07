//
//  NuoInspectableMaster.h
//  ModelViewer
//
//  Created by middleware on 9/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@class NuoTextureMesh;


extern NSString* const kInspectable_Immediate;
extern NSString* const kInspectable_ImmediateAlpha;
extern NSString* const kInspectable_RayTracing;
extern NSString* const kInspectable_RayTracingVirtualBlocked;
extern NSString* const kInspectable_Illuminate;
extern NSString* const kInspectable_Ambient;
extern NSString* const kInspectable_Shadow;
extern NSString* const kInspectable_ShadowTranslucent;
extern NSString* const kInspectable_DirectLightWithShadow;
extern NSString* const kInspectable_ShadowOverlay;



@protocol NuoInspector <NSObject>

- (void)inspect;
- (void)setInspectAspectRatio:(CGFloat)aspectRatio;

@end




@interface NuoInspectable : NSObject

@property (nonatomic, weak) id<MTLTexture> inspectedTexture;
@property (nonatomic, strong) NSString* displayTitle;
@property (nonatomic, strong) NSString* inspectingMean;
@property (nonatomic, strong) id<NuoInspector> inspector;


+ (NuoInspectable*)inspectableWithTitle:(NSString*)title withMean:(NSString*)mean;

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



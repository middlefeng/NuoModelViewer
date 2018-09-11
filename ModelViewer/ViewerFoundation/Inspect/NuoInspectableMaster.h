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
extern NSString* const kInspectable_Ambient;



@protocol NuoInspector <NSObject>

- (void)inspect;

@end




@interface NuoInspectable : NSObject

@property (nonatomic, weak) id<MTLTexture> inspectedTexture;
@property (nonatomic, strong) NuoTextureMesh* inspectingMean;
@property (nonatomic, strong) id<NuoInspector> inspector;

@end





@interface NuoInspectableMaster : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString*, NuoInspectable*>* inspectables;

+ (NuoInspectableMaster*)sharedMaster;
+ (NSDictionary*)inspectableList;

- (void)setInspector:(id<NuoInspector>)inspector forName:(NSString*)name;
- (void)removeInspectorForName:(NSString*)name;
- (void)updateTexture:(id<MTLTexture>)texture forName:(NSString*)name;

- (void)inspect;

@end



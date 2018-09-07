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




@interface NuoInspectable

@property (nonatomic, weak) id<MTLTexture> inspectedTexture;
@property (nonatomic, strong) NuoTextureMesh* inspectingMean;

@end





@interface NuoInspectableMaster : NSObject

@property (nonatomic, strong) NSDictionary<NSString*, NuoInspectable*>* inspectables;

@end



//
//  ModelDeferredRenderer.h
//  ModelViewer
//
//  Created by Dong on 10/25/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoDeferredRenderer.h"



@class NuoBackdropMesh;



@interface ModelDeferredRenderer : NuoDeferredRenderer


@property (nonatomic, strong) NuoBackdropMesh* backdropMesh;


@end

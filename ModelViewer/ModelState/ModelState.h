//
//  ModelState.h
//  ModelViewer
//
//  Created by Dong on 10/28/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Metal/Metal.h>

#include "NuoTypes.h"
#include "NuoBounds.h"
#include "NuoUniforms.h"
#include "NuoMatrixTypes.h"



@class NuoMeshSceneRoot;
@class NuoMeshCompound;
@class NuoMesh;
@class NuoBoardMesh;

class NuoMeshOptions;
class NuoTableExporter;
class NuoLua;



typedef enum
{
    kTransformMode_Model,
    kTransformMode_View,
}
TransformMode;



@interface ModelState : NSObject


@property (nonatomic, assign) bool rayTracingMultipleImportance;
@property (nonatomic, assign) bool rayTracingIndirectSpecular;


@property (nonatomic, strong) NuoMeshSceneRoot* sceneRoot;
@property (nonatomic, readonly) NuoMeshCompound* mainModelMesh;
@property (nonatomic, strong) NSArray<NuoMesh*>* selectedParts;

@property (nonatomic, assign) TransformMode transMode;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setAdvancedShaowEnabled:(BOOL)enabled;
- (void)setSampleCount:(NSUInteger)sampleCount;

- (void)loadMesh:(NSString*)path withProgress:(NuoProgressFunction)progress;
- (void)createMeshsWithProgress:(NuoProgressFunction)progress;

- (NuoBoardMesh*)createBoard:(CGSize)size withName:(NSString*)name;
- (void)removeSelectedMesh;
- (void)removeAllBoards;

- (void)exportScenePoises:(NuoTableExporter*)exporter;
- (void)exportBoardModels:(NuoTableExporter*)exporter;
- (void)exportModelConfiguration:(NuoTableExporter*)exporter;

- (void)importScenePoises:(NuoLua*)lua;
- (void)importBoardModels:(NuoLua*)lua;
- (void)importModelConfiguration:(NuoLua*)lua;

- (void)updateModelOptionsWithProgress:(NuoProgressFunction)progress;
- (NuoMeshOptions&)modelOptions;

- (void)selectMesh:(NuoMesh*)mesh;
- (NuoBounds)selectedMeshBounds:(const NuoMatrixFloat44&)viewMatrix;

- (BOOL)viewTransformReset;
- (void)resetViewTransform;
- (NuoMatrixFloat44)viewMatrix;
- (void)caliberateSceneCenter;

- (void)rotateX:(float)x Y:(float)y;
- (void)tanslate:(const NuoVectorFloat3&)translation;

- (size_t)configurableMeshPartsNumber;
- (NSArray<NuoMesh*>*)configurableMeshParts;
- (void)setSelectedParts:(NSArray<NuoMesh*>*)selected;
- (void)resetSelectionIndicators;
- (NSArray<NuoMesh*>*)selectedIndicators;
- (NuoMeshSceneRoot*)cloneSceneFor:(NuoMeshModeShaderParameter)mode;


@end



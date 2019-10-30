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
@class NuoMeshOption;

class NuoTableExporter;
class NuoLua;



@interface ModelState : NSObject


@property (nonatomic, strong) NuoMeshSceneRoot* sceneRoot;
@property (nonatomic, readonly) NuoMeshCompound* mainModelMesh;
@property (nonatomic, strong) NSArray<NuoMesh*>* selectedParts;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setAdvancedShaowEnabled:(BOOL)enabled;
- (void)setSampleCount:(NSUInteger)sampleCount;

- (void)loadMesh:(NSString*)path withProgress:(NuoProgressFunction)progress;
- (void)createMeshsWithProgress:(NuoProgressFunction)progress;

- (NuoBoardMesh*)createBoard:(CGSize)size withName:(NSString*)name;
- (void)removeSelectedMesh;
- (void)removeAllBoards;

- (void)exportMainModel:(NuoTableExporter*)exporter;
- (void)exportBoardModels:(NuoTableExporter*)exporter;
- (void)exportModelConfiguration:(NuoTableExporter*)exporter;

- (void)importMainModel:(NuoLua*)lua;
- (void)importBoardModels:(NuoLua*)lua;
- (void)importModelConfiguration:(NuoLua*)lua;

- (void)setModelOptions:(NuoMeshOption*)modelOptions
           withProgress:(NuoProgressFunction)progress;

- (void)selectMesh:(NuoMesh*)mesh;
- (NuoBounds)selectedMeshBounds:(const NuoMatrixFloat44&)viewMatrix;
- (void)selectedMeshTranslateX:(float)x Y:(float)y Z:(float)z;
- (void)selectedMeshRotationX:(float)x Y:(float)y;

- (size_t)configurableMeshPartsNumber;
- (NSArray<NuoMesh*>*)configurableMeshParts;
- (void)setSelectedParts:(NSArray<NuoMesh*>*)selected;
- (void)resetSelectionIndicators;
- (NSArray<NuoMesh*>*)selectedIndicators;
- (NuoMeshSceneRoot*)cloneSceneFor:(NuoMeshModeShaderParameter)mode;


@end



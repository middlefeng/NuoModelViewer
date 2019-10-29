//
//  ModelState.m
//  ModelViewer
//
//  Created by Dong on 10/28/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "ModelState.h"
#import "NuoModelLoaderGPU.h"

#include "NuoBoardMesh.h"
#include "NuoMeshSceneRoot.h"

#include "NuoLua.h"
#include "NuoModelLoader.h"
#include "NuoTableExporter.h"


@interface ModelState()


@property (nonatomic, strong) NSMutableArray<NuoBoardMesh*>* boardMeshes;

@property (nonatomic, weak) NuoMesh* selectedMesh;
@property (nonatomic, strong) NSArray<NuoMesh*>* selectedIndicator;
@property (nonatomic, strong) NuoMeshSceneRoot* sceneRootForMode;

@property (strong) NuoModelLoaderGPU* modelLoader;
@property (weak) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) NuoMeshOption* modelOptions;


@end




@implementation ModelState
{
    __weak NuoMeshCompound* _mainModelMesh;
}



@dynamic mainModelMesh;



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    if (self)
    {
        _commandQueue = commandQueue;
        
        _modelOptions = [NuoMeshOption new];
        _sceneRoot = [[NuoMeshSceneRoot alloc] init];
        _boardMeshes = [NSMutableArray new];
    }
    
    return self;
}


- (void)loadMesh:(NSString*)path withProgress:(NuoProgressFunction)progress
{
    std::shared_ptr<NuoModelLoader> loader = std::make_shared<NuoModelLoader>();
    loader->LoadModel(path.UTF8String);
    
    _modelLoader = [[NuoModelLoaderGPU alloc] initWithLoader:loader];
    
    [self createMeshsWithProgress:^(float progressPercent)
         {
             progress(progressPercent * (1 - 0.3) + 0.3);
         }];
    
    [_mainModelMesh centerMesh];
    
    // move model from camera for a default distance (3 times of r)
    //
    const NuoBounds bounds = [_mainModelMesh worldBounds:NuoMatrixFloat44Identity].boundingBox;
    const float radius = bounds.MaxDimension() / 2.0;
    const float defaultDistance = - 3.0 * radius;
    const NuoVectorFloat3 defaultDistanceVec(0, 0, defaultDistance);
    [_mainModelMesh setTransformTranslate:NuoMatrixTranslation(defaultDistanceVec)];
}


- (void)createMeshsWithProgress:(NuoProgressFunction)progress
{
    NuoMeshCompound* mesh = [_modelLoader createMeshsWithOptions:_modelOptions
                                                withCommandQueue:_commandQueue
                                                    withProgress:progress];

    [_sceneRoot replaceMesh:_mainModelMesh with:mesh];
    
    _mainModelMesh = mesh;
    _selectedMesh = mesh;
}


- (NuoBoardMesh*)createBoard:(CGSize)size withName:(NSString*)name
{
    std::shared_ptr<NuoModelBoard> modelBoard(new NuoModelBoard(size.width, size.height, 0.001));
    modelBoard->CreateBuffer();
    modelBoard->SetName(name.UTF8String);
    NuoBoardMesh* boardMesh = CreateBoardMesh(self.commandQueue, modelBoard, [_modelOptions basicMaterialized]);
    
    const NuoBounds bounds = boardMesh.boundsLocal.boundingBox;
    const float radius = bounds.MaxDimension();
    const float defaultDistance = - 3.0 * radius;
    const NuoVectorFloat3 defaultDistanceVec(0, 0, defaultDistance);
    [boardMesh setTransformTranslate:NuoMatrixTranslation(defaultDistanceVec)];
    [_boardMeshes addObject:boardMesh];
    
    // boards are all opaque so they are drawn first
    //
    [_sceneRoot addBoardObject:boardMesh];
    
    return boardMesh;
}


- (void)removeMesh:(NuoMesh*)mesh
{
    if (_sceneRoot.meshes.count > 0)
    {
        [_sceneRoot removeMesh:mesh];
        
        if ([mesh isKindOfClass:[NuoBoardMesh class]])
        {
            NuoBoardMesh* boardMesh = (NuoBoardMesh*)mesh;
            [_boardMeshes removeObject:boardMesh];
        }
        
        if (mesh == _mainModelMesh)
        {
            _mainModelMesh = nil;
            _modelLoader = nil;
        }
        
        if (_sceneRoot.meshes.count > 0 && mesh == _selectedMesh)
            _selectedMesh = _sceneRoot.meshes[0];
        else
            _selectedMesh = nil;
    }
}


- (void)removeSelectedMesh
{
    [self removeMesh:_selectedMesh];
}


- (void)removeAllBoards
{
    for (NuoMesh* mesh in _boardMeshes)
        [_sceneRoot removeMesh:mesh];

    [_boardMeshes removeAllObjects];
}


- (NSArray<NuoMesh*>*)configurableMeshParts
{
    NSMutableArray* result = [NSMutableArray arrayWithArray:_mainModelMesh.meshes];
    for (NuoMesh* mesh in _boardMeshes)
         [result addObject:mesh];
    
    return result;
}



- (void)setModelOptions:(NuoMeshOption*)modelOptions
           withProgress:(NuoProgressFunction)progress
{
    _modelOptions = modelOptions;
    
    if (_modelLoader)
    {
        const NuoMatrixFloat44 originalPoise = _mainModelMesh.transformPoise;
        const NuoMatrixFloat44 originalTrans = _mainModelMesh.transformTranslate;
        
        [self createMeshsWithProgress:progress];
        
        _mainModelMesh.transformPoise = originalPoise;
        _mainModelMesh.transformTranslate = originalTrans;
    }
    
    for (NuoBoardMesh* board in _boardMeshes)
    {
        board.shadowOverlayOnly = [modelOptions basicMaterialized];
        [board makePipelineState];
    }
}


- (void)setAdvancedShaowEnabled:(BOOL)enabled
{
    [_sceneRoot setShadowOptionPCSS:enabled];
    [_sceneRoot setShadowOptionPCF:enabled];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    [_sceneRoot setSampleCount:sampleCount];
}


- (NuoMeshCompound*)mainModelMesh
{
    return _mainModelMesh;
}


- (NuoBounds)selectedMeshBounds:(const NuoMatrixFloat44&)viewMatrix
{
    NuoBounds bounds;
    if (_selectedMesh)
        bounds = [_selectedMesh worldBounds:viewMatrix].boundingBox;
    
    return bounds;
}


- (void)selectedMeshTranslateX:(float)x Y:(float)y Z:(float)z
{
    const NuoVectorFloat3 translation
    (
        x, y, z
    );
    
     const NuoMatrixFloat44 transMatrix = NuoMatrixTranslation(translation) * _selectedMesh.transformTranslate;
     [_selectedMesh setTransformTranslate:transMatrix];
}


- (void)selectedMeshRotationX:(float)x Y:(float)y
{
    _selectedMesh.transformPoise = NuoMatrixRotationAppend(_selectedMesh.transformPoise, x, y);
}


- (void)selectMesh:(NuoMesh*)mesh
{
    _selectedMesh = mesh;
}


- (void)setSelectedParts:(NSArray<NuoMesh*>*)selected
{
    _selectedParts = selected;
}


- (void)resetSelectionIndicators
{
    _selectedIndicator = nil;
}


- (NSArray<NuoMesh*>*)selectedIndicators
{
    if (_selectedIndicator)
        return _selectedIndicator;
    
    NSMutableArray<NuoMesh*>* selectedIndicate = [NSMutableArray new];
    for (NuoMesh* mesh in _selectedParts)
        [selectedIndicate addObject:[mesh cloneForMode:kMeshMode_Selection]];
    
    _selectedIndicator = selectedIndicate;
    
    return _selectedIndicator;
}


- (NuoMeshSceneRoot*)cloneSceneFor:(NuoMeshModeShaderParameter)mode
{
    _sceneRootForMode = [_sceneRoot cloneForMode:mode];
    return _sceneRootForMode;
}


- (void)exportMainModel:(NuoTableExporter*)exporter
{
    {
        exporter->StartEntry("rotationMatrix");
        exporter->SetMatrix(_mainModelMesh.transformPoise);
        exporter->EndEntry(true);
    }
    
    {
        exporter->StartEntry("translationMatrix");
        exporter->SetMatrix(_mainModelMesh.transformTranslate);
        exporter->EndEntry(true);
    }
}


- (void)exportBoardModels:(NuoTableExporter*)exporter
{
    {
        exporter->StartEntry("boards");
        exporter->StartTable();
        
        size_t meshIndex = 0;
        
        for (NuoBoardMesh* boardMesh in _boardMeshes)
        {
            exporter->StartArrayIndex(++meshIndex);
            exporter->StartTable();
            
            {
                exporter->StartEntry("dimensions");
                exporter->StartTable();
                {
                    const NuoVectorFloat3& dimension = boardMesh.dimensions;
                    exporter->StartEntry("width");
                    exporter->SetEntryValueFloat(dimension.x());
                    exporter->EndEntry(false);
                    exporter->StartEntry("height");
                    exporter->SetEntryValueFloat(dimension.y());
                    exporter->EndEntry(false);
                    exporter->StartEntry("thickness");
                    exporter->SetEntryValueFloat(dimension.z());
                    exporter->EndEntry(false);
                }
                exporter->EndTable();
                exporter->EndEntry(true);
                
                exporter->StartEntry("name");
                exporter->SetEntryValueString(boardMesh.modelName.UTF8String);
                exporter->EndEntry(true);
                
                exporter->StartEntry("diffuse");
                {
                    exporter->StartTable();
                    exporter->StartEntry("r");
                    exporter->SetEntryValueFloat(boardMesh.diffuse.redComponent);
                    exporter->EndEntry(false);
                    exporter->StartEntry("g");
                    exporter->SetEntryValueFloat(boardMesh.diffuse.greenComponent);
                    exporter->EndEntry(false);
                    exporter->StartEntry("b");
                    exporter->SetEntryValueFloat(boardMesh.diffuse.blueComponent);
                    exporter->EndEntry(false);
                    exporter->EndTable();
                }
                exporter->EndEntry(true);
                
                exporter->StartEntry("specular");
                {
                    exporter->StartTable();
                    exporter->StartEntry("r");
                    exporter->SetEntryValueFloat(boardMesh.specular.redComponent);
                    exporter->EndEntry(false);
                    exporter->StartEntry("g");
                    exporter->SetEntryValueFloat(boardMesh.specular.greenComponent);
                    exporter->EndEntry(false);
                    exporter->StartEntry("b");
                    exporter->SetEntryValueFloat(boardMesh.specular.blueComponent);
                    exporter->EndEntry(false);
                    exporter->StartEntry("power");
                    exporter->SetEntryValueFloat(boardMesh.specularPower);
                    exporter->EndEntry(false);
                    exporter->EndTable();
                }
                exporter->EndEntry(true);
                
                exporter->StartEntry("translationMatrix");
                exporter->SetMatrix(boardMesh.transformTranslate);
                exporter->EndEntry(true);
                
                exporter->StartEntry("rotationMatrix");
                exporter->SetMatrix(boardMesh.transformPoise);
                exporter->EndEntry(true);
            }
            
            exporter->EndTable();
            exporter->EndEntry(true);
        }
        
        exporter->EndTable();
        exporter->EndEntry(true);
    }
}


- (void)exportModelConfiguration:(NuoTableExporter*)exporter
{
    exporter->StartEntry("models");
    exporter->StartTable();
    
    size_t index = 0;
    
    for (NuoMesh* meshItem in _mainModelMesh.meshes)
    {
        if (meshItem.smoothTolerance > 0.001 || !meshItem.enabled ||
            meshItem.reverseCommonCullMode || (meshItem.hasUnifiedMaterial && meshItem.unifiedOpacity != 1.0))
        {
            exporter->StartArrayIndex(++index);
            exporter->StartTable();
            
            exporter->StartEntry("name");
            exporter->SetEntryValueString(meshItem.modelName.UTF8String);
            exporter->EndEntry(false);
            
            exporter->StartEntry("enabled");
            exporter->SetEntryValueBool(meshItem.enabled);
            exporter->EndEntry(false);
            
            exporter->StartEntry("smooth");
            exporter->SetEntryValueFloat(meshItem.smoothTolerance);
            exporter->EndEntry(false);
            
            exporter->StartEntry("smoothConservative");
            exporter->SetEntryValueBool(meshItem.smoothConservative);
            exporter->EndEntry(false);
            
            exporter->StartEntry("cullModeReverse");
            exporter->SetEntryValueBool(meshItem.reverseCommonCullMode);
            exporter->EndEntry(false);
            
            exporter->StartEntry("opacity");
            exporter->SetEntryValueFloat(meshItem.unifiedOpacity);
            exporter->EndEntry(false);
            
            exporter->EndTable();
            exporter->EndEntry(true);
        }
    }

    exporter->EndTable();
    exporter->EndEntry(true);
}


- (void)importMainModel:(NuoLua*)lua
{
    lua->GetField("rotationMatrix", -1);
    [_mainModelMesh setTransformPoise:lua->GetMatrixFromTable(-1)];
    lua->RemoveField();
    
    lua->GetField("translationMatrix", -1);
    if (!lua->IsNil(-1))
        [_mainModelMesh setTransformTranslate:lua->GetMatrixFromTable(-1)];
    lua->RemoveField();
}



- (void)importBoardModels:(NuoLua*)lua
{
    lua->GetField("boards", -1);
    
    if (!lua->IsNil(-1))
    {
        const size_t length = lua->GetArraySize(-1);
        if (length > 0)
            [self removeAllBoards];
        
        for (size_t i = 0; i < length; ++i)
        {
            lua->GetItem((int)(i + 1), -1);
            
            float width, height, thickness;
            {
                lua->GetField("dimensions", -1);
                
                width = lua->GetFieldAsNumber("width", -1);
                height = lua->GetFieldAsNumber("height", -1);
                thickness = lua->GetFieldAsNumber("thickness", -1);
                
                lua->RemoveField();
            }
            
            NSString* nameStr = nil;
            {
                lua->GetField("name", -1);
                
                if (lua->IsNil(-1))
                {
                    nameStr = @"Virtual";
                }
                else
                {
                    std::string name = lua->GetFieldAsString("name", -2);
                    nameStr = @(name.c_str());
                }
                
                lua->RemoveField();
            }
            
            NuoBoardMesh* boardMesh = [self createBoard:CGSizeMake(width, height) withName:nameStr];
            lua->GetField("rotationMatrix", -1);
            [boardMesh setTransformPoise:lua->GetMatrixFromTable(-1)];
            lua->RemoveField();
            
            lua->GetField("translationMatrix", -1);
            [boardMesh setTransformTranslate:lua->GetMatrixFromTable(-1)];
            lua->RemoveField();
            
            lua->GetField("diffuse", -1);
            if (!lua->IsNil(-1))
            {
                float r = lua->GetFieldAsNumber("r", -1);
                float g = lua->GetFieldAsNumber("g", -1);
                float b = lua->GetFieldAsNumber("b", -1);
                [boardMesh setDiffuse:[NSColor colorWithRed:r green:g blue:b alpha:1.0]];
            }
            lua->RemoveField();
            
            lua->GetField("specular", -1);
            if (!lua->IsNil(-1))
            {
                float r = lua->GetFieldAsNumber("r", -1);
                float g = lua->GetFieldAsNumber("g", -1);
                float b = lua->GetFieldAsNumber("b", -1);
                [boardMesh setSpecular:[NSColor colorWithRed:r green:g blue:b alpha:1.0]];
                [boardMesh setSpecularPower:lua->GetFieldAsNumber("power", -1)];
            }
            lua->RemoveField();
            
            lua->RemoveField();
        }
    }
    
    lua->RemoveField();
}



- (void)importModelConfiguration:(NuoLua*)lua
{
    lua->GetField("models", -1);
    
    const size_t length = lua->GetArraySize(-1);
    size_t passedModel = 0;
    
    for (size_t i = 0; i < length; ++i)
    {
        lua->GetItem((int)(i + 1), -1);
        const std::string name = lua->GetFieldAsString("name", -1);
        for (size_t i = passedModel; i < _mainModelMesh.meshes.count; ++i)
        {
            NuoMesh* mesh = _mainModelMesh.meshes[i];
            
            if (mesh.modelName.UTF8String == name)
            {
                [mesh setEnabled:lua->GetFieldAsBool("enabled", -1)];
                [mesh setReverseCommonCullMode:lua->GetFieldAsBool("cullModeReverse", -1)];
                [mesh setUnifiedOpacity:lua->GetFieldAsNumber("opacity", -1)];
                [mesh setSmoothConservative:lua->GetFieldAsBool("smoothConservative", -1)];
                [mesh smoothWithTolerance:lua->GetFieldAsNumber("smooth", -1)];
                
                passedModel = ++i;
                break;
            }
        }
        lua->RemoveField();
    }
    lua->RemoveField();
}



@end

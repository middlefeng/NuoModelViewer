//
//  NuoModelLoader.m
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoModelLoader.h"

#include "NuoModelBase.h"
#include "NuoMaterial.h"
#include "NuoMesh.h"

#include "tiny_obj_loader.h"



typedef std::vector<tinyobj::shape_t> ShapeVector;
typedef std::shared_ptr<ShapeVector> PShapeVector;
typedef std::map<NuoMaterial, tinyobj::shape_t> ShapeMapByMaterial;
typedef std::shared_ptr<ShapeMapByMaterial> PShapeMapByMaterial;




static void DoSplitShapes(const PShapeVector result, const tinyobj::shape_t shape)
{
    tinyobj::mesh_t mesh = shape.mesh;
    
    assert(mesh.num_face_vertices.size() == mesh.material_ids.size());
    
    size_t faceAccount = mesh.num_face_vertices.size();
    size_t i = 0;
    for (i = 0; i < faceAccount - 1; ++i)
    {
        unsigned char numPerFace1 = mesh.num_face_vertices[i];
        unsigned char numPerFace2 = mesh.num_face_vertices[i+1];
        
        int material1 = mesh.material_ids[i];
        int material2 = mesh.material_ids[i+1];
        
        if (numPerFace1 != numPerFace2 || material1 != material2)
        {
            tinyobj::shape_t splitShape;
            tinyobj::shape_t remainShape;
            splitShape.name = shape.name;
            remainShape.name = shape.name;
            
            std::vector<tinyobj::index_t>& addedIndices = splitShape.mesh.indices;
            std::vector<tinyobj::index_t>& remainIndices = remainShape.mesh.indices;
            addedIndices.insert(addedIndices.begin(),
                                mesh.indices.begin(),
                                mesh.indices.begin() + (i + 1) * numPerFace1);
            remainIndices.insert(remainIndices.begin(),
                                 mesh.indices.begin() + (i + 1) * numPerFace1,
                                 mesh.indices.end());
            
            std::vector<unsigned char>& addedNumberPerFace = splitShape.mesh.num_face_vertices;
            std::vector<unsigned char>& remainNumberPerFace = remainShape.mesh.num_face_vertices;
            addedNumberPerFace.insert(addedNumberPerFace.begin(),
                                      mesh.num_face_vertices.begin(),
                                      mesh.num_face_vertices.begin() + i + 1);
            remainNumberPerFace.insert(remainNumberPerFace.begin(),
                                       mesh.num_face_vertices.begin() + i + 1,
                                       mesh.num_face_vertices.end());
            
            std::vector<int>& addedMaterial = splitShape.mesh.material_ids;
            std::vector<int>& remainMaterial = remainShape.mesh.material_ids;
            addedMaterial.insert(addedMaterial.begin(),
                                 mesh.material_ids.begin(),
                                 mesh.material_ids.begin() + i + 1);
            remainMaterial.insert(remainMaterial.begin(),
                                  mesh.material_ids.begin() + i + 1,
                                  mesh.material_ids.end());
            
            result->push_back(splitShape);
            DoSplitShapes(result, remainShape);
            break;
        }
    }
    
    if (i == faceAccount - 1)
        result->push_back(shape);
}



static tinyobj::shape_t DoMergeShapes(std::vector<tinyobj::shape_t> shapes)
{
    tinyobj::shape_t result;
    result.name = shapes[0].name;
    
    for (const auto& shape : shapes)
    {
        result.mesh.indices.insert(result.mesh.indices.end(),
                                   shape.mesh.indices.begin(),
                                   shape.mesh.indices.end());
        result.mesh.material_ids.insert(result.mesh.material_ids.end(),
                                        shape.mesh.material_ids.begin(),
                                        shape.mesh.material_ids.end());
        result.mesh.num_face_vertices.insert(result.mesh.num_face_vertices.end(),
                                             shape.mesh.num_face_vertices.begin(),
                                             shape.mesh.num_face_vertices.end());
    }
    
    return result;
}




static PShapeMapByMaterial DoMergeShapesInVector(const PShapeVector result, std::vector<tinyobj::material_t>& materials)
{
    typedef std::map<NuoMaterial, std::vector<tinyobj::shape_t>> ShapeMap;
    ShapeMap shapesMap;
    
    NuoMaterial nonMaterial;
    
    for (size_t i = 0; i < result->size(); ++i)
    {
        const auto& shape = (*result)[i];
        int shapeMaterial = shape.mesh.material_ids[0];
        
        if (shapeMaterial < 0)
        {
            shapesMap[nonMaterial].push_back(shape);
        }
        else
        {
            tinyobj::material_t material = materials[(size_t)shapeMaterial];
            NuoMaterial materialIndex(material);
            shapesMap[materialIndex].push_back(shape);
        }
    }
    
    result->clear();
    
    PShapeMapByMaterial shapeMapByMaterial = std::make_shared<ShapeMapByMaterial>();
    
    for (auto itr = shapesMap.begin(); itr != shapesMap.end(); ++itr)
    {
        const NuoMaterial& material = itr->first;
        std::vector<tinyobj::shape_t>& shapes = itr->second;
        shapeMapByMaterial->insert(std::make_pair(material, DoMergeShapes(shapes)));
    }
    
    return shapeMapByMaterial;
}




static PShapeMapByMaterial GetShapeVectorByMaterial(ShapeVector& shapes, std::vector<tinyobj::material_t> &materials)
{
    PShapeVector result = std::make_shared<ShapeVector>();
    for (const auto& shape : shapes)
        DoSplitShapes(result, shape);
    
    PShapeMapByMaterial shapeMap;
    shapeMap = DoMergeShapesInVector(result, materials);
    
    return shapeMap;
}




@implementation NuoModelLoader



-(NSArray<NuoMesh*>*)loadModelObjects:(NSString*)objPath
                             withType:(NSString*)type
                           withDevice:(id<MTLDevice>)device
{
    typedef std::shared_ptr<NuoModelBase> PNuoModelBase;
    
    tinyobj::attrib_t attrib;
    std::vector<tinyobj::shape_t> shapes;
    std::vector<tinyobj::material_t> materials;
    std::string err;
    
    NSString* basePath = [objPath stringByDeletingLastPathComponent];
    basePath = [basePath stringByAppendingString:@"/"];
    
    tinyobj::LoadObj(&attrib, &shapes, &materials, &err, objPath.UTF8String, basePath.UTF8String);
    
    PShapeMapByMaterial shapeMap = GetShapeVectorByMaterial(shapes, materials);
    
    std::vector<PNuoModelBase> models;
    std::vector<uint32> indices;
    
    for (const auto& shapeItr : (*shapeMap))
    {
        const NuoMaterial material(shapeItr.first);
        const tinyobj::shape_t& shape = shapeItr.second;
        
        PNuoModelBase modelBase = CreateModel(type.UTF8String, material);
        
        for (size_t i = 0; i < shape.mesh.indices.size(); ++i)
        {
            tinyobj::index_t index = shape.mesh.indices[i];
            
            modelBase->AddPosition(index.vertex_index, attrib.vertices);
            if (attrib.normals.size())
                modelBase->AddNormal(index.normal_index, attrib.normals);
            if (material.HasDiffuseTexture())
                modelBase->AddTexCoord(index.texcoord_index, attrib.texcoords);
        }
        
        modelBase->GenerateIndices();
        if (!attrib.normals.size())
            modelBase->GenerateNormals();
        
        if (material.HasDiffuseTexture())
        {
            NSString* diffuseTexName = [NSString stringWithUTF8String:material.diffuse_texname.c_str()];
            NSString* diffuseTexPath = [basePath stringByAppendingPathComponent:diffuseTexName];
            
            modelBase->SetTexturePath(diffuseTexPath.UTF8String);
        }
        
        models.push_back(modelBase);
    }
    
    NSMutableArray<NuoMesh*>* result = [[NSMutableArray<NuoMesh*> alloc] init];
    
    for (auto& model : models)
    {
        NuoBox boundingBox = model->GetBoundingBox();
        
        NSString* modelType = [NSString stringWithUTF8String:model->TypeName().c_str()];
        NuoMesh* mesh = CreateMesh(modelType, device, model);
        
        NuoMeshBox* meshBounding = [[NuoMeshBox alloc] init];
        meshBounding.spanX = boundingBox._spanX;
        meshBounding.spanY = boundingBox._spanY;
        meshBounding.spanZ = boundingBox._spanZ;
        meshBounding.centerX = boundingBox._centerX;
        meshBounding.centerY = boundingBox._centerY;
        meshBounding.centerZ = boundingBox._centerZ;
        
        mesh.boundingBox = meshBounding;
        [result addObject:mesh];
    }
    
    return result;
}

@end

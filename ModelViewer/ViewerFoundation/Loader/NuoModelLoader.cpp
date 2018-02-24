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

#include "tiny_obj_loader.h"
#include <cassert>



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
        
        assert(numPerFace1 == 3);
        assert(numPerFace2 == 3);
        
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




static PShapeMapByMaterial DoMergeShapesInVector(const PShapeVector result,
                                                 std::vector<tinyobj::material_t>& materials,
                                                 bool combineMaterial)
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
            NuoMaterial materialIndex(material, !combineMaterial);
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




static PShapeMapByMaterial GetShapeVectorByMaterial(ShapeVector& shapes,
                                                    std::vector<tinyobj::material_t> &materials,
                                                    bool combineMaterial)
{
    PShapeVector result = std::make_shared<ShapeVector>();
    for (const auto& shape : shapes)
        DoSplitShapes(result, shape);
    
    PShapeMapByMaterial shapeMap;
    shapeMap = DoMergeShapesInVector(result, materials, combineMaterial);
    
    return shapeMap;
}




class NuoModelLoader_Internal
{
public:
    std::string _basePath;
    
    tinyobj::attrib_t _attrib;
    std::vector<tinyobj::shape_t> _shapes;
    std::vector<tinyobj::material_t> _materials;
};



NuoModelLoader::NuoModelLoader()
{
    _internal = new NuoModelLoader_Internal;
}



NuoModelLoader::~NuoModelLoader()
{
    delete _internal;
}




void NuoModelLoader::LoadModel(const std::string& path)
{
    std::string err;
    
    size_t pos = path.find_last_of("/");
    
    _internal->_basePath = path.substr(0, pos + 1);
    
    _internal->_shapes.clear();
    _internal->_materials.clear();
    
    tinyobj::LoadObj(&_internal->_attrib, &_internal->_shapes, &_internal->_materials,
                     &err, path.c_str(), _internal->_basePath.c_str());
}



std::vector<PNuoModelBase> NuoModelLoader::CreateMeshWithOptions(const NuoModelOption& options, bool combineMaterial,
                                                                 NuoModelLoaderProgress progressFunc)
{
    typedef std::shared_ptr<NuoModelBase> PNuoModelBase;
    
    PShapeMapByMaterial shapeMap = GetShapeVectorByMaterial(_internal->_shapes, _internal->_materials, combineMaterial);
    
    std::vector<PNuoModelBase> models;
    std::vector<uint32_t> indices;
    
    unsigned long vertexNumTotal = 0;
    unsigned long vertexNumLoaded = 0;
    for (tinyobj::shape_t shape : _internal->_shapes)
         vertexNumTotal += shape.mesh.indices.size();
    
    for (const auto& shapeItr : (*shapeMap))
    {
        const NuoMaterial material(shapeItr.first);
        const tinyobj::shape_t& shape = shapeItr.second;
        
        PNuoModelBase modelBase = CreateModel(options, material, shape.name);
        
        for (size_t i = 0; i < shape.mesh.indices.size(); ++i)
        {
            tinyobj::index_t index = shape.mesh.indices[i];
            
            modelBase->AddPosition(index.vertex_index, _internal->_attrib.vertices);
            if (_internal->_attrib.normals.size())
                modelBase->AddNormal(index.normal_index, _internal->_attrib.normals);
            if (material.HasTextureDiffuse())
                modelBase->AddTexCoord(index.texcoord_index, _internal->_attrib.texcoords);
            
            int materialID = shape.mesh.material_ids[i / 3];
            if (materialID >= 0)
            {
                NuoMaterial vertexMaterial(_internal->_materials[materialID], false /* ignored */);
                modelBase->AddMaterial(vertexMaterial);
            }
        }
        
        modelBase->GenerateIndices();
        if (!_internal->_attrib.normals.size())
            modelBase->GenerateNormals();
        
        if (material.HasTextureDiffuse())
        {
            const char* diffuseTexName = material.diffuse_texname.c_str();
            std::string diffuseTexPath = _internal->_basePath + diffuseTexName;
            
            modelBase->SetTexturePathDiffuse(diffuseTexPath);
        }
        
        if (material.HasTextureOpacity())
        {
            const char* opacityTexName = material.alpha_texname.c_str();
            std::string opacityTexPath = _internal->_basePath + opacityTexName;
            
            modelBase->SetTexturePathOpacity(opacityTexPath);
        }
        
        if (material.HasTextureBump())
        {
            const char* bumpTexName = material.bump_texname.c_str();
            std::string bumpTexPath = _internal->_basePath + bumpTexName;
            
            modelBase->GenerateTangents();
            modelBase->SetTexturePathBump(bumpTexPath);
        }
        
        models.push_back(modelBase);
        
        vertexNumLoaded += shape.mesh.indices.size();
        
        if (progressFunc)
            progressFunc(vertexNumLoaded / (float)vertexNumTotal);
    }
    
    return models;
}



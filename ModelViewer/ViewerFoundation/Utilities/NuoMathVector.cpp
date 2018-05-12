//
//  NuoMathVectorMac.cpp
//  ModelViewer
//
//  Created by Dong on 5/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include "NuoMathVector.h"



NuoMatrix<float, 4> NuoMatrixScale(const NuoVector<float, 3>& scale)
{
    glm::mat4x4 gmat = glm::scale(glm::mat4x4(1.0), glm::vec3(scale.x(), scale.y(), scale.z()));
    return ToMatrix(gmat);
}



NuoMatrix<float, 4> NuoMatrixRotationAround(NuoMatrix<float, 4> rotate, NuoVector<float, 3> center)
{
    NuoVectorFloat3 transVec1 = -center;
    NuoMatrix<float, 4> trans1 = NuoMatrixTranslation(transVec1);
    NuoVectorFloat3 transVec2 = center;
    NuoMatrix<float, 4> trans2 = NuoMatrixTranslation(transVec2);
    
    return (trans2 * (rotate * trans1));
}

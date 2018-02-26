//
//  NuoDirectoryUtils.hpp
//  ModelViewer
//
//  Created by Dong on 12/14/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoDirectoryUtils_hpp
#define NuoDirectoryUtils_hpp


#if __cplusplus
extern "C" {
#endif

const char* pathForDocument(void);
const char* pathFonfigureFile(void);
void clearCategoryInDocument(const char* category);

#if __cplusplus
}
#endif

#endif /* NuoDirectoryUtils_hpp */

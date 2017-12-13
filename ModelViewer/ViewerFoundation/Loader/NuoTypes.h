//
//  NuoTypes.hpp
//  ModelViewer
//
//  Created by middleware on 9/5/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef NuoTypes_hpp
#define NuoTypes_hpp


#if __cplusplus
extern "C" {
#endif

extern const unsigned int kSampleCount;
extern const unsigned int kInFlightBufferCount;


typedef void (^NuoProgressFunction)(float);
typedef void (^NuoProgressIndicatedFunction)(NuoProgressFunction);
typedef void (^NuoSimpleFunction)(void);
    
#if __cplusplus
}
#endif


#endif /* NuoTypes_hpp */

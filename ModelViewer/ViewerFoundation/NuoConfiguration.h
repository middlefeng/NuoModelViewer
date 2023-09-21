//
//  NuoConfiguration.h
//  ModelViewer
//
//  Created by Dong Feng on 9/19/23.
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#ifndef NuoConfiguration_h
#define NuoConfiguration_h


#include <TargetConditionals.h>


#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#else

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#endif


#if TARGET_OS_IPHONE

#define NuoColor UIColor

#define NuoBaseView UIView
#define NuoManagedResourceOption MTLResourceStorageModeShared

typedef uint8_t uint8;
typedef uint32_t uint32;

#else

#define NuoColor NSColor

#define NuoBaseView NSView
#define NuoManagedResourceOption MTLResourceStorageModeManaged

#endif



#endif /* NuoConfiguration_h */

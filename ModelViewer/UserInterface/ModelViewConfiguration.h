//
//  ModelViewConfiguration.h
//  ModelViewer
//
//  Created by Dong on 2/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface ModelViewConfiguration : NSObject

@property (nonatomic, assign) CGRect windowFrame;
@property (nonatomic, strong) NSString* deviceName;

- (instancetype)initWithFile:(NSString*)path;
- (void)save;

@end

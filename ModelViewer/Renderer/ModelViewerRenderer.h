#import "ModelView.h"



@class NuoMeshOption;



@interface ModelRenderer : NSObject <NuoMetalViewDelegate>


@property (nonatomic, assign) float zoom;


@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;

@property (nonatomic, assign) float transX;
@property (nonatomic, assign) float transY;

@property (nonatomic, strong) NuoMeshOption* modelOptions;


- (void)loadMesh:(NSString*)path;


@end

#import "ModelView.h"



@interface ModelRenderer : NSObject <NuoMetalViewDelegate>


@property (nonatomic, assign) float zoom;


@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;



- (void)loadMesh:(NSString*)path withType:(NSString*)type;
- (void)setType:(NSString*)type;

@end

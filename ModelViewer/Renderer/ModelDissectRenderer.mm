
#import "ModelDissectRenderer.h"

@interface ModelDissectRenderer ()

@end



@implementation ModelDissectRenderer
{
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        self.device = device;
        
        [self makeResources];
    }

    return self;
}


- (void)makeResources
{
    
}



@end

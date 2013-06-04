//
//  SKGView.h
//  SceneKitGeometry
//
//  Created by Steven Troughton-Smith on 04/06/2013.
//  Copyright (c) 2013 High Caffeine Content. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>

#import "OBLevelGenerator.h"

@interface SKGView : SCNView
{
	OBLevelGenerator *levelGenerator;
}
@end

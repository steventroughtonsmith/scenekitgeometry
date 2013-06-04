//
//  SKGView.m
//  SceneKitGeometry
//
//  Created by Steven Troughton-Smith on 04/06/2013.
//  Copyright (c) 2013 High Caffeine Content. All rights reserved.
//

#import "SKGView.h"

#define MAP_SIZE 32
#define HEIGHT_SCALE 32

typedef struct _RGBPixel
{
	int r;
	int g;
	int b;
} RGBPixel;

RGBPixel getpixel(char* data, NSInteger wid, NSInteger bpp, NSInteger x, NSInteger y)
{
    long ro,go,bo;
    RGBPixel p;
    ro = ((y*wid + x)*bpp);
    go = ((y*wid + x)*bpp)+bpp/3;
    bo = ((y*wid + x)*bpp)+bpp/3*2;
    p.r = *((data+ro/8));
    p.g = *((data+go/8));
    p.b = *((data+bo/8));
    return p;
}

@implementation SKGView

-(void)awakeFromNib
{
	SCNScene *scene = [SCNScene scene];
	[self buildScene:scene];

	self.scene = scene;
	
	scene.rootNode.rotation = SCNVector4Make(0, 0, 1, M_PI);
	scene.rootNode.position = SCNVector3Make(48, 0, 0);
}

-(void)buildScene:(SCNScene *)scene
{
	levelGenerator = [[OBLevelGenerator alloc] init];

	SCNNode *sword = [SCNNode nodeWithGeometry:[self createGeometryForImage:[NSImage imageNamed:@"sword.png"]]];
	sword.position = SCNVector3Make(0, 0, 0);
	[scene.rootNode addChildNode:sword];
	
	SCNNode *face = [SCNNode nodeWithGeometry:[self createGeometryForImage:[NSImage imageNamed:@"face.png"]]];
	face.position = SCNVector3Make(8, 0, 0);
	[scene.rootNode addChildNode:face];
	
	SCNNode *heart = [SCNNode nodeWithGeometry:[self createGeometryForImage:[NSImage imageNamed:@"heart.png"]]];
	heart.position = SCNVector3Make(16, 0, 0);
	[scene.rootNode addChildNode:heart];
	
	SCNNode *terrain = [SCNNode nodeWithGeometry:[self createGeometryForTerrain]];
	terrain.position = SCNVector3Make(40, 0, 0);
	[scene.rootNode addChildNode:terrain];
	
	/*  Lights!  */
	
	SCNNode *lightNode = [SCNNode node];
	
	SCNLight *light = [SCNLight light];
	light.type = SCNLightTypeOmni;
	light.color = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
	
	lightNode.light = light;
	
	
	lightNode.position = SCNVector3Make(32, 0, 32);
	
	lightNode.transform = CATransform3DRotate(lightNode.transform, M_PI_4, 0, 1,0);
	
	[scene.rootNode addChildNode:lightNode];

	
}

- (SCNGeometry *) createGeometryForTerrain
{
	NSMutableArray *sources = @[].mutableCopy;
	NSMutableArray *elements = @[].mutableCopy;
	
	CGFloat w = MAP_SIZE;
	CGFloat h = MAP_SIZE;
	
	CGFloat xOffset = -((CGFloat)w)/2.0;
	CGFloat yOffset = -((CGFloat)h)/2.0;
	
	NSInteger maxElements = (int)w * (int)h * 4;
	
	SCNVector3 vertices[maxElements];
	SCNVector3 normals[maxElements];
	CGPoint texCoords[maxElements];
	
	int vertexCount = 0;
	
	CGFloat scale = HEIGHT_SCALE;
	
	for (int y = h-1; y > -1; y--)
	{
		for (int x = 0; x < w; x++)
		{
			
			CGFloat factor = 0.5;
			
			CGFloat xf = ((CGFloat)x);
			CGFloat yf = ((CGFloat)y);
			
			CGFloat xt = xOffset+xf;
			CGFloat yt = yOffset+yf;
			
			
			CGFloat topLeftZ = [levelGenerator valueForX:x Y:y+1]/scale;
			
			CGFloat topRightZ = [levelGenerator valueForX:x+1 Y:y+1]/scale;
			
			CGFloat bottomLeftZ = [levelGenerator valueForX:x Y:y]/scale;
			
			CGFloat bottomRightZ = [levelGenerator valueForX:x+1 Y:y]/scale;
				
			//  -->
			// |
			// v
			
			SCNVector3 topLeft = SCNVector3Make(xt-factor, yt+factor, topLeftZ);
			SCNVector3 topRight = SCNVector3Make(xt+factor, yt+factor, topRightZ);
			
			SCNVector3 bottomLeft = SCNVector3Make(xt-factor, yt-factor, bottomLeftZ);
			SCNVector3 bottomRight = SCNVector3Make(xt+factor, yt-factor, bottomRightZ);
			
			vertices[vertexCount] = bottomLeft;
			vertices[vertexCount+1] = topLeft;
			vertices[vertexCount+2] = topRight;
			vertices[vertexCount+3] = bottomRight;
			
			texCoords[vertexCount] = CGPointMake(xf/w, yf/h);
			texCoords[vertexCount+1] = CGPointMake(xf/w, (yf+factor)/h);
			texCoords[vertexCount+2] = CGPointMake((xf+factor)/w, (yf+factor)/h);
			texCoords[vertexCount+3] = CGPointMake((xf+factor)/w, yf/h);
			
			vertexCount+=4;
		}
	}
	
	SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithVertices:vertices count:vertexCount];
	[sources addObject:source];
	
	NSMutableData *geometryData = [NSMutableData data];
	
	for (int g = 0; g < vertexCount; g+=4)
	{
		[geometryData appendBytes:(short[]){g, g+2, g+3, g, g+1, g+2} length:sizeof(short[6])];
	}
	
	[elements addObject:[SCNGeometryElement geometryElementWithData:geometryData
													  primitiveType:SCNGeometryPrimitiveTypeTriangles
						 
													 primitiveCount:vertexCount/2
													  bytesPerIndex:sizeof(short)]];
	
	int normalIndex = 0;
	
	for (normalIndex = 0; normalIndex < vertexCount; normalIndex++)
	{
		normals[normalIndex] = SCNVector3Make(0, 0, -1);
	}
	
	[sources addObject:[SCNGeometrySource geometrySourceWithNormals:normals count:normalIndex]];
	[sources addObject:[SCNGeometrySource geometrySourceWithTextureCoordinates:texCoords count:vertexCount]];
	
	SCNGeometry *geometry = [SCNGeometry geometryWithSources:sources elements:elements];
	
	SCNMaterial *material = [SCNMaterial material];
	
	material.diffuse.contents = [NSImage imageNamed:@"grass.png"];
	
	material.diffuse.magnificationFilter = SCNNoFiltering;
	material.diffuse.wrapS = SCNRepeat;
	material.diffuse.wrapT = SCNRepeat;
	
	material.diffuse.contentsTransform = CATransform3DMakeScale(MAP_SIZE*2, MAP_SIZE*2, 1);
	
	material.litPerPixel = YES;
	
	geometry.firstMaterial = material;
	geometry.firstMaterial.doubleSided = YES;
	
	return geometry;
}

- (SCNGeometry *) createGeometryForImage:(NSImage *)sourceImage
{
	[sourceImage setFlipped:NO];
	NSBitmapImageRep *rep = (NSBitmapImageRep *)[sourceImage representations][0] ;
	char *data = (char *)[rep bitmapData];
	
	NSInteger bpp = [rep bitsPerPixel];
	CGFloat w = [sourceImage size].width;
	CGFloat h = [sourceImage size].height;
	
	NSMutableArray *sources = @[].mutableCopy;
	NSMutableArray *elements = @[].mutableCopy;
	
	CGFloat xOffset = -((CGFloat)w)/2.0;
	CGFloat yOffset = -((CGFloat)h)/2.0;
	
	int quads = 0;
	
	NSInteger maxElements = (int)w * (int)h * 4;
	
	SCNVector3 vertices[maxElements];
	SCNVector3 normals[maxElements];
	CGPoint texCoords[maxElements];
	
	int vertexCount = 0;
	
	for (int y = h-1; y > -1; y--)
	{
		for (int x = 0; x < w; x++)
		{
			RGBPixel p = getpixel(data, w, bpp, x, y);
			
			int rgb = ((p.r << 16) & 0xff) | ((p.g << 8) & 0xff) | ((p.b << 0) & 0xff);
			
			if (rgb != 0xff)
			{
				CGFloat factor = 0.5;
				
				CGFloat xf = ((CGFloat)x);
				CGFloat yf = ((CGFloat)y);
				
				CGFloat xt = xOffset+xf;
				CGFloat yt = yOffset+yf;
				
				
				CGFloat zf = 0.0;
				
				SCNVector3 bottomLeft = SCNVector3Make(xt-factor, yt-factor, zf);
				SCNVector3 topLeft = SCNVector3Make(xt-factor, yt+factor, zf);
				SCNVector3 topRight = SCNVector3Make(xt+factor, yt+factor, zf);
				SCNVector3 bottomRight = SCNVector3Make(xt+factor, yt-factor, zf);
				
				vertices[vertexCount] = bottomLeft;
				vertices[vertexCount+1] = topLeft;
				vertices[vertexCount+2] = topRight;
				vertices[vertexCount+3] = bottomRight;
				
				texCoords[vertexCount] = CGPointMake(xf/w, yf/h);
				texCoords[vertexCount+1] = CGPointMake(xf/w, (yf+factor)/h);
				texCoords[vertexCount+2] = CGPointMake((xf+factor)/w, (yf+factor)/h);
				texCoords[vertexCount+3] = CGPointMake((xf+factor)/w, yf/h);
				
				quads++;
				vertexCount+=4;
				
			}
		}
	}
	
	SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithVertices:vertices count:vertexCount];
	[sources addObject:source];
	
	NSMutableData *geometryData = [NSMutableData data];
	
	for (int g = 0; g < vertexCount; g+=4)
	{
		[geometryData appendBytes:(short[]){g, g+2, g+3, g, g+1, g+2} length:sizeof(short[6])];
	}
	
	[elements addObject:[SCNGeometryElement geometryElementWithData:geometryData
													  primitiveType:SCNGeometryPrimitiveTypeTriangles
													 primitiveCount:vertexCount/2
													  bytesPerIndex:sizeof(short)]];
	
	int normalIndex = 0;
	
	for (normalIndex = 0; normalIndex < vertexCount; normalIndex++)
	{
		normals[normalIndex] = SCNVector3Make(0, 0, -1);
	}
	
	[sources addObject:[SCNGeometrySource geometrySourceWithNormals:normals count:normalIndex]];
	[sources addObject:[SCNGeometrySource geometrySourceWithTextureCoordinates:texCoords count:vertexCount]];
	
	SCNGeometry *geometry = [SCNGeometry geometryWithSources:sources elements:elements];
	
	SCNMaterial *material = [SCNMaterial material];
	material.diffuse.contents = sourceImage;
	
	material.diffuse.magnificationFilter = SCNNoFiltering;
	material.diffuse.wrapS = SCNClamp;
	material.diffuse.wrapT = SCNClamp;
	
	geometry.firstMaterial = material;
	geometry.firstMaterial.doubleSided = YES;
	
	return geometry;
}

@end

//
//  fanImageUploader.m
//  mFan
//
//  Created by yang shengfu on 11-7-27.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "fanImageUploader.h"
#import "mFanAppDelegate.h"
#import "MGTwitterEngine.h"
#include "util.h"

#define		JPEG_CONTENT_TYPE			@"image/jpeg"

@implementation ImageUploader

@synthesize connection;
@synthesize newURL;
@synthesize userData;
@synthesize delegate;
@synthesize contentType;
@synthesize imgData;


-(id)init
{
	self = [super init];
	if(self)
	{
		result = [[NSMutableData alloc] initWithCapacity:128];
		canceled = NO;
		scaleIfNeed = NO;
	}
	return self;
}


-(void)dealloc
{
	self.delegate = nil;
	self.connection = nil;
    self.newURL = nil;
	self.userData = nil;
	self.contentType = nil;
    self.imgData = nil;
	[result  release];
	[super dealloc];
}

- (void) postData:(NSData*)data
{
	if(canceled)
		return;
    
	if(!self.contentType)
	{
		NSLog(@"Content-Type header was not setted\n");
		return;
	}
    
    NSString *boundary = [NSString stringWithFormat:@"-----Boundaryfjhdsjhfjd--------"];

	//adding the body:
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    if (imgData) {
        imgData = nil;
    }
    imgData = postBody;
	
}

- (void) postData:(NSData*)data contentType:(NSString*)mediaContentType
{
	self.contentType = mediaContentType;
	[self postData:data];
}

- (void)postJPEGData:(NSData*)imageJPEGData delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	self.delegate = dlgt;
	self.userData = data;
	
	if(!imageJPEGData)
	{
		return;
	}
    
    
	[self postData:imageJPEGData contentType:JPEG_CONTENT_TYPE];
}

- (void)convertImageThreadAndStartUpload:(UIImage*)image
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSData* imData = UIImageJPEGRepresentation(image, 1.0f);
	self.contentType = JPEG_CONTENT_TYPE;
	[self performSelectorOnMainThread:@selector(postData:) withObject:imData waitUntilDone:NO];
    
	[pool release];
}

- (void)postImage:(UIImage*)image delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data
{
	delegate = [dlgt retain];
	self.userData = data;
    
	UIImage* modifiedImage = nil;
	
	BOOL needToResize;
	BOOL needToRotate;
	int newDimension = isImageNeedToConvert(image, &needToResize, &needToRotate);
	if(needToResize || needToRotate)		
		modifiedImage = imageScaledToSize(image, newDimension);
    
	[NSThread detachNewThreadSelector:@selector(convertImageThreadAndStartUpload:) toTarget:self withObject:modifiedImage ? modifiedImage : image];
}



- (void)cancel
{
	canceled = YES;
	if(connection)
	{
		[connection cancel];
		[mFanAppDelegate decreaseNetworkActivityIndicator];
		[self release];
	}
	[delegate uploadedImage:nil sender:self];
}

- (BOOL)canceled
{
	return canceled;
}



@end

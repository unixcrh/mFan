//
//  fanImageUploader.h
//  mFan
//
//  Created by yang shengfu on 11-7-27.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterConnectionProtocol.h"

@class ImageUploader;

@protocol ImageUploaderDelegate<NSObject>

- (void)uploadedImage:(NSString*)imageURL sender:(ImageUploader*)sender;

@end



@interface ImageUploader : NSObject <TwitterConnectionProtocol>
{
	NSMutableData*	result;
	id <ImageUploaderDelegate> delegate;
	id userData;
	NSURLConnection *connection;
    NSData *imgData;
	
	NSString*		newURL;
	BOOL			canceled;
	BOOL			scaleIfNeed;
	
	NSString*		contentType;

    
}

- (void)postJPEGData:(NSData*)imageJPEGData delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data;
- (void)postImage:(UIImage*)image delegate:(id <ImageUploaderDelegate>)dlgt userData:(id)data; // call postJPEGData:delegate:userData:
- (void)cancel;
- (BOOL)canceled;


@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSString* newURL;
@property (nonatomic, retain) NSString* contentType;
@property (nonatomic, retain) id userData;
@property (nonatomic, retain) NSData *imgData;
@property (nonatomic, retain) id <ImageUploaderDelegate> delegate;



@end

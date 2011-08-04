// Copyright (c) 2009 Imageshack Corp.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import "TwitEditorController.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"
#import "mFanAppDelegate.h"
#include "util.h"


#define PROCESSING_PHOTO_SHEET_TAG										3

#define K_UI_TYPE_IMAGE													@"public.image"
#define PHOTO_Q_SHEET_TAG												436





@implementation TwitEditorController

@synthesize progressSheet;
@synthesize connectionDelegate;
@synthesize _message;
@synthesize pickedPhoto;
@synthesize imageView;



- (void)setCharsCount
{
	charsCount.text = [NSString stringWithFormat:@"%d", MAX_SYMBOLS_COUNT_IN_TEXT_VIEW - [messageText.text length]];

}

- (void) setNavigatorButtons
{
    if (pickedPhoto) {
        CGRect newframe = CGRectMake(112, 0, 208, 200);
        messageText.frame = newframe;
    } else {
        CGRect oframe = CGRectMake(0, 0, 320, 200);
        messageText.frame = oframe;
    }
    
	if(self.navigationItem.leftBarButtonItem != cancelButton)
	{
		[[self navigationItem] setLeftBarButtonItem:cancelButton animated:YES];
		if([self.navigationController.viewControllers count] == 1)
			cancelButton.title = NSLocalizedString(@"清楚", @"");
		else
			cancelButton.title = NSLocalizedString(@"取消", @"");
	}	
		
	if([[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
	{
		if(self.navigationItem.rightBarButtonItem != sendButton)
			self.navigationItem.rightBarButtonItem = sendButton;
		
	}
	else
	{
		if(self.navigationItem.rightBarButtonItem)
			[[self navigationItem] setRightBarButtonItem:nil animated:YES];
	}

}

- (void)setMessageTextText:(NSString*)newText
{
	messageText.text = newText;
	[self setCharsCount];
	[self setNavigatorButtons];
}



- (void)initData
{
	_twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
	inTextEditingMode = NO;
    isRT = NO;
	messageTextWillIgnoreNextViewAppearing = NO;
	twitWasChangedManually = NO;
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self)
		[self initData];

	return self;
}

- (id)init
{
	return [self initWithNibName:@"TwitEditor" bundle:nil];
}

-(void)dismissProgressSheetIfExist
{
	if(self.progressSheet)
	{
		[self.progressSheet dismissWithClickedButtonIndex:0 animated:YES];
		self.progressSheet = nil;
	}
}

- (void)dealloc 
{
	while (_indicatorCount) 
		[self releaseActivityIndicator];

	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];

	[_indicator release];
    
    

	[defaultTintColor release];
    self.connectionDelegate = nil;
    self.pickedPhoto = nil;
	self._message = nil;
    self.imageView = nil;
	[self dismissProgressSheetIfExist];
    [super dealloc];
}



- (void)appWillTerminate:(NSNotification*)notification
{
	if(![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return;


}


- (void)setImageImage:(UIImage*)newImage
{
    
	imageView.image = newImage;
    imageView.hidden = NO;
	[self setNavigatorButtons];
}


- (void) setImage:(UIImage*)img
{
	self.pickedPhoto = img;
	UIImage* prevImage = nil;
	prevImage = img;
	[self setImageImage:prevImage];
}




#pragma mark ImagePicker method

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	messageTextWillIgnoreNextViewAppearing = YES;
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[messageText becomeFirstResponder];
	[self setNavigatorButtons];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishWithPickingPhoto:(UIImage *)img
{
    //img = nil;
    //url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"TestYfrog" ofType:@"mov"]];
    
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	twitWasChangedManually = YES;
	messageTextWillIgnoreNextViewAppearing = YES;
    
	BOOL startNewUpload = NO;
    
	if(pickedPhoto != img)
	{
		startNewUpload = YES;
		[self setImage:img];
	}
    
	[self setNavigatorButtons];
    
	if(startNewUpload)
	{
		if(self.connectionDelegate)
			[self.connectionDelegate cancel];
		self.connectionDelegate = nil;
	}
    
	[messageText becomeFirstResponder];
	
	if(img)
	{
		BOOL needToResize;
		BOOL needToRotate;
		isImageNeedToConvert(img, &needToResize, &needToRotate);
		if(needToResize || needToRotate)
		{
			self.progressSheet = ShowActionSheet(NSLocalizedString(@"优化图片...", @""), self, nil, self.tabBarController.view);
			self.progressSheet.tag = PROCESSING_PHOTO_SHEET_TAG;
		}
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	
	if([[info objectForKey:@"UIImagePickerControllerMediaType"] isEqualToString:K_UI_TYPE_IMAGE])
		[self imagePickerController:picker didFinishWithPickingPhoto:[info objectForKey:@"UIImagePickerControllerOriginalImage"]];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editInfo 
{
	[self imagePickerController:picker didFinishWithPickingPhoto:img];
}


- (void)imageViewTouched:(NSNotification*)notification
{
	if(pickedPhoto)
	{
		/*UIViewController *imgViewCtrl = [[ImageViewController alloc] initWithImage:pickedPhoto];
		[self.navigationController pushViewController:imgViewCtrl animated:YES];
		[imgViewCtrl release];*/
	}
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = NSLocalizedString(@"返回", @"");
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
	[temporaryBarButtonItem release];
	
	self.navigationItem.title = NSLocalizedString(@"写消息", @"");

	messageText.delegate = self;
    
    BOOL cameraEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	BOOL libraryEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	if(!cameraEnabled && !libraryEnabled)
		[pickImage setEnabled:NO];
	
    


	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
    imageView.hidden = YES;
	
	_indicatorCount = 0;
	_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

	[self setNavigatorButtons];
	
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	//[notificationCenter addObserver:self selector:@selector(imageViewTouched:) name:@"ImageViewTouched" object:image];
	[notificationCenter addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{	
	return MAX_SYMBOLS_COUNT_IN_TEXT_VIEW >= [textView.text length] - range.length + [text length];;
}


- (void)textViewDidChange:(UITextView *)textView
{
	twitWasChangedManually = YES;
	[self setCharsCount];
	[self setNavigatorButtons];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	inTextEditingMode = NO;
	[self setNavigatorButtons];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	inTextEditingMode = YES;
	[self setNavigatorButtons];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{

}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (IBAction)finishEditAction
{
	[messageText resignFirstResponder];
}


- (NSArray*)availableMediaTypes:(UIImagePickerControllerSourceType) pickerSourceType
{
	SEL selector = @selector(availableMediaTypesForSourceType:);
	NSMethodSignature *sig = [[UIImagePickerController class] methodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
	[invocation setTarget:[UIImagePickerController class]];
	[invocation setSelector:selector];
	[invocation setArgument:&pickerSourceType atIndex:2];
	[invocation invoke];
	NSArray *mediaTypes = nil;
	[invocation getReturnValue:&mediaTypes];
	return mediaTypes;
}

- (void)grabImage 
{
	BOOL imageAlreadyExists = [self mediaIsPicked];
	BOOL photoCameraEnabled = NO;
	BOOL photoLibraryEnabled = NO;
	BOOL movieCameraEnabled = NO;
    
    
	NSArray *mediaTypes = nil;
    
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
		photoLibraryEnabled = YES;
		if ([[UIImagePickerController class] respondsToSelector:@selector(availableMediaTypesForSourceType:)]) 
		{
			mediaTypes = [self availableMediaTypes:UIImagePickerControllerSourceTypePhotoLibrary];
			photoLibraryEnabled = [mediaTypes indexOfObject:K_UI_TYPE_IMAGE] != NSNotFound;
		}
        
	}
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		photoCameraEnabled = YES;
        
        
		if ([[UIImagePickerController class] respondsToSelector:@selector(availableMediaTypesForSourceType:)]) 
		{
			mediaTypes = [self availableMediaTypes:UIImagePickerControllerSourceTypeCamera];
			photoCameraEnabled = [mediaTypes indexOfObject:K_UI_TYPE_IMAGE] != NSNotFound;
		}
	}
    
	NSString *buttons[5] = {0};
	int i = 0;
	
	if(photoCameraEnabled)
		buttons[i++] = NSLocalizedString(@"拍照", @"");
	if(movieCameraEnabled)
		buttons[i++] = NSLocalizedString(@"录像", @"");
	if(photoLibraryEnabled)
		buttons[i++] = NSLocalizedString(@"本地图片", @"");
    //	if(movieLibraryEnabled)
    //		buttons[i++] = NSLocalizedString(@"Use video library", @"");
	if(imageAlreadyExists)
		buttons[i++] = NSLocalizedString(@"移除图片" , @"");
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self cancelButtonTitle:NSLocalizedString(@"取消", @"") destructiveButtonTitle:nil
													otherButtonTitles:buttons[0], buttons[1], buttons[2], buttons[3], buttons[4], nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	actionSheet.tag = PHOTO_Q_SHEET_TAG;
	[actionSheet showInView:self.tabBarController.view];
	[actionSheet release];
	
}

- (IBAction)attachImagesActions:(id)sender
{
	[self grabImage];
}



- (void)postImageAction 
{
	if(![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return;

	if([messageText.text length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"无法发送", @"") 
														message:NSLocalizedString(@"消息太长了，亲！", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"确定", @""), nil];
		[alert show];
		[alert release];
		return;
	}

	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	
	if(!login || !pass)
	{
		[LoginController showModal:self.navigationController];
		return;
	}
	
	NSString *messageBody = messageText.text;
    
    if ([self mediaIsPicked]) {
        
    
    
   
        NSData *imageData = UIImageJPEGRepresentation(pickedPhoto, 1.0f);
        [mFanAppDelegate increaseNetworkActivityIndicator];
        if(!self.progressSheet)
            self.progressSheet = ShowActionSheet(NSLocalizedString(@"正在发送图片...", @""), self, NSLocalizedString(@"取消", @""), self.tabBarController.view);
        
        
        NSString* mgTwitterConnectionID = nil;
        mgTwitterConnectionID = [_twitter sendUpdate:messageBody imageData:imageData inReplyTo:0];
        MGConnectionWrap * mgConnectionWrap = [[MGConnectionWrap alloc] initWithTwitter:_twitter connection:mgTwitterConnectionID delegate:self];
        self.connectionDelegate = mgConnectionWrap;
        [mgConnectionWrap release];
        
        
        return;
    
    }
    
	[mFanAppDelegate increaseNetworkActivityIndicator];
	if(!self.progressSheet)
		self.progressSheet = ShowActionSheet(NSLocalizedString(@"正在发送...", @""), self, NSLocalizedString(@"取消", @""), self.tabBarController.view);


	NSString* mgTwitterConnectionID = nil;
    
        if(_message)
            mgTwitterConnectionID = [_twitter sendUpdate:messageBody inReplyTo:[[_message objectForKey:@"id"] intValue]];
        else
            mgTwitterConnectionID = [_twitter sendUpdate:messageBody];
		
        MGConnectionWrap * mgConnectionWrap = [[MGConnectionWrap alloc] initWithTwitter:_twitter connection:mgTwitterConnectionID delegate:self];
        self.connectionDelegate = mgConnectionWrap;
        [mgConnectionWrap release];
    

	return;
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(actionSheet.tag == PHOTO_Q_SHEET_TAG)
	{
		if(buttonIndex == actionSheet.cancelButtonIndex)
			return;
		
		if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"移除图片", @"")])
		{
			twitWasChangedManually = YES;
			[self setImage:nil];
            imageView.hidden = YES;
			if(connectionDelegate)
				[connectionDelegate cancel];
			return;
		}
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"拍照", @"")])
		{
            UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
            imgPicker.delegate =self;
			imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
			if([imgPicker respondsToSelector:@selector(setMediaTypes:)])
				[imgPicker performSelector:@selector(setMediaTypes:) withObject:[NSArray arrayWithObject:K_UI_TYPE_IMAGE]];
			[self presentModalViewController:imgPicker animated:YES];
            [imgPicker release];
			return;
		}
        else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"本地图片", @"")])
		{
            UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
            imgPicker.delegate =self;

			imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
			if([imgPicker respondsToSelector:@selector(setMediaTypes:)])
				[imgPicker performSelector:@selector(setMediaTypes:) withObject:[self availableMediaTypes:UIImagePickerControllerSourceTypePhotoLibrary]];
			[self presentModalViewController:imgPicker animated:YES];
            [imgPicker release];
			return;
		}
		
	}
	else
	{
		[self dismissProgressSheetIfExist];
		if(connectionDelegate)
			[connectionDelegate cancel];
	}
}


- (void)setRetwit:(NSString*)body whose:(NSString*)username
{
    if (!isRT) {
        isRT = YES;
    }
	if(username)
		[self setMessageTextText:[NSString stringWithFormat:NSLocalizedString(@"转@%@ %@", @""), username, body]];
	else
		[self setMessageTextText:body];
}

- (void)setReplyToMessage:(NSDictionary*)message
{
    if (isRT) {
        isRT = NO;
    }
    
	self._message = message;
	NSString *replyToUser = [[message objectForKey:@"user"] objectForKey:@"screen_name"];
	[self setMessageTextText:[NSString stringWithFormat:@"@%@ ", replyToUser]];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if(!messageTextWillIgnoreNextViewAppearing)
	{
		[messageText becomeFirstResponder];
		inTextEditingMode = YES;
	}
	messageTextWillIgnoreNextViewAppearing = NO;
	[self setCharsCount];
	[self setNavigatorButtons];
}

- (void)popController
{
    [self setImage:nil];
    if (!imageView.hidden) {
        imageView.hidden = YES;
    }
	[self setMessageTextText:@""];
	[self.navigationController popToRootViewControllerAnimated:YES];
}



- (IBAction)postMessageSegmentedActions:(id)sender
{
    [self postImageAction];
}


#pragma mark MGTwitterEngineDelegate methods

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	[mFanAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
    if (!isRT) {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"消息发送成功" object: nil];
    } 
	self.connectionDelegate = nil;
	[self setMessageTextText:@""];
	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
	[self setNavigatorButtons];
	[self.navigationController popViewControllerAnimated:YES];
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
	[mFanAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
	self.connectionDelegate = nil;
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"失败!", @"") message:[error localizedDescription]
												   delegate:nil cancelButtonTitle:NSLocalizedString(@"确定", @"") otherButtonTitles: nil];
	[alert show];	
	[alert release];
}

- (void)MGConnectionCanceled:(NSString *)connectionIdentifier
{
	self.connectionDelegate = nil;
	[mFanAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
}

- (void)doCancel
{
	
	[self.navigationController popViewControllerAnimated:YES];
	if(connectionDelegate)
		[connectionDelegate cancel];
	[self setMessageTextText:@""];
	[messageText resignFirstResponder];
	[self setNavigatorButtons];
}

- (IBAction)cancel
{
	if(!twitWasChangedManually || ([[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0 ))
	{
		[self doCancel];
		return;
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"消息将不会发送" message:@"你的改动将会作废"
												   delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
	[alert show];
	[alert release];
		
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	
    [self doCancel];
	
}



- (void)retainActivityIndicator
{
	if(++_indicatorCount == 1)
	{
		[_indicator startAnimating];
	}
}

- (void)releaseActivityIndicator
{
	if(_indicatorCount > 0)
	{
		[_indicator stopAnimating];
		[_indicator removeFromSuperview];
		--_indicatorCount;
	}
}


- (BOOL)mediaIsPicked
{
    return pickedPhoto;
}





@end

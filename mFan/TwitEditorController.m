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







@implementation TwitEditorController

@synthesize progressSheet;
@synthesize connectionDelegate;
@synthesize _message;


- (void)setCharsCount
{
	charsCount.text = [NSString stringWithFormat:@"%d", MAX_SYMBOLS_COUNT_IN_TEXT_VIEW - [messageText.text length]];

}

- (void) setNavigatorButtons
{
	if(self.navigationItem.leftBarButtonItem != cancelButton)
	{
		[[self navigationItem] setLeftBarButtonItem:cancelButton animated:YES];
		if([self.navigationController.viewControllers count] == 1)
			cancelButton.title = NSLocalizedString(@"Clear", @"");
		else
			cancelButton.title = NSLocalizedString(@"Cancel", @"");
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
	self._message = nil;
	[self dismissProgressSheetIfExist];
    [super dealloc];
}



- (void)appWillTerminate:(NSNotification*)notification
{
	if(![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return;


	NSString *messageBody = messageText.text;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = NSLocalizedString(@"Back", @"");
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
	[temporaryBarButtonItem release];
	
	self.navigationItem.title = NSLocalizedString(@"New Tweet", @"");

	messageText.delegate = self;


	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
	
	_indicatorCount = 0;
	_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

	[self setNavigatorButtons];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
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


- (void)postImageAction 
{
	if(![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return;

	if([messageText.text length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not send message", @"") 
														message:NSLocalizedString(@"Cant to send too long message", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
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
    
	[mFanAppDelegate increaseNetworkActivityIndicator];
	if(!self.progressSheet)
		self.progressSheet = ShowActionSheet(NSLocalizedString(@"Send twit on Twitter", @""), self, NSLocalizedString(@"Cancel", @""), self.tabBarController.view);


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




- (void)setRetwit:(NSString*)body whose:(NSString*)username
{
	if(username)
		[self setMessageTextText:[NSString stringWithFormat:NSLocalizedString(@"转@%@ %@", @""), username, body]];
	else
		[self setMessageTextText:body];
}

- (void)setReplyToMessage:(NSDictionary*)message
{
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
	[self setImage:nil movie:nil];
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
	[[NSNotificationCenter defaultCenter] postNotificationName: @"TwittsUpdated" object: nil];
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
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed!", @"") message:[error localizedDescription]
												   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles: nil];
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
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"The message is not sent" message:@"Your changes will be lost"
												   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
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


@end

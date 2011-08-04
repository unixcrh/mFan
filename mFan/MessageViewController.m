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

#import "MessageViewController.h"
#import "ImageLoader.h"
#import "TwitEditorController.h"
#import "NewMessageController.h"
#import "WebViewController.h"
//#import "ImageViewController.h"
#import "UserInfo.h"
#import "mFanAppDelegate.h"
#include "util.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"


@implementation MessageViewController

@synthesize progressSheet;


- (id)initWithMessage:(NSDictionary*)message 
{
    if (self = [super initWithNibName:@"MessageView" bundle:nil]) 
	{
        _message = [message retain];
		imagesLinks = [[NSMutableDictionary alloc] initWithCapacity:1];
		connectionsDelegates = [[NSMutableArray alloc] initWithCapacity:1];
		suspendedOperation = noMVOperations;
		NSNumber *isDirectMessage = [_message objectForKey:@"DirectMessage"];
		_isDirectMessage = isDirectMessage && [isDirectMessage boolValue];
        _isMakeHTML = YES;
		_twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
    }
    return self;
}


- (IBAction)nameSelected 
{
    UserInfo *infoView = [[UserInfo alloc] initWithUserName:[[_message objectForKey:@"user"] objectForKey:@"id"]];
	[self.navigationController pushViewController:infoView animated:YES];
	[infoView release];
}

- (NSString *)makeHTMLMessage
{
    
	NSString *text = [_message objectForKey:@"text"];
	NSString *html;
	
    
	NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSString *line;
	_newLineCounter = [lines count];
	NSMutableArray *filteredLines = [[NSMutableArray alloc] initWithCapacity:_newLineCounter];
	NSEnumerator *en = [lines objectEnumerator];
	while(line = [en nextObject])
	{
		NSArray *words = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSEnumerator *en = [words objectEnumerator];
		NSString *word;
		NSMutableArray *filteredWords = [[NSMutableArray alloc] initWithCapacity:[words count]];
		while(word = [en nextObject])
		{
			if([word hasPrefix:@"http://"] || [word hasPrefix:@"https://"] || [word hasPrefix:@"www"])
			{
				if([word hasPrefix:@"www"])
					word = [@"http://" stringByAppendingString:word];

				NSString *yFrogURL = ValidateYFrogLink(word);

				if(yFrogURL == nil)
				{
					if([word hasSuffix:@".jpg"] ||
						[word hasSuffix:@".bmp"] ||
						[word hasSuffix:@".jpeg"] ||
						[word hasSuffix:@".tif"] ||
						[word hasSuffix:@".tiff"] ||
						[word hasSuffix:@".png"] ||
						[word hasSuffix:@".gif"]
						)
					{
						[imagesLinks setObject:[NSNull null] forKey:word];
					}
					word = [NSString  stringWithFormat:@" <a href=%@>%@</a> ", word, word];
				}
				else
				{
					[imagesLinks setObject:word forKey:word];
					word = [NSString  stringWithFormat:@"<br><a href=%@><img src=%@.th.jpg></a><br>", yFrogURL, yFrogURL];
					_newLineCounter += 6;
				}
			} else if ([word rangeOfString:@"http://"].location != NSNotFound)
            {
                NSRange r1 = [word rangeOfString:@"http://"];
                NSString *urlstr = [word substringFromIndex:r1.location];
                NSString *wordstr = [word substringToIndex:r1.location];
                
                word = [NSString stringWithFormat:@"%@<a href=%@>%@</a>",wordstr,urlstr,urlstr];
                
            }
			/*else if([word hasPrefix:@"@"] && [word length] > 1)
			{
                NSRange r = [word rangeOfString:@"："];
                if (r.location != NSNotFound) {
                    NSString* idword = [word substringToIndex:r.location - 1];
                    NSString* msword = [word substringFromIndex:r.location];
                    word = [NSString  stringWithFormat:@" <a href=user://%@>%@</a>%@ ",idword, idword,msword];
                } else {
                    word = [NSString  stringWithFormat:@" <a href=user://%@>%@</a> ", [word substringFromIndex:1], word];
                }
				
			} 
            else if ([word hasPrefix:@"转@"] && [word length] > 2)
            {
                NSRange r = [word rangeOfString:@"@"];
                NSString* idword = [word substringFromIndex:r.location + 1];
                word = [NSString stringWithFormat:@" 转<a href=user://%@>%@</a> ", idword,[word substringFromIndex:1]];
            }*/
			
			[filteredWords addObject:word];
		}
		
		[filteredLines addObject:[filteredWords componentsJoinedByString:@" "]];
		[filteredWords release];
	}
	
	NSString *htmlTemplate = @"<html></script></head><body style=\"width:%d; overflow:visible; padding:0; margin:0\"><big>%@</big></body></html>";
	html = [NSString stringWithFormat:htmlTemplate, (int)textField.frame.size.width - 10, [filteredLines componentsJoinedByString:@"<br>"]];
	[filteredLines release];
	return html;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	for (id view in textField.subviews) 
	{
		if ([view respondsToSelector:@selector(setAllowsRubberBanding:)]) 
			[view performSelector:@selector(setAllowsRubberBanding:) withObject:NO]; 
	}
	messageActionsSegmentedControl.frame = CGRectMake(0, 0, 190, 30);
	messageActionsSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	messageActionsSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	UIBarButtonItem *segmentBarItem = [[[UIBarButtonItem alloc] initWithCustomView:messageActionsSegmentedControl] autorelease];
	if(!_isDirectMessage || 
	   ![[MGTwitterEngine username] isEqualToString:[[_message objectForKey:@"sender"] objectForKey:@"screen_name"]])
			self.navigationItem.rightBarButtonItem = segmentBarItem;
	defaultTintColor = [messageActionsSegmentedControl.tintColor retain];	// keep track of this for later
	
	static NSDateFormatter *dateFormatter = nil;
	if (dateFormatter == nil) 
		dateFormatter = [[NSDateFormatter alloc] init];
	
	static NSCalendar *calendar;
	if(calendar == nil)
		calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
			
	NSDictionary *userData = [_message objectForKey:@"user"];
    
        
	//Set message date and time
	NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDate *createdAt = [_message objectForKey:@"created_at"];
	NSDateComponents *nowComponents = [calendar components:unitFlags fromDate:[NSDate date]];
	NSDateComponents *yesterdayComponents = [calendar components:unitFlags fromDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24]];
	NSDateComponents *createdAtComponents = [calendar components:unitFlags fromDate:createdAt];
	
	if([nowComponents year] == [createdAtComponents year] &&
		[nowComponents month] == [createdAtComponents month] &&
		[nowComponents day] == [createdAtComponents day])
	{
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateField.text = [dateFormatter stringFromDate:createdAt];
	}
	else if([yesterdayComponents year] == [createdAtComponents year] &&
		[yesterdayComponents month] == [createdAtComponents month] &&
		[yesterdayComponents day] == [createdAtComponents day])
	{
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateField.text = [NSString stringWithFormat:@"Yesterday, %@", [dateFormatter stringFromDate:createdAt]];
	}
	else
	{
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateField.text = [dateFormatter stringFromDate:createdAt];
	}
		
	if(!_isDirectMessage && [[MGTwitterEngine username] isEqualToString:[userData objectForKey:@"screen_name"]])
	{
		[deleteTwit setHidden:NO];
	}
		
	[avatarView setImage:[[ImageLoader sharedLoader] imageWithURL:[userData objectForKey:@"profile_image_url"]] forState:UIControlStateNormal];
	[nameField setTitle: [userData objectForKey:@"screen_name"] forState:UIControlStateNormal];
    
    
    if (_isDirectMessage)
    {
        [textField loadHTMLString:[self makeHTMLMessage] baseURL:nil];
        textField.scalesPageToFit = NO;
    } else {
        NSString *messageId = [_message objectForKey:@"id"];
        [mFanAppDelegate increaseNetworkActivityIndicator];
        [_twitter getMessageHtml:messageId];
    }
    
   
    
    
    
    
     

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent || self.navigationController.navigationBar.barStyle == UIBarStyleBlackOpaque) 
		messageActionsSegmentedControl.tintColor = [UIColor darkGrayColor];
	else
		messageActionsSegmentedControl.tintColor = defaultTintColor;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	textField.delegate = nil;
	if(textField.loading)
	{
		[textField stopLoading];
		[mFanAppDelegate decreaseNetworkActivityIndicator];
	}
	int connectionsCount = [_twitter numberOfConnections];
	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];
	while(connectionsCount-- > 0)
		[mFanAppDelegate decreaseNetworkActivityIndicator];

	[defaultTintColor release];
	[_message release];
	[imagesLinks release];

	[super dealloc];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[mFanAppDelegate increaseNetworkActivityIndicator];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if([[[request URL] absoluteString] isEqualToString:@"about:blank"])
		return YES;

	NSString *url = [[request URL] absoluteString];
	
    if([url hasPrefix:@"user://"])
	{
		NSString *user = [[url substringFromIndex:7] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
		UserInfo *infoView = [[UserInfo alloc] initWithUserName:user];
		[self.navigationController pushViewController:infoView animated:YES];
		[infoView release];
	}
	else
	{
		UIViewController *webViewCtrl = [[WebViewController alloc] initWithRequest:request];
		[self.navigationController pushViewController:webViewCtrl animated:YES];
		[webViewCtrl release];
	}
	
	return NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[mFanAppDelegate decreaseNetworkActivityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[mFanAppDelegate decreaseNetworkActivityIndicator];
}

- (void)implementOperationIfPossible
{
	if([connectionsDelegates count])
		return;
	if(suspendedOperation == noMVOperations)
		return;


	if(self.progressSheet)
	{
		[self.progressSheet dismissWithClickedButtonIndex:0 animated:YES];
		self.progressSheet = nil;
	}
	
	NSString* body = nil;
	
    if(suspendedOperation == retwit)
	{
        body = [_message objectForKey:@"text"];
		TwitEditorController *msgView = [[TwitEditorController alloc] init];
		[self.navigationController pushViewController:msgView animated:YES];
		[msgView setRetwit:body whose:[[_message objectForKey:@"user"] objectForKey:@"screen_name"]];
		[msgView release];
	}		
		
	suspendedOperation = noMVOperations;
}

- (void)copyImagesToYFrog
{
    [self implementOperationIfPossible];
}


- (void)reTwit
{
	suspendedOperation = retwit;
	[self copyImagesToYFrog];
}

- (void)reply 
{
	if(_isDirectMessage)
	{
		NewMessageController *msgView = [[NewMessageController alloc] initWithNibName:@"NewMessage" bundle:nil];
		[self.navigationController pushViewController:msgView animated:YES];
		[msgView setUser:[[_message objectForKey:@"sender"] objectForKey:@"screen_name"]];
		[msgView release];
	}
	else
	{
		TwitEditorController *msgView = [[TwitEditorController alloc] init];
		[self.navigationController pushViewController:msgView animated:YES];
		[msgView setReplyToMessage:_message];
		[msgView release];
	}
}


- (IBAction)segmentedActions:(id)sender
{

	NSString* login = [MGTwitterEngine username];
	NSString* pass = [MGTwitterEngine password];
	if(!login || !pass)
	{
		[LoginController showModal:self.navigationController];
		return;
	}

	switch([sender selectedSegmentIndex])
	{
		case 0:
			[self reTwit];
			break;
		case 1:
			[self reply];
			break;
		default:
			break;
	}
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	suspendedOperation = noMVOperations;
	id obj;
	NSEnumerator *enumerator = [connectionsDelegates objectEnumerator];
	while (obj = [enumerator nextObject]) 
		[obj cancel];
}

- (void)initTwitterEngine
{
	if(!_twitter)
		_twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
}

- (IBAction)deleteTwit
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"你真的想删除这个消息吗？ " message:@"这个操作无法撤销"
												   delegate:self cancelButtonTitle:@"取消删除" otherButtonTitles:@"确认删除", nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex > 0)
	{
		[mFanAppDelegate increaseNetworkActivityIndicator];
		[_twitter deleteUpdate:[_message objectForKey:@"id"]];
	}
}

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    if (!_isMakeHTML){
        [[NSNotificationCenter defaultCenter] postNotificationName: @"消息发送成功" object: nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    
    [mFanAppDelegate decreaseNetworkActivityIndicator];
    
    if (_isDirectMessage) {
        _isDirectMessage = NO;
    }
	
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
	[mFanAppDelegate decreaseNetworkActivityIndicator];
	
	if(self.tabBarController.selectedViewController == self.navigationController && [error code] == 401)
		[LoginController showModal:self.navigationController];
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
    NSDictionary *msgData = [statuses objectAtIndex:0];
    NSString *str = [msgData objectForKey:@"text"];
    NSMutableString *info = [NSMutableString stringWithCapacity:256];
    [info appendFormat:@"<html></script></head><body style=\"width:%d; overflow:visible; padding:0; margin:0\"><big>",(int)textField.frame.size.width - 10];
    [info appendString:str];
    [info appendString:@"<br>"];
    [info appendString:@"</big></body></html>"];
    
    [textField loadHTMLString:info baseURL:nil];
    textField.scalesPageToFit = NO;
    
}

		
	



@end

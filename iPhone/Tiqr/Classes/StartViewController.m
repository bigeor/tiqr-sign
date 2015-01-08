/*
 * Copyright (c) 2010-2011 SURFnet bv
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of SURFnet bv nor the names of its contributors 
 *    may be used to endorse or promote products derived from this 
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "StartViewController.h"
#import "StartViewController-Protected.h"
#import "ScanViewController.h"
#import "IdentityListViewController.h"
#import "FooterController.h"
#import "ErrorController.h"
#import "Identity+Utils.h"
#import "SecKeyWrapper+Utils.h"

@interface StartViewController () <UIWebViewDelegate>

@property (nonatomic, retain) UIBarButtonItem *identitiesButtonItem;
@property (nonatomic, retain) FooterController *footerController;
@property (nonatomic, retain) ErrorController *errorController;

@end

@implementation StartViewController

@synthesize webView=webView_;
@synthesize managedObjectContext=managedObjectContext_;
@synthesize identitiesButtonItem=identitiesButtonItem_;
@synthesize footerController=footerController_;
@synthesize errorController=errorController_;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"start_button", @"Start button title") style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];                
    NSString *scanButtonTitle = NSLocalizedString(@"scan_button", @"Scan button title");
    UIBarButtonItem *scanButtonItem = [[UIBarButtonItem alloc] initWithTitle:scanButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(scan)];
    self.navigationItem.leftBarButtonItem = scanButtonItem;
    [scanButtonItem release];
    
    UIBarButtonItem *identitiesButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"identities"] style:UIBarButtonItemStyleBordered target:self action:@selector(listIdentities)];
    self.navigationItem.rightBarButtonItem = identitiesButtonItem;
    self.identitiesButtonItem = identitiesButtonItem;
    [identitiesButtonItem release];    
    
    self.footerController = [[[FooterController alloc] init] autorelease];
    [self.footerController addToView:self.view];
    
    self.errorController = [[[ErrorController alloc] init] autorelease];  
    [self.errorController addToView:self.view];
    
    //self.webView.backgroundColor = [UIColor greenColor];
    self.webView.opaque = NO;       
    self.webView.delegate = self;    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.errorController.view.hidden = YES;
    self.webView.frame = CGRectMake(0.0, 0.0, self.webView.frame.size.width, self.view.frame.size.height - self.footerController.view.frame.size.height);    
    
    NSString *content = @"";
    if ([Identity allIdentitiesBlockedInManagedObjectContext:self.managedObjectContext]) {
        self.webView.frame = CGRectMake(0.0, self.errorController.view.frame.size.height, self.webView.frame.size.width, self.view.frame.size.height - self.errorController.view.frame.size.height - self.footerController.view.frame.size.height);
        self.errorController.view.hidden = NO;
        self.title = NSLocalizedString(@"main_title_blocked", @"Blocked navigation title");
        self.navigationItem.rightBarButtonItem = self.identitiesButtonItem;
        self.errorController.title = NSLocalizedString(@"error_auth_account_blocked_title", @"Accounts blocked error title");
        self.errorController.message = NSLocalizedString(@"to_many_attempts", @"Accounts blocked error message");        
        content = NSLocalizedString(@"main_text_blocked", @"");                
    } else if ([Identity countInManagedObjectContext:self.managedObjectContext] > 0) {
        self.title = NSLocalizedString(@"main_title_instructions", @"Instructions navigation title");
        self.navigationItem.rightBarButtonItem = self.identitiesButtonItem;
        content = NSLocalizedString(@"main_text_instructions", @"");        
    } else {
        self.title = NSLocalizedString(@"main_title_welcome", @"Welcome navigation title");
        self.navigationItem.rightBarButtonItem = nil;
        content = NSLocalizedString(@"main_text_welcome", @"");
    }
    
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"start" withExtension:@"html"];
    NSString *html = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:nil];
    html = [NSString stringWithFormat:html, content];
    [self.webView loadHTMLString:html baseURL:nil];

    // TODO REMOVE !!
    //[SecKeyWrapper resetKeychain];
    //[SecKeyWrapper printKeychain];
}



- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[[UIApplication sharedApplication] openURL:[request URL]];
		return NO;
	} else {
		return YES;
	}
}

- (void)scan {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
    if ([Identity countInManagedObjectContext:self.managedObjectContext] > 0 &&
        [defaults objectForKey:@"show_instructions_preference"] == nil) {
		NSString *message = NSLocalizedString(@"show_instructions_preference_message", @"Do you want to see these instructions when you start the application in the future? You can always open the instructions from the Scan window or change this behavior in Settings.");		
		NSString *yesTitle = NSLocalizedString(@"yes_button", @"Yes button title");
		NSString *noTitle = NSLocalizedString(@"no_button", @"No button title");		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:nil otherButtonTitles:yesTitle, noTitle, nil];
		[alertView show];
		[alertView release];
	} else {
		ScanViewController *viewController = [[ScanViewController alloc] init];
        viewController.managedObjectContext = self.managedObjectContext;
		[self.navigationController pushViewController:viewController animated:YES];	
        [viewController release];
	}
}

- (void)listIdentities {
    IdentityListViewController *viewController = [[IdentityListViewController alloc] init];
    viewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	BOOL showInstructions = buttonIndex == 0;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:showInstructions forKey:@"show_instructions_preference"];
	
    ScanViewController *viewController = [[ScanViewController alloc] init];
    viewController.managedObjectContext = self.managedObjectContext;
    [self.navigationController pushViewController:viewController animated:YES];	
    [viewController release];
}

- (void)resetOutlets {
    self.webView = nil;
}

- (void)viewDidUnload {
    [self resetOutlets];
    
    [self.footerController.view removeFromSuperview];
    self.footerController = nil;
    
    [self.errorController.view removeFromSuperview];
    self.errorController = nil;
    
    [super viewDidUnload];
}

- (void)dealloc {
    [self resetOutlets];
    
    self.managedObjectContext = nil;
    self.identitiesButtonItem = nil;
    self.footerController = nil;
    self.errorController = nil;
    
    [super dealloc];
}

@end
//
//  DataToSignViewController.m
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/17/14.
//  Copyright (c) 2014 Egeniq. All rights reserved.
//

#import "DataToSignViewController.h"
#import "SignResultViewController.h"
#import "MBProgressHUD.h"
#import "TiqrAppDelegate.h"
#import "SignChallenge.h"
#import "DecryptChallenge.h"
#import "UIColor+TiQR.h"

@interface DataToSignViewController ()
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;
@property (retain, nonatomic) IBOutlet UIButton *okButton;
@property (retain, nonatomic) IBOutlet UIWebView *dataView;
@property (nonatomic, retain) CryptoChallenge *challenge;
@end

@implementation DataToSignViewController

- (id)initWithSignChallenge:(CryptoChallenge *)challenge{
    self = [super initWithNibName:@"DataToSignViewController" bundle:nil];
	if (self != nil) {
		self.challenge = challenge;
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self.challenge isKindOfClass:[SignChallenge class]]){
        [self.okButton setTitle:NSLocalizedString(@"sign_button", @"sign") forState:UIControlStateNormal];
    } else if ([self.challenge isKindOfClass:[DecryptChallenge class]]){
        [self.okButton setTitle:NSLocalizedString(@"decrypt_button", @"decrypt") forState:UIControlStateNormal];
    }
    
    
    self.okButton.layer.borderWidth = 1;
    self.okButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.okButton.layer.cornerRadius = 4;
    
    [self.cancelButton setTitle:NSLocalizedString(@"cancel_button", @"Cancel") forState:UIControlStateNormal];
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.cancelButton.layer.cornerRadius = 4;
    
    [self.dataView loadHTMLString:self.challenge.inputText baseURL:nil];
}
- (IBAction)didTapSignButton:(id)sender {
    SignResultViewController *c = [[SignResultViewController alloc] initWithSignChallenge:self.challenge];
    [self.navigationController pushViewController:c animated:YES];
    [c release];
}

- (IBAction)didTapCancelButton:(id)sender {
    CryptoConfirmationRequest *request = [[CryptoConfirmationRequest alloc] initWithChallenge:self.challenge response:nil];
    request.delegate = self;
    [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];    
    [request sendCancel];
}

-(void)tiqrRequestDidFinish:(CryptoConfirmationRequest *)request{
    [self operationCancelled];
}

-(void)tiqrRequest:(CryptoConfirmationRequest *)request didFailWithError:(NSError *)error{
    [self operationCancelled];
}

-(void)operationCancelled{
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    [(TiqrAppDelegate *)[UIApplication sharedApplication].delegate popToStartViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_dataView release];
    [_cancelButton release];
    [_okButton release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setDataView:nil];
    [self setCancelButton:nil];
    [self setOkButton:nil];
    [super viewDidUnload];
}
@end

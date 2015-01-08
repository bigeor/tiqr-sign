//
//  SignConfirmViewController-Protected.h
//  Tiqr
//
//  Created by Fabrice Dewasmes on 7/16/14.
//  Copyright (c) 2014 Neopixl. All rights reserved.
//
#import "SignConfirmViewController.h"

@interface SignConfirmViewController ()

@property (nonatomic, retain) IBOutlet UIImageView *identityProviderLogoImageView;
@property (nonatomic, retain) IBOutlet UILabel *identityDisplayNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *identityProviderDisplayNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *serviceProviderDisplayNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *serviceProviderIdentifierLabel;
@property (retain, nonatomic) IBOutlet UILabel *signConfirmLabel;
@property (retain, nonatomic) IBOutlet UILabel *signAsLabel;
@property (retain, nonatomic) IBOutlet UILabel *toLabel;
@property (retain, nonatomic) IBOutlet UIButton *okButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;


- (IBAction)ok;
- (IBAction)cancel:(id)sender;


@end
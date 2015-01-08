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

#import "IdentityEditViewController.h"
#import "IdentityEditViewController-Protected.h"
#import "Identity.h"
#import "IdentityProvider.h"
#import "SecretStore.h"
#import "UIColor+TiQR.h"

@interface IdentityEditViewController ()

@property (nonatomic, retain) Identity *identity;
@property (nonatomic, retain) IBOutlet UIButton *deleteButton;

@end

@implementation IdentityEditViewController

@synthesize identity=identity_;
@synthesize identityProviderLogoImageView=identityProviderLogoImageView_;
@synthesize identityProviderIdentifierLabel=identityProviderIdentifierLabel_;
@synthesize identityProviderDisplayNameLabel=identityProviderDisplayNameLabel_;
@synthesize blockedWarningLabel=blockedWarningLabel_;
@synthesize tableView=tableView_;
@synthesize deleteButton=deleteButton_;


- (id)initWithIdentity:(Identity *)identity {
    self = [super initWithNibName:@"IdentityEditView" bundle:nil];
    if (self != nil) {
        self.identity = identity;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [tableView_ setTintColor:[UIColor defaultTintColor]];
    
    [self.deleteButton setTitle:NSLocalizedString(@"delete_button", @"Delete") forState:UIControlStateNormal];
    self.deleteButton.layer.borderWidth = 1;
    self.deleteButton.layer.borderColor = [UIColor defaultTintColor].CGColor;
    self.deleteButton.layer.cornerRadius = 4;
    
    self.blockedWarningLabel.text = NSLocalizedString(@"identity_blocked_message", @"Warning this account is blocked and needs to be reactivated.");
    
    self.title = NSLocalizedString(@"account_details_title", @"Account details navigation title");
    
    self.identityProviderLogoImageView.image = [UIImage imageWithData:self.identity.identityProvider.logo];
    self.identityProviderIdentifierLabel.text = self.identity.identityProvider.identifier;
    self.identityProviderDisplayNameLabel.text = self.identity.identityProvider.displayName;    
    
    if ([self.identity.blocked boolValue]) {
        self.blockedWarningLabel.hidden = NO;
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        cell.detailTextLabel.minimumFontSize = 12.0;
        cell.detailTextLabel.minimumScaleFactor = 0.4f;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"full_name", @"Username label");
        cell.detailTextLabel.text = self.identity.displayName;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"id", @"User ID label");
        cell.detailTextLabel.text = self.identity.identifier;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"information", @"Info label");
        cell.detailTextLabel.text = self.identity.identityProvider.infoUrl;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"authenticationUrl", @"Authentication URL label");
        if (self.identity.identityProvider.authenticationUrl != nil && self.identity.identityProvider.authenticationUrl.length > 0){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"signatureUrl", @"Signature URL label");
        if (self.identity.identityProvider.signatureUrl != nil && self.identity.identityProvider.signatureUrl.length > 0){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

        
    } else if (indexPath.row == 5) {
        cell.textLabel.text = NSLocalizedString(@"decryptionUrl", @"Decryption URL label");
        if (self.identity.identityProvider.decryptionUrl != nil && self.identity.identityProvider.decryptionUrl.length > 0){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.identity.identityProvider.infoUrl]];
    }
}

- (void)deleteIdentity {
    NSManagedObjectContext *context = self.identity.managedObjectContext;
    
    IdentityProvider *identityProvider = self.identity.identityProvider;
    
    SecretStore *store = nil;       
    if (identityProvider != nil) {
        store = [SecretStore secretStoreForIdentity:self.identity.identifier identityProvider:identityProvider.identifier];		
		
        [identityProvider removeIdentitiesObject:self.identity];
        [context deleteObject:self.identity];
        if ([identityProvider.identities count] == 0) {
            [context deleteObject:identityProvider];
        }
    } else {
        [context deleteObject:self.identity];            
    }
    
    NSError *error = nil;
    if ([context save:&error]) {
        if (store != nil) {
            [store deleteFromKeychain];
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSLog(@"Unexpected error: %@", error);
		NSString *title = NSLocalizedString(@"error", "Alert title for error");		
		NSString *message = NSLocalizedString(@"error_auth_unknown_error", "Unexpected error message");		        
		NSString *okTitle = NSLocalizedString(@"ok_button", "OK button title");		
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:okTitle otherButtonTitles:nil] autorelease];
		[alertView show];
        [alertView release];
    }
}

- (void)resetOutlets {
    self.identityProviderLogoImageView = nil;
    self.identityProviderIdentifierLabel = nil;    
    self.identityProviderDisplayNameLabel = nil;
    self.blockedWarningLabel = nil;
    self.tableView = nil;
    self.deleteButton = nil;
}

- (void)viewDidUnload {
    [self resetOutlets];
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [self resetOutlets];
    self.identity = nil;
    [tableView_ release];
    [super dealloc];
}

@end
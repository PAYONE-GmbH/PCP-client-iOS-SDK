//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

#import "ViewController.h"
#import "PCPClientObjcDemo-Swift.h"
@import PCPClient;
@import PCPClientBridge;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *fingerprintTokenLabel;
@property (nonatomic, strong) FingerprintTokenizerWrapper *tokenizerWrapper;
@property (weak, nonatomic) IBOutlet UILabel *applePayResultLabel;
@property (weak, nonatomic) IBOutlet UILabel *creditcardTokenizerResponseLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.applePayResultLabel.text = @"Apple Pay Beispiele – keine echte Zahlung";
    self.applePayResultLabel.numberOfLines = 0;
    UIStackView *menu = [[UIStackView alloc] init];
    menu.axis = UILayoutConstraintAxisVertical;
    menu.spacing = 8;
    menu.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:menu];
    [NSLayoutConstraint activateConstraints:@[
        [menu.leadingAnchor constraintEqualToAnchor:self.fingerprintTokenLabel.leadingAnchor],
        [menu.trailingAnchor constraintEqualToAnchor:self.fingerprintTokenLabel.trailingAnchor],
        [menu.bottomAnchor constraintEqualToAnchor:self.applePayResultLabel.topAnchor constant:-8]
    ]];
    UIButton *standard = [UIButton buttonWithType:UIButtonTypeSystem];
    [standard setTitle:@"Go to Apple Pay Standard Checkout" forState:UIControlStateNormal];
    [standard addTarget:self action:@selector(showStandardApplePay:) forControlEvents:UIControlEventTouchUpInside];
    [menu addArrangedSubview:standard];
    UIButton *express = [UIButton buttonWithType:UIButtonTypeSystem];
    [express setTitle:@"Go to Apple Pay Express Checkout" forState:UIControlStateNormal];
    [express addTarget:self action:@selector(showExpressApplePay:) forControlEvents:UIControlEventTouchUpInside];
    [menu addArrangedSubview:express];
}

- (IBAction)startFingerprintTokenizer:(id)sender {
    self.tokenizerWrapper = [[FingerprintTokenizerWrapper alloc] initWithPaylaPartnerId:@"YOUR_PARTNER_ID" partnerMerchantId:@"YOUR_MERCHANT_ID" environment:PCPEnvironmentTest sessionId:nil];
    [self.tokenizerWrapper getSnippetTokenWithSuccess:^(NSString *token) {
        NSLog(@"token: %@", token);
        self.fingerprintTokenLabel.text = token;
    } failure:^(enum FingerprintErrorWrapper error) {
        self.fingerprintTokenLabel.text = [NSString stringWithFormat:@"%ld", (long)error];
    }];
}

- (void)showStandardApplePay:(id)sender {
    [self showApplePayWithStandardOrder:YES];
}

- (void)showExpressApplePay:(id)sender {
    [self showApplePayWithStandardOrder:NO];
}

- (void)showApplePayWithStandardOrder:(BOOL)standard {
    NSError *error = nil;
    ApplePayDemoConfiguration *configuration = [ApplePayDemoConfiguration loadFromBundle:NSBundle.mainBundle error:&error];
    ApplePayDemoStandardOrder *order = standard ? [ApplePayDemoStandardOrder loadFromBundle:NSBundle.mainBundle error:&error] : nil;
    if (!configuration || (standard && !order)) {
        self.applePayResultLabel.text = error.localizedDescription;
        return;
    }
    ApplePayDemoViewController *controller = [[ApplePayDemoViewController alloc] initWithConfiguration:configuration standardOrder:order];
    [self.navigationController pushViewController:controller animated:YES];
}
- (IBAction)startCreditcardTokenizer:(id)sender {
    NSError *error = nil;
    CreditcardTokenizerDemoConfiguration *configuration = [CreditcardTokenizerDemoConfiguration loadFromBundle:NSBundle.mainBundle error:&error];
    if (!configuration) {
        self.creditcardTokenizerResponseLabel.text = error.localizedDescription;
        return;
    }
    CreditcardTokenizerDemoViewController *controller = [[CreditcardTokenizerDemoViewController alloc] initWithConfiguration:configuration];
    [self.navigationController pushViewController:controller animated:YES];
}

@end

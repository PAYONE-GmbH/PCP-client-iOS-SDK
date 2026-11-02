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
@property (nonatomic, strong) ApplePayDemoCheckout *applePayCheckout;
@property (nonatomic, strong) PKPaymentButton *applePayButton;
@property (weak, nonatomic) IBOutlet UILabel *applePayResultLabel;
@property (weak, nonatomic) IBOutlet UILabel *creditcardTokenizerResponseLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.applePayResultLabel.text = @"Apple Pay Express Demo – keine echte Zahlung";
    self.applePayResultLabel.numberOfLines = 0;
    NSError *configurationError = nil;
    ApplePayDemoConfiguration *configuration = [ApplePayDemoConfiguration loadFromBundle:NSBundle.mainBundle error:&configurationError];
    if (configuration) {
        self.applePayCheckout = [[ApplePayDemoCheckout alloc] initWithConfiguration:configuration];
    } else {
        self.applePayResultLabel.text = configurationError.localizedDescription;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!self.applePayButton && [self.applePayCheckout supportsApplePay]) {
        PKPaymentButton *applePayButton = [PKPaymentButton buttonWithType: PKPaymentButtonTypePlain style:PKPaymentButtonStyleBlack];
        applePayButton.translatesAutoresizingMaskIntoConstraints = false;
        [self.view addSubview:applePayButton];
        self.applePayButton = applePayButton;

        [applePayButton.leadingAnchor constraintEqualToAnchor:self.fingerprintTokenLabel.leadingAnchor].active = true;
        [applePayButton.trailingAnchor constraintEqualToAnchor:self.fingerprintTokenLabel.trailingAnchor].active = true;
        [applePayButton.bottomAnchor constraintEqualToAnchor:self.applePayResultLabel.topAnchor constant:-8.0].active = true;

        [applePayButton addTarget:self action:@selector(startApplePay:) forControlEvents:UIControlEventTouchUpInside];
    }
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

-(void)startApplePay:(id)sender {
    self.applePayButton.enabled = NO;
    self.applePayResultLabel.text = @"Demo-Versandangebot wird geladen …";
    __weak typeof(self) weakSelf = self;
    [self.applePayCheckout startWithCompletion:^(NSString *result) {
        weakSelf.applePayResultLabel.text = result;
        weakSelf.applePayButton.enabled = YES;
    }];
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

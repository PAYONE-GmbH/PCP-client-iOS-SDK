//
// This file is part of the PCPClient iOS SDK.
// Copyright © 2024 PAYONE GmbH. All rights reserved.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

#import "ViewController.h"
@import PCPClient;
@import PCPClientBridge;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *fingerprintTokenLabel;
@property (nonatomic, strong) FingerprintTokenizerWrapper *tokenizerWrapper;
@property (nonatomic, strong) ApplePayHandler *applePayHandler;
@property (weak, nonatomic) IBOutlet UILabel *applePayResultLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *url = [[NSURL alloc] initWithString:@"YOUR_URL"];
    self.applePayHandler = [[ApplePayHandler alloc] initWithProcessPaymentServerUrl:url];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([self.applePayHandler supportsApplePay]) {
        PKPaymentButton *applePayButton = [PKPaymentButton buttonWithType: PKPaymentButtonTypePlain style:PKPaymentButtonStyleBlack];
        applePayButton.translatesAutoresizingMaskIntoConstraints = false;
        [self.view addSubview:applePayButton];

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
    PKPaymentRequest *request = [self makeRequest];
    self.applePayHandler.onShippingMethodDidChange = ^PKPaymentRequestShippingMethodUpdate * _Nonnull(PKShippingMethod *shippingMethod) {
        NSMutableArray<PKPaymentSummaryItem *> *currentPaymentSummaryItems = [NSMutableArray array];
        [currentPaymentSummaryItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:@"Item 1" amount:[NSDecimalNumber decimalNumberWithString:@"33.99"]]];
        [currentPaymentSummaryItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:@"Item 2" amount:[NSDecimalNumber decimalNumberWithString:@"2.99"]]];

        if ([shippingMethod.identifier isEqualToString:@"free"]) {
            [currentPaymentSummaryItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:@"Free Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]]];
            [currentPaymentSummaryItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:@"Total" amount:[NSDecimalNumber decimalNumberWithString:@"36.98"]]];
        } else if ([shippingMethod.identifier isEqualToString:@"express"]) {
            [currentPaymentSummaryItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:@"Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]]];
            [currentPaymentSummaryItems addObject:[PKPaymentSummaryItem summaryItemWithLabel:@"Total" amount:[NSDecimalNumber decimalNumberWithString:@"46.98"]]];
        }

        return [[PKPaymentRequestShippingMethodUpdate alloc] initWithPaymentSummaryItems:currentPaymentSummaryItems];
    };
    [self.applePayHandler startAndPresentPaymentWithRequest:request on:self onDidSelectPaymentMethod:^PKPaymentRequestPaymentMethodUpdate * _Nonnull(PKPaymentMethod *paymentMethod) {
        return [[PKPaymentRequestPaymentMethodUpdate alloc] initWithPaymentSummaryItems:request.paymentSummaryItems];
    } completion:^(BOOL success) {
        if (success) {
            NSLog(@"We are here");
            self.applePayResultLabel.text = @"Success";
        } else {
            NSLog(@"We are there");
            self.applePayResultLabel.text = @"Failed";
        }
    }];
}

-(PKPaymentRequest *)makeRequest {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"YOUR_MERCHANT_IDENTIFIER";
    request.supportedNetworks = @[PKPaymentNetworkVisa, PKPaymentNetworkGirocard];
    request.merchantCapabilities = PKMerchantCapability3DS;
    request.countryCode = @"DE";
    request.currencyCode = @"EUR";

    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem summaryItemWithLabel:@"Item 1" amount:[NSDecimalNumber decimalNumberWithString:@"33.99"]];
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem summaryItemWithLabel:@"Item 2" amount:[NSDecimalNumber decimalNumberWithString:@"2.99"]];
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"Total" amount:[NSDecimalNumber decimalNumberWithString:@"36.98"]];
    request.paymentSummaryItems = @[item1, item2, total];

    request.requiredBillingContactFields = [NSSet setWithArray:@[PKContactFieldPostalAddress, PKContactFieldEmailAddress, PKContactFieldName]];
    request.requiredShippingContactFields = [NSSet setWithArray:@[PKContactFieldPostalAddress, PKContactFieldEmailAddress, PKContactFieldName]];

    PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"Free Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]];
    freeShipping.identifier = @"free";
    freeShipping.detail = @"Arrives in 1-3 business days.";

    PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    expressShipping.identifier = @"express";
    expressShipping.detail = @"Arrives tomorrow";

    request.shippingMethods = @[freeShipping, expressShipping];

    request.applicationData = [NSData data];

    return request;
}

@end

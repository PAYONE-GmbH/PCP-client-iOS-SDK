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
@property (weak, nonatomic) IBOutlet UILabel *creditcardTokenizerResponseLabel;

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
    [self.applePayHandler startPaymentWithRequest:request onDidSelectPaymentMethod:^PKPaymentRequestPaymentMethodUpdate * _Nonnull(PKPaymentMethod *paymentMethod) {
        return [[PKPaymentRequestPaymentMethodUpdate alloc] initWithPaymentSummaryItems:request.paymentSummaryItems];
    } completion:^(BOOL success) {
        if (success) {
            self.applePayResultLabel.text = @"Success";
        } else {
            self.applePayResultLabel.text = @"Failed";
        }
    }];
}
- (IBAction)startCreditcardTokenizer:(id)sender {
    NSURL *url = [[NSURL alloc] initWithString:@"YOUR_URL"];
    CCTokenizerRequest *request = [
        [CCTokenizerRequest alloc]
        initWithMid:@"YOUR_MID"
        aid:@"YOUR_AID"
        portalId:@"YOUR_PORTAL_ID"
        environment:PCPEnvironmentTest
        pmiPortalKey:@"YOUR_PMI_PORTAL_KEY"
    ];
    CreditcardTokenizerConfigWrapper *config = [
        [CreditcardTokenizerConfigWrapper alloc]
        initWithCardPan:[
            [Field alloc]
            initWithSelector:@"cardpan"
            style:@"font-size: 14px; border: 1px solid #000;"
            type:@"input" 
            size:NULL
            maxlength:NULL
            length:NULL
            iframe:NULL
        ]
        cardCvc2:[
            [Field alloc]
            initWithSelector:@"cardcvc2"
            style:@"font-size: 14px; border: 1px solid #000;"
            type:@"password"
            size:@"4"
            maxlength:@"4"
            length:@{@"V": @3, @"M": @4}
            iframe:NULL
        ]
        cardExpireMonth:[
            [Field alloc]
            initWithSelector:@"cardexpiremonth"
            style:@"font-size: 14px; width: 30px; border: solid 1px #000; height: 22px;"
            type:@"text"
            size:@"2"
            maxlength:@"2"
            length:NULL
            iframe:@{@"width": @"40px"}
        ]
        cardExpireYear:[
            [Field alloc]
            initWithSelector:@"cardexpireyear"
            style:NULL
            type:@"text"
            size:NULL
            maxlength:NULL
            length:NULL
            iframe:@{@"width": @"50px"}
        ]
        defaultStyles:@{
            @"input": @"font-size: 1em; border: 1px solid #000; width: 175px;",
            @"select": @"font-size: 1em; border: 1px solid #000;",
            @"iframe": @"height: 22px, width: 180px"
        }
        language:PayoneLanguageGerman
        error:@"error"
        submitButtonId:@"submit"
        success:^(CCTokenizerResponse *response) {
            self.creditcardTokenizerResponseLabel.text =
                [NSString stringWithFormat: @"cardtype: %@ cardexpiredate: %@ pseudocardpan %@ truncatedcardpan: %@ status: %@ errorcode: %@ errormessage: %@", response.cardType, response.cardExpireDate, response.pseudoCardpan, response.truncatedCardpan, response.status, response.errorCode, response.errorMessage];
            [self.navigationController popViewControllerAnimated:true];
        }
        failure:^(enum CCTokenizerError error) {
            self.creditcardTokenizerResponseLabel.text = [NSString stringWithFormat:@"%ld", (long)error];
            [self.navigationController popViewControllerAnimated:true];
        }
    ];
    CreditcardTokenizerViewController *viewController = [
        [CreditcardTokenizerViewController alloc]
            initWithTokenizerUrl:url
            request:request
            supportedCardTypes:@[@"V", @"M"]
            config:config.creditcardTokenizerConfig
    ];
    [self.navigationController pushViewController:viewController animated:true];
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

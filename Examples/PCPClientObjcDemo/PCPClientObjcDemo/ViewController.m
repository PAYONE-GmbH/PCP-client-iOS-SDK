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
    NSURL *url = [[NSURL alloc] initWithString:@"YOUR_URL"];
    UIConfig *uiConfig = [[UIConfig alloc] initWithFormBgColor:@"#fff"
                                                  formMarginLeft:nil
                                                 formMarginRight:nil
                                                  fieldBgColor:@"#f9f9f9"
                                                   fieldBorder:@"1px solid #000"
                                                  fieldOutline:@"none"
                                               fieldLabelColor:@"#333"
                                         fieldPlaceholderColor:@"#aaa"
                                                fieldTextColor:@"#000"
                                           fieldErrorCodeColor:@"#f00"
                                                    fontFamily:nil
                                                       fontUrl:nil
                                                    labelStyle:nil
                                                    inputStyle:nil
                                          errorValidationStyle:nil
                                      manualEntryFormLabelStyle:nil
                                            checkboxLabelStyle:nil
                                                termsTextStyle:nil
                                           checkboxLabelColor:nil
                                                  checkboxSize:nil
                                                    btnBgColor:nil
                                                  btnTextColor:nil
                                              btnBorderColor:nil
                                                separatorColor:nil
                                            separatorTextColor:nil
                                               termsTextColor:nil
                                           inputBorderRadius:nil
                                      inputBorderColorDefault:nil
                                      inputBorderColorSuccess:nil
                                        inputBorderColorError:nil
                                             inputFocusOutline:nil
                                                  inputPadding:nil
                                          fieldSpacingVertical:nil
                                            labelMarginBottom:nil
                                            inputMarginBottom:nil
                                            errorMarginBottom:nil
                                           buttonMarginBottom:nil
                                   separatorTextMarginBottom:nil
                                   checkboxTextMarginBottom:nil
                                      termsTextMarginBottom:nil
                                                   iconWidth:nil
                                            iconPaddingRight:nil];
    
    IframeConfig *iframeConfig = [[IframeConfig alloc] initWithIframeWrapperId:@"payment-IFrame" height:@400 width:@400 zIndex:nil];
    
    SubmitButtonConfig *submitButtonConfig = [[SubmitButtonConfig alloc] initWithSelector:@"#submit" element:nil];
    
    CreditcardTokenizerConfigWrapper *config = [
            [CreditcardTokenizerConfigWrapper alloc]
                    initWithIframeConfig:iframeConfig
                    uiConfig:uiConfig
                    locale:@"de_DE"
                    token:@"<Token to be retrieved from the CommercePlatform-API>"
                    mode:@"test"
                    allowedCardSchemes:nil
                    customTextConfig:nil
                    submitButtonConfig:submitButtonConfig 
                    tokenizationSuccessCallback:^(NSInteger statusCode, NSString *token, CardDetails *cardDetails, NSString *inputMode) {
                        self.creditcardTokenizerResponseLabel.text = [NSString stringWithFormat:@"Success: %ld %@ %@ %@", (long)statusCode, token, cardDetails, inputMode];
                        [self.navigationController popViewControllerAnimated:true];
                    }   
                    tokenizationFailureCallback:^(NSInteger statusCode, NSDictionary *errorResponse) {
                        self.creditcardTokenizerResponseLabel.text = [NSString stringWithFormat:@"Failure: %ld %@", (long)statusCode, errorResponse];
                        [self.navigationController popViewControllerAnimated:true];
                    }
    ];

    CreditcardTokenizerViewController *viewController = [[CreditcardTokenizerViewController alloc] initWithTokenizerUrl:url config:config.creditcardTokenizerConfig];
    [self.navigationController pushViewController:viewController animated:true];
}

@end

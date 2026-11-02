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


#import "RNPaypalWrapper.h"
#import "RCTConvert.h"
#import "PayPalMobile.h"

@interface RNPaypalWrapper () <PayPalPaymentDelegate, PayPalFuturePaymentDelegate, RCTBridgeModule>

@property PayPalPayment *payment;
@property PayPalConfiguration *configuration;
@property (copy) RCTPromiseResolveBlock resolve;
@property (copy) RCTPromiseRejectBlock reject;

@end

@implementation RNPaypalWrapper

NSString * const USER_CANCELLED = @"USER_CANCELLED";

- (NSDictionary *)constantsToExport
{
    return @{
             @"PRODUCTION": PayPalEnvironmentProduction,
             @"SANDBOX": PayPalEnvironmentSandbox,
             @"NO_NETWORK": PayPalEnvironmentNoNetwork,
             USER_CANCELLED: USER_CANCELLED
             };
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initialize:(NSString *) environment clientId:(NSString *)clientId)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [PayPalMobile initializeWithClientIdsForEnvironments:@{environment : clientId}];
        [PayPalMobile preconnectWithEnvironment:environment];
    });
}

#pragma mark Single Payment

RCT_EXPORT_METHOD(pay:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    self.resolve = resolve;
    self.reject = reject;
    
    NSString *price = [RCTConvert NSString:options[@"price"]];
    NSString *currency = [RCTConvert NSString:options[@"currency"]];
    NSString *description = [RCTConvert NSString:options[@"description"]];
    
    self.payment = [[PayPalPayment alloc] init];
    [self.payment setAmount:[[NSDecimalNumber alloc] initWithString:price]];
    [self.payment setCurrencyCode:currency];
    [self.payment setShortDescription:description];
    
    self.configuration = [[PayPalConfiguration alloc] init];
    [self.configuration setAcceptCreditCards:false];
    [self.configuration setPayPalShippingAddressOption:PayPalShippingAddressOptionPayPal];
    
    PayPalPaymentViewController *vc = [[PayPalPaymentViewController alloc] initWithPayment:self.payment
                                                                             configuration:self.configuration
                                                                                  delegate:self];
    
    UIViewController *visibleVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    do {
        if ([visibleVC isKindOfClass:[UINavigationController class]]) {
            visibleVC = [(UINavigationController *)visibleVC visibleViewController];
        } else if (visibleVC.presentedViewController) {
            visibleVC = visibleVC.presentedViewController;
        }
    } while (visibleVC.presentedViewController);
    dispatch_async(dispatch_get_main_queue(), ^{
        [visibleVC presentViewController:vc animated:YES completion:nil];
    });
}

#pragma mark Future Payments

RCT_EXPORT_METHOD(obtainConsent:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    self.resolve = resolve;
    self.reject = reject;

    NSString *merchantName = [RCTConvert NSString:options[@"merchantName"]];
    NSString *merchantPrivacyPolicyURL = [RCTConvert NSString:options[@"merchantPrivacyPolicyURL"]];
    NSString *merchantUserAgreementURL = [RCTConvert NSString:options[@"merchantUserAgreementURL"]];

    self.configuration = [[PayPalConfiguration alloc] init];
    [self.configuration setMerchantName:merchantName];
    [self.configuration setMerchantPrivacyPolicyURL:[NSURL URLWithString:merchantPrivacyPolicyURL]];
    [self.configuration setMerchantUserAgreementURL:[NSURL URLWithString:merchantUserAgreementURL]];
    
    PayPalFuturePaymentViewController *vc = [[PayPalFuturePaymentViewController alloc] initWithConfiguration:self.configuration
                                                                                              delegate:self];
    
    UIViewController *visibleVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    do {
        if ([visibleVC isKindOfClass:[UINavigationController class]]) {
            visibleVC = [(UINavigationController *)visibleVC visibleViewController];
        } else if (visibleVC.presentedViewController) {
            visibleVC = visibleVC.presentedViewController;
        }
    } while (visibleVC.presentedViewController);
    dispatch_async(dispatch_get_main_queue(), ^{
        [visibleVC presentViewController:vc animated:YES completion:nil];
    });
}

#pragma mark Paypal Delegate

- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController
{
    [paymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.reject) {
            NSError *error = [NSError errorWithDomain:RCTErrorDomain code:1 userInfo:NULL];
            self.reject(USER_CANCELLED, USER_CANCELLED, error);
        }
    }];
}

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController
                 didCompletePayment:(PayPalPayment *)completedPayment
{
    [paymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.resolve) {
            self.resolve(completedPayment.confirmation);
        }
    }];
}

#pragma mark - PayPalFuturePaymentDelegate

- (void)payPalFuturePaymentDidCancel:(PayPalFuturePaymentViewController *)futurePaymentViewController
{
    [futurePaymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.reject) {
            NSError *error = [NSError errorWithDomain:RCTErrorDomain code:1 userInfo:NULL];
            self.reject(USER_CANCELLED, USER_CANCELLED, error);
        }
    }];
}

- (void)payPalFuturePaymentViewController:(PayPalFuturePaymentViewController *)futurePaymentViewController
                didAuthorizeFuturePayment:(NSDictionary *)futurePaymentAuthorization
{
    // futurePaymentAuthorization
    [futurePaymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.resolve) {
            self.resolve(futurePaymentAuthorization);
        }
    }];
}

@end

//
//  BTStoreManager.m
//  GoogleLoginDemo
//
//  Created by admin on 2020/5/13.
//  Copyright © 2020 admin. All rights reserved.
//

#import "BTStoreManager.h"
#import "BTStoreTransactionReceiptVerifier.h"
#import "BTStoreTransactionObserver.h"

NSString *const BTStoreErrorDomain = @"net.robotmedia.store";
NSInteger const BTStoreErrorCodeDownloadCanceled = 300;
NSInteger const BTStoreErrorCodeUnknownProductIdentifier = 100;
NSInteger const BTStoreErrorCodeUnableToCompleteVerification = 200;


@implementation BTAddPaymentParameters

-(void)dealloc
{
    
}

@end

@implementation BTStoreManager{

    NSMutableDictionary *_products;
    NSMutableSet *_productsRequestDelegates;
    NSMutableDictionary *_addPaymentParameters;

    id<BTStoreReceiptVerifier> _receipt;

    
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"这个是个单例"
                                   reason:@"应该这样调用 [BTStoreManager defaultStore]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init])
    {
        _addPaymentParameters = [NSMutableDictionary dictionary];
        _products = [NSMutableDictionary dictionary];
        _productsRequestDelegates = [NSMutableSet set];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:[BTStoreTransactionObserver defaultObserver]];
    }
    
    return self;
}

+ (BTStoreManager*)defaultStore
{
    static BTStoreManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] initPrivate];
    });
    return sharedInstance;
}

#pragma mark StoreKit addPayment

+ (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

- (void)addPayment:(NSString*)productIdentifier
           callBack:(void (^)(SKPaymentTransaction *transaction))successBlock
{
    [self addPayment:productIdentifier user:nil callBack:successBlock];
}

- (void)addPayment:(NSString*)productIdentifier
              user:(NSString*)userIdentifier
           callBack:(void (^)(SKPaymentTransaction *transaction))callBackBlock
{
    SKProduct *product = [self productForIdentifier:productIdentifier];
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    if ([payment respondsToSelector:@selector(setApplicationUsername:)])
    {
        payment.applicationUsername = userIdentifier;
    }
    
    BTAddPaymentParameters *parameters = [[BTAddPaymentParameters alloc] init];
    parameters.callBackBlock = callBackBlock;
    _addPaymentParameters[productIdentifier] = parameters;
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark finishTransaction


- (void)finishTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark requestProducts

- (void)requestProducts:(NSString*)identifiers
                success:(BTSKProductsRequestSuccessBlock)successBlock
                failure:(BTSKProductsRequestFailureBlock)failureBlock
{
    BTProductsRequestDelegate *delegate = [[BTProductsRequestDelegate alloc] init];
    delegate.store = self;
    delegate.successBlock = successBlock;
    delegate.failureBlock = failureBlock;
    [_productsRequestDelegates addObject:delegate];
 
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:identifiers]];
    productsRequest.delegate = delegate;
    
    [productsRequest start];
}

- (void)addProduct:(SKProduct*)product
{
    _products[product.productIdentifier] = product;
}

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier
{
    return _products[productIdentifier];
}

- (void)removeProductsRequestDelegate:(BTProductsRequestDelegate*)delegate
{
    [_productsRequestDelegates removeObject:delegate];
}

- (BTAddPaymentParameters*)popAddPaymentParametersForIdentifier:(SKPaymentTransaction *)transaction
{
    NSString *identifier = transaction.payment.productIdentifier;
     BTAddPaymentParameters *parameters = _addPaymentParameters[identifier];
    if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
        return parameters;
    }
    [_addPaymentParameters removeObjectForKey:identifier];
    return parameters;
}

@end



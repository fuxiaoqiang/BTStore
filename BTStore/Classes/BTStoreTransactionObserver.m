//
//  BTStoreTransactionObserver.m
//  ZYXSDK_GAT
//
//  Created by admin on 2020/5/21.
//  Copyright © 2020 admin. All rights reserved.
//

#import "BTStoreTransactionObserver.h"

@implementation BTStoreTransactionObserver

+ (BTStoreTransactionObserver*)defaultObserver
{
    static BTStoreTransactionObserver *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"这个是个单例"
                                   reason:@"应该这样调用 [BTStoreTransactionObserver defaultObserver]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    if (self = [super init])
    {
        //[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    
    return self;
}
- (void)paymentQueue:(nonnull SKPaymentQueue *)queue updatedTransactions:(nonnull NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions)
    {
        BTAddPaymentParameters *paramers = [[BTStoreManager defaultStore] popAddPaymentParametersForIdentifier:transaction];
        NSLog(@"paramers = %@",paramers);
        if (paramers.callBackBlock) {
            paramers.callBackBlock(transaction);
        }else{
            if ([BTStoreManager defaultStore].issueOrdersBlock) {
                [BTStoreManager defaultStore].issueOrdersBlock(transaction);
            }
        }
        
    }
    
}


@end

@implementation BTProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    BTStoreLog(@"thread = %@",[NSThread currentThread]);
    NSArray *products = [NSArray arrayWithArray:response.products];
    NSArray *invalidProductIdentifiers = [NSArray arrayWithArray:response.invalidProductIdentifiers];
    
    for (SKProduct *product in products)
    {
        BTStoreLog(@"received product with id %@", product.productIdentifier);
        [self.store addProduct:product];
    }
    
    for (NSString *invalid in invalidProductIdentifiers)
    {
        BTStoreLog(@"invalid product with id %@", invalid);
    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.successBlock&&[products count])
        {
            self.successBlock(products);
        }else{
            NSError *wrapperError = [NSError errorWithDomain:@"request.error" code:100 userInfo:@{@"key": @"invalid productid"}];
            self.failureBlock(wrapperError);
        }
    });

    
}

- (void)requestDidFinish:(SKRequest *)request
{
    [self.store removeProductsRequestDelegate:self];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    BTStoreLog(@"products request failed with error %@", error.debugDescription);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.failureBlock)
        {
            self.failureBlock(error);
        }
    });
    
    [self.store removeProductsRequestDelegate:self];
}

- (void)dealloc
{
    
}

@end

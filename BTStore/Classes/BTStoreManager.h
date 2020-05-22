//
//  BTStoreManager.h
//  GoogleLoginDemo
//
//  Created by admin on 2020/5/13.
//  Copyright © 2020 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class BTStoreTransactionObserver;
@class BTProductsRequestDelegate;

#if DEBUG
#define BTStoreLog(fmt, ...) NSLog((@"\n[文件名:%s]\n""[函数名:%s]\n""[行号:%d] \n" fmt), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define BTStoreLog(...)
#endif

typedef void (^BTSKProductsRequestFailureBlock)(NSError * _Nonnull error);
typedef void (^BTSKProductsRequestSuccessBlock)(NSArray * _Nonnull products);
typedef void (^BTSKPaymentTransactionFailureBlock)(SKPaymentTransaction * _Nullable transaction, NSError * _Nonnull error);
typedef void (^BTSKPaymentTransactionSuccessBlock)(SKPaymentTransaction * _Nonnull transaction);

extern NSString * _Nonnull const BTStoreErrorDomain;
extern NSInteger const BTStoreErrorCodeDownloadCanceled;
extern NSInteger const BTStoreErrorCodeUnknownProductIdentifier;
extern NSInteger const BTStoreErrorCodeUnableToCompleteVerification;

NS_ASSUME_NONNULL_BEGIN


@protocol BTStoreReceiptVerifier <NSObject>


- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *error))failureBlock;

@end


@interface BTAddPaymentParameters : NSObject

@property (nonatomic, strong) BTSKPaymentTransactionSuccessBlock callBackBlock;

@end

@interface BTStoreManager : NSObject

@property (nonatomic, weak) id<BTStoreReceiptVerifier> receiptVerifier;

@property (nonatomic, strong) BTSKPaymentTransactionSuccessBlock issueOrdersBlock;


+ (BTStoreManager*)defaultStore;

+ (BOOL)canMakePayments;


- (void)requestProducts:(NSString*)identifiers
                success:(void (^)(NSArray *products))successBlock
                failure:(void (^)(NSError *error))failureBlock;

- (void)addPayment:(NSString*)productIdentifier
           callBack:(void (^)(SKPaymentTransaction *transaction))callBackBlock;

- (void)addPayment:(NSString*)productIdentifier
              user:(nullable NSString*)userIdentifier
           callBack:(void (^)(SKPaymentTransaction *transaction))callBackBlock;


- (void)finishTransaction:(SKPaymentTransaction *)transaction;



- (void)addProduct:(SKProduct*)product;

- (SKProduct*)productForIdentifier:(NSString*)productIdentifier;

- (void)removeProductsRequestDelegate:(BTProductsRequestDelegate*)delegate;

- (BTAddPaymentParameters*)popAddPaymentParametersForIdentifier:(SKPaymentTransaction *)transaction;

@end



NS_ASSUME_NONNULL_END

//
//  BTStoreTransactionObserver.h
//  ZYXSDK_GAT
//
//  Created by admin on 2020/5/21.
//  Copyright © 2020 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "BTStoreManager.h"

NS_ASSUME_NONNULL_BEGIN



@interface BTProductsRequestDelegate : NSObject<SKProductsRequestDelegate>

@property (nonatomic, strong) BTSKProductsRequestSuccessBlock successBlock;
@property (nonatomic, strong) BTSKProductsRequestFailureBlock failureBlock;
@property (nonatomic, weak)   BTStoreManager *store;

@end

@interface BTStoreTransactionObserver : NSObject<SKPaymentTransactionObserver>

+ (BTStoreTransactionObserver*)defaultObserver;

@end

NS_ASSUME_NONNULL_END

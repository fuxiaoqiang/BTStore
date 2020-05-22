//
//  _+BTTransaction.h
//  LoginUI
//
//  Created by hechao on 2017/11/30.
//  Copyright © 2017年 zhangyuhe. All rights reserved.
//
#import <StoreKit/StoreKit.h>

typedef NS_ENUM(NSInteger, BTTransactionStatus) {
    BTTransactionStatusCreateOrder =1,    // 创建订单
    BTTransactionStatusPurchasing,     // 拉起苹果充值
    BTTransactionStatusPurchased,        // 苹果返回充值成功
    BTTransactionStatusFailed,      // 苹果返回充值失败
    BTTransactionStatusTimeout ,   // 苹果接口未返回
    BTTransactionStatusServerBack,    //  已发送给web服务器, 并收到回调, 用不到
    BTTransactionStatusFinishi,    //  关闭苹果订单, 用不到
};

@interface BTTransaction : NSObject<NSCoding>

@property(atomic, strong, nullable) NSDate *transactionDate ;

@property(atomic, strong, nullable) NSString *transactionReceipt ;

@property(atomic, strong, nullable) NSString * orderID ;

@property(atomic, strong, nullable) NSString * productID ;

@property(atomic) BTTransactionStatus status ;

@property(atomic, strong, nullable) NSString * uid ;

@property(atomic, strong, nullable) NSString * serverID ;

@property(atomic, strong, nullable)SKPaymentTransaction *sKPaymentTransaction;

@end

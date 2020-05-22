//
//  _+BTTransaction.h
//  LoginUI
//
//  Created by hechao on 2017/11/30.
//  Copyright © 2017年 zhangyuhe. All rights reserved.
//

#import "BTTransaction.h"
#define PAY_VERSION @"2"

@protocol BTStoreUtilDelegate <NSObject>

- (void)saveStoreLog:(NSString *)log;

- (void)uploadStoreLogWithUid:(NSString *)uid;

- (void)issueOrderWith:(BTTransaction *)transaction;

- (void)issueFailOrderWith:(BTTransaction *)transaction;

- (void)issueTimeoutOrderWith:(BTTransaction *)transaction;

@end

@interface BTTransactionManager : NSObject

@property (nonatomic , weak) id<BTStoreUtilDelegate> delegate;

+ (BTTransactionManager*) getInstance;
- (void) addTransaction:(BTTransaction*) transation;
- (BTTransaction*) getCurrentTransactionBy: (NSString *) productID byUID:(NSString*) uid byServerID:(NSString*) serverid;
- (BOOL) updateTransaction: (BTTransaction *) upTransaction;
- (BOOL) removeTransaction:(NSString *) productID byUID:(NSString*) uid byServerID:(NSString*) serverid;
- (void) startThread;
- (void) removeTransionFile;
@end

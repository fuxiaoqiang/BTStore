//
//  _+BTTransaction.m
//  LoginUI
//
//  Created by hechao on 2017/11/30.
//  Copyright © 2017年 zhangyuhe. All rights reserved.
//

#import "BTTransactionManager.h"

#define TRANSATIONFILE "sdk_transaction.plist"
#define TIMEOUTINTERVAL 3600

static BTTransactionManager* instance = NULL;

@implementation BTTransactionManager
{
    NSMutableArray *transactions;
    int coefficient ;
    BOOL isOpenThread ;
}

+ (BTTransactionManager*) getInstance{
    if (instance == NULL) {
        instance =[[BTTransactionManager alloc] init];
    }
    return instance;
}

-(id)init{
    if (self = [super init]) {
        coefficient = 1;
        isOpenThread = false;
         [self syscFromFile];
    }
    return self;
}

-(void)syscFromFile {
    NSData *data2 = [NSData dataWithContentsOfFile:[self getTransactionFile]];//读取文件
    NSArray *arr = [NSKeyedUnarchiver unarchiveObjectWithData:data2];
    @synchronized(self) {
        transactions =[NSMutableArray arrayWithArray:arr];
    }
}

-(void)syscToFile{
    BOOL b = false;
    @synchronized(self) {
        NSData  *data = [NSKeyedArchiver archivedDataWithRootObject:transactions];//将transactions序列化后,保存到NSData中
        b = [data writeToFile:[self getTransactionFile] atomically:YES];//持久化保存成物理文件
    }
    if (!b) {
        NSLog(@"保存失败");
        [self.delegate saveStoreLog:[NSString stringWithFormat:@"syscToFile, save error"]];
    }
}

- (void) addTransaction:(BTTransaction*) transaction{
    [self.delegate saveStoreLog:[NSString stringWithFormat:@"--111-- addTransaction, productID:%@ before count: %d" ,transaction.productID, (int)[transactions count] ]];
    if ([self removeTransaction:transaction.productID byUID:transaction.uid byServerID:transaction.serverID]) {
        [self.delegate saveStoreLog:[NSString stringWithFormat:@"--111.1-- addTransaction, have same product order " ]];
    }
    @synchronized(self) {
        [transactions addObject:transaction];
    }
    [self syscToFile];
}

- (BTTransaction*) getCurrentTransactionBy: (NSString *) productID byUID:(NSString*) uid byServerID:(NSString*) serverid{
    BTTransaction * transation = nullptr;
    @synchronized(self) {
        for (BTTransaction* transaction in transactions) {
            if ([productID isEqualToString:transaction.productID] && [uid isEqualToString:transaction.uid] && [serverid isEqualToString:transaction.serverID] ) {
                transation = [transaction copy];
            }
        }
    }
    return transation;
}

- (BOOL) updateTransaction: (BTTransaction *) upTransaction {
    [self.delegate saveStoreLog:[NSString stringWithFormat:@"--222-- updateTransaction,productID:%@ status: %d" ,upTransaction.productID, (int)upTransaction.status]];
    BOOL find = false;
    @synchronized(self) {
        int i = 0;
        for (__strong BTTransaction* transaction in transactions) {
            if ([upTransaction.productID isEqualToString:transaction.productID] && [upTransaction.uid isEqualToString:transaction.uid]&& [upTransaction.serverID isEqualToString:transaction.serverID]) {
                [transactions replaceObjectAtIndex:i withObject:[upTransaction copy] ];
                find = true;
                break;
            }
        }
    }
    if(!find){
        [self addTransaction:upTransaction];
    }else{
        [self syscToFile];
    }
    return true;
}

-(BOOL) removeTransaction:(NSString *) productID byUID:(NSString*) uid byServerID:(NSString*) serverid{
    [self.delegate saveStoreLog:[NSString stringWithFormat:@"--333-- removeTransaction,productID:%@ " ,productID]];
    BTTransaction* findTransaction = NULL;
    @synchronized(self) {
        for (__strong BTTransaction* transaction in transactions) {
            if ([productID isEqualToString:transaction.productID] && [uid isEqualToString:transaction.uid] && [serverid isEqualToString:transaction.serverID]) {
                findTransaction = transaction;
            }
        }
    }
    if (findTransaction!=NULL) {
         @synchronized(self) {
             [transactions removeObject:findTransaction];
         }
        [self syscToFile];
        return true;
    }else{
        return false;
    }
   

    
}

-(NSString *)getTransactionFile{
    NSString * sandBoxpath = [NSHomeDirectory()stringByAppendingPathComponent:@"/Documents"];
    return [NSString stringWithFormat:@"%@/%s",sandBoxpath,TRANSATIONFILE];
}

-(void) startThread {
    if(isOpenThread == true){
        coefficient = 1; //速率重置
        return;
    }
    isOpenThread = true;
    dispatch_queue_t queue = dispatch_queue_create("BTTransactionManager", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        
        while (true) {
            if([transactions count] <=0){
                isOpenThread = false;
                coefficient = 1;
                return;
            }
            @synchronized(self) {
                for (BTTransaction* transaction in transactions) {
                    switch (transaction.status) {
                        case BTTransactionStatusCreateOrder:
                        case BTTransactionStatusPurchasing:
                            if([NSDate date].timeIntervalSince1970 - transaction.transactionDate.timeIntervalSince1970 > TIMEOUTINTERVAL){
                                [self sendTimeout:transaction];
                                [self uploadLog:transaction.uid ];
                            }
                            break;

                        case BTTransactionStatusPurchased:{
                            SKPaymentTransaction * sKTransaction = transaction.sKPaymentTransaction;
                            if(sKTransaction != NULL){
                                [self sendPurchased:transaction];
                            }
                            break;
                        }
                        case BTTransactionStatusFailed:{
                            SKPaymentTransaction * sKTransaction = transaction.sKPaymentTransaction;
                            if(sKTransaction != NULL){
                                [self sendFailed:transaction];
                            }
                            break;
                        }
                        case BTTransactionStatusTimeout:{
                            break;
                        }
                            
                        default:
                            break;
                    }
                }
            }
            NSLog(@"%@", [NSThread currentThread]);
            [NSThread sleepForTimeInterval:10.0*coefficient];
            coefficient = coefficient*2;
        }
        
        
    });
}

-(void) sendPurchased:(BTTransaction*) transaction{

    [self.delegate issueOrderWith:transaction];
}

-(void) sendFailed:(BTTransaction*) transaction{

    [self.delegate issueFailOrderWith:transaction];
}

-(void) sendTimeout:(BTTransaction*) transaction{
    
    [self.delegate issueTimeoutOrderWith:transaction];
}

-(void) uploadLog:(NSString*)uid{
    [self.delegate uploadStoreLogWithUid:uid];
}

- (void) removeTransionFile{
    [[NSFileManager defaultManager] removeItemAtPath:[self getTransactionFile] error:nil];
}

@end

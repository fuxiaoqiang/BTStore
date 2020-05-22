//
//  _+BTTransaction.m
//  LoginUI
//
//  Created by hechao on 2017/11/30.
//  Copyright © 2017年 zhangyuhe. All rights reserved.
//

#import "BTTransaction.h"

@implementation BTTransaction

@synthesize orderID,productID,status,transactionReceipt,transactionDate,uid,serverID,sKPaymentTransaction;


//将对象编码(即:序列化)
-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:orderID forKey:@"orderID"];
    [aCoder encodeObject:productID forKey:@"productID"];
    [aCoder encodeInteger:(int)status forKey:@"status"];
    [aCoder encodeObject:transactionReceipt forKey:@"transactionReceipt"];
    [aCoder encodeObject:transactionDate forKey:@"transactionDate"];
    [aCoder encodeObject:uid forKey:@"uid"];
    [aCoder encodeObject:serverID forKey:@"serverID"];

}

//将对象解码(反序列化)
-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super init])
    {
        self.orderID = [aDecoder decodeObjectForKey:@"orderID"];
        self.status = [aDecoder decodeIntForKey:@"status"];
        self.productID = [aDecoder decodeObjectForKey:@"productID"];
        self.transactionReceipt = [aDecoder decodeObjectForKey:@"transactionReceipt"];
        self.transactionDate = [aDecoder decodeObjectForKey:@"transactionDate"];
        self.uid = [aDecoder decodeObjectForKey:@"uid"];
        self.serverID = [aDecoder decodeObjectForKey:@"serverID"];

    }
    return (self);
    
}

-(id)copy
{
    BTTransaction *copy = [[BTTransaction alloc] init];
    copy.orderID = self.orderID;
    copy.status = self.status;
    copy.productID = self.productID;
    copy.transactionReceipt = self.transactionReceipt;
    copy.transactionDate = self.transactionDate;
    copy.uid = self.uid;
    copy.serverID = self.serverID;
    copy.sKPaymentTransaction = self.sKPaymentTransaction;
    
    return copy;
}

@end

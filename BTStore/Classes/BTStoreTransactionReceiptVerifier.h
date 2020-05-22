//
//  BTStoreTransactionReceiptVerifier.h
//  GoogleLoginDemo
//
//  Created by admin on 2020/5/13.
//  Copyright © 2020 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTStoreManager.h"
@interface BTStoreTransactionReceiptVerifier : NSObject<BTStoreReceiptVerifier>


@end

@interface NSData(rm_base64)

- (NSString *)bt_stringByBase64Encoding;

@end

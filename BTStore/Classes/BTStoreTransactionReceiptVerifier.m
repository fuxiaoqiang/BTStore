//
//  BTStoreTransactionReceiptVerifier.m
//  GoogleLoginDemo
//
//  Created by admin on 2020/5/13.
//  Copyright © 2020 admin. All rights reserved.
//

#import "BTStoreTransactionReceiptVerifier.h"


@interface BTStoreTransactionReceiptVerifier ()

@property (nonatomic,strong) dispatch_semaphore_t semaphore;

@end



@implementation NSData(rm_base64)

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSString *)bt_stringByBase64Encoding
{ // From: http://stackoverflow.com/a/4727124/143378
    const unsigned char * objRawData = self.bytes;
    char * objPointer;
    char * strResult;
    
    // Get the Raw Data length and ensure we actually have data
    NSInteger intLength = self.length;
    if (intLength == 0) return nil;
    
    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc((((intLength + 2) / 3) * 4) + 1, sizeof(char));
    objPointer = strResult;
    
    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3;
    }
    
    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }
    
    // Terminate the string-based result
    *objPointer = '\0';
    
    // Create result NSString object
    NSString *base64String = @(strResult);
    
    // Free memory
    free(strResult);
    
    return base64String;
}

@end


@implementation BTStoreTransactionReceiptVerifier

- (dispatch_semaphore_t)semaphore
{
    if (_semaphore == nil) {
        _semaphore = dispatch_semaphore_create(0);
    }
    return _semaphore;
}

- (NSData *)getTransactionReceiptWith:(NSURLRequest *)request
{

    __block NSData *receipData = nil;
    NSURLSessionConfiguration *ephemeralConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    ephemeralConfiguration.timeoutIntervalForRequest = 10.0;
    ephemeralConfiguration.timeoutIntervalForResource = 10.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:ephemeralConfiguration];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        receipData = data;
        dispatch_semaphore_signal(self.semaphore);
    }];
    
    [dataTask resume];
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    return receipData;
}

- (void)verifyTransaction:(nonnull SKPaymentTransaction *)transaction success:(nonnull void (^)(void))successBlock failure:(nonnull void (^)(NSError * _Nonnull))failureBlock
{
    NSData *receipt;
//#ifdef NSFoundationVersionNumber_iOS_7_0
//    //如果NSFoundation的版本在7.0之上，包括7.0
//    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[[NSBundle mainBundle] appStoreReceiptURL]];
//
//    receipt = [self getTransactionReceiptWith:urlRequest];
//#else
    receipt= transaction.transactionReceipt;
//#endif

    NSString *strReceipt = [receipt bt_stringByBase64Encoding];
    if (receipt == nil)
    {
        if (failureBlock != nil)
        {
            NSError *error = [NSError errorWithDomain:BTStoreErrorDomain code:0 userInfo:nil];
            failureBlock(error);
        }
        return;
    }
    static NSString *receiptDataKey = @"receipt-data";
    static NSString *password = @"password";
    NSDictionary *jsonReceipt = @{receiptDataKey : strReceipt,
                                  password : @""
                                };

    NSError *error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:jsonReceipt options:0 error:&error];
    if (!requestData)
    {
        BTStoreLog(@"Failed to serialize receipt into JSON");
        if (failureBlock != nil)
        {
            failureBlock(error);
        }
        return;
    }
    
    static NSString *productionURL = @"https://buy.itunes.apple.com/verifyReceipt";
    
    [self verifyRequestData:requestData url:productionURL success:successBlock failure:failureBlock];
}

- (void)verifyRequestData:(NSData*)requestData
                      url:(NSString*)urlString
                  success:(void (^)(void))successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPBody = requestData;
    static NSString *requestMethod = @"POST";
    request.HTTPMethod = requestMethod;

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSData *data = [self getTransactionReceiptWith:request];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!data)
            {
                BTStoreLog(@"Server Connection Failed");
                NSError *wrapperError = [NSError errorWithDomain:BTStoreErrorDomain code:BTStoreErrorCodeUnableToCompleteVerification userInfo:@{NSUnderlyingErrorKey : error, NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Connection to Apple failed. Check the underlying error for more info.", @"BTStore", @"Error description")}];
                if (failureBlock != nil)
                {
                    failureBlock(wrapperError);
                }
                return;
            }
            NSError *jsonError;
            NSDictionary *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!responseJSON)
            {
                BTStoreLog(@"Failed To Parse Server Response");
                if (failureBlock != nil)
                {
                    failureBlock(jsonError);
                }
            }
            
            static NSString *statusKey = @"status";
            NSInteger statusCode = [responseJSON[statusKey] integerValue];
            
            static NSInteger successCode = 0;
            static NSInteger sandboxCode = 21007;
            if (statusCode == successCode)
            {
                if (successBlock != nil)
                {
                    successBlock();
                }
            }
            else if (statusCode == sandboxCode)
            {
                BTStoreLog(@"Verifying Sandbox Receipt");
                
                static NSString *sandboxURL = @"https://sandbox.itunes.apple.com/verifyReceipt";
                [self verifyRequestData:requestData url:sandboxURL success:successBlock failure:failureBlock];
            }
            else
            {
                BTStoreLog(@"Verification Failed With Code %ld", (long)statusCode);
                NSError *serverError = [NSError errorWithDomain:BTStoreErrorDomain code:statusCode userInfo:nil];
                if (failureBlock != nil)
                {
                    failureBlock(serverError);
                }
            }
        });
    });
}


@end

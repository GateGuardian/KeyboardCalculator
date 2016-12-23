//
//  InputComposer.h
//  KeyboardCalculator
//
//  Created by Evan Kostromin on 12/22/16.
//  Copyright © 2016 IvanKostromin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ComposingCompletion) (BOOL success, NSError *error, NSString *validString, NSRange relativeStringRange);

@interface InputComposer : NSObject

- (void)addOperand:(NSString *)operand to:(NSMutableString *)expression inRange:(NSRange)cursor completion:(ComposingCompletion)completion;
- (void)addOperation:(NSString *)operation to:(NSMutableString *)expression inRange:(NSRange)cursor completion:(ComposingCompletion)completion;
- (void)deleteStringInRange:(NSRange)cursor inString:(NSMutableString *)expression completion:(ComposingCompletion)completion;
- (NSString *)formatString:(NSString *)string;
- (BOOL)isStringAnOperator:(NSString *)string;
- (BOOL)isStringAnDigitPart:(NSString *)string;
- (BOOL)isOperationInString:(NSString *)string;
@end

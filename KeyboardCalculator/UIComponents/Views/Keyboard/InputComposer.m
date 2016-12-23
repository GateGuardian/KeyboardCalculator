//
//  InputComposer.m
//  KeyboardCalculator
//
//  Created by Evan Kostromin on 12/22/16.
//  Copyright © 2016 IvanKostromin. All rights reserved.
//

#import "InputComposer.h"
#import "KeyboardConstans.h"

@interface InputComposer ()

@property (strong, nonatomic) NSNumberFormatter *formatter;

@end

@implementation InputComposer

- (instancetype)init {
    self = [super init];
    if (self) {
        _formatter = [self createFormatter];
    }
    return self;
}

#pragma mark - Public

- (void)addOperand:(NSString *)operand to:(NSMutableString *)expression inRange:(NSRange)cursor completion:(ComposingCompletion)completion {
    
    //TODO: advanced operand check: multy DotSigns, NaN etc.
    
    NSUInteger expressionLength = expression.length;
    BOOL isValidCursor = cursor.location <= expressionLength;
    BOOL isValidOperand = operand.length;
    NSRange operandRange = NSMakeRange(cursor.location, operand.length);
    if (isValidOperand && isValidCursor) {
        //ZeroExpressionLength: if expressionLength == 0 just addingoperand, if expressionLength == 0 && operand is a DotSign add ZeroSign a head, if expressionLength == 0 && operand is a TripleZero add ZeroSign instead
        if (!expressionLength) {
            [self handleZeroLengthExpression:expression withOperand:operand];
        } else {
            NSRange expressionOperandRange = [self operandRangeWithCursorPosition:cursor inString:expression];
            NSString *expressionOperand = [expression substringWithRange:expressionOperandRange];
            BOOL tryingToAddMultyDots = [operand isEqualToString:DotSign] && [expressionOperand containsString:DotSign];//operand is a DotSign and expressionOperand allready contains DotSign
            BOOL cursorAtExpressionOperandBegining = cursor.location == expressionOperandRange.location;
            BOOL tryingToAddZeroToHead = cursorAtExpressionOperandBegining && [self isStringAnZeroSign:operand];// - can't add zero to head of Number
            BOOL canAddOperand = !tryingToAddMultyDots && !tryingToAddZeroToHead && isValidOperand;
            if (canAddOperand) {
                // Merge operand with expressionOperand
                //add operand with replace
                [expression replaceCharactersInRange:cursor withString:operand];
                cursor = NSMakeRange(cursor.location, 0);
                expressionOperandRange = [self operandRangeWithCursorPosition:cursor inString:expression];
                expressionOperand = [expression substringWithRange:expressionOperandRange];
                expressionOperand = [self formatString:expressionOperand];
                [expression replaceCharactersInRange:expressionOperandRange withString:expressionOperand];
            }
        }
    }
    completion(YES, nil, expression, operandRange);
}

- (void)addOperation:(NSString *)operation to:(NSMutableString *)expression inRange:(NSRange)cursor completion:(ComposingCompletion)completion
{
    NSUInteger expressionLength = expression.length;
    BOOL isValidCursor = cursor.location <= expressionLength;
    BOOL isValidOperation = operation.length;
    NSRange operationRange = NSMakeRange(cursor.location, operation.length);
    
    //limitations
    //1) if length == 0  - only Plus or Minus operations allowed
    //2) if length == 1 and expression is an operation replace, only Plus or Minus operations allowed
    //3) If cursor == expression range - replace with operator if allowed
    //4) look for trailing and leading chars according to Cursor Position and Length.
    //   Operations chars should be replaced
    if (isValidCursor && isValidOperation) {
        if (expressionLength <= 1) {
            [self handleInitialOperationsInExpression:expression operation:operation];
        } else {
            //if leading or trailing character regarding cursor position are operator - replace with given operator
            NSUInteger lastPosition = expressionLength - 1;
            
            NSString *leadingSymbol = @"";
            NSString *trailingSymbol = @"";
            
            NSRange leadingSymbolRange = NSMakeRange(cursor.location ? cursor.location - 1 : 0, 1);
            if (leadingSymbolRange.location) {
                leadingSymbol = [expression substringWithRange:leadingSymbolRange];
            }
            NSUInteger cursorEdgeLocation = cursor.location + cursor.length;
            NSRange trailingSymbolRange = NSMakeRange((cursorEdgeLocation < lastPosition ? cursorEdgeLocation : lastPosition), 1);
            if (trailingSymbolRange.location < lastPosition) {
                trailingSymbol = [expression substringWithRange:trailingSymbolRange];
            }
            NSUInteger newCursorLocation = [self isStringAnOperator:leadingSymbol] ? leadingSymbolRange.location : cursor.location;
            NSUInteger newCursorLength = [self isStringAnOperator:trailingSymbol] ? ((trailingSymbolRange.location + trailingSymbolRange.length) - newCursorLocation) : cursor.length + (cursor.location - newCursorLocation);
            
            NSRange newCursor = NSMakeRange(newCursorLocation, newCursorLength);
            if (newCursorLength) {
                [expression replaceCharactersInRange:newCursor withString:operation];
            } else {
                [expression insertString:operation atIndex:newCursor.location];
            }
        }
    }
    completion(YES, nil, expression, operationRange);
}

- (void)deleteStringInRange:(NSRange)cursor inString:(NSMutableString *)expression completion:(ComposingCompletion)completion {
    
    NSUInteger expressionLength = expression.length;
    BOOL validArguments = expressionLength && (cursor.location <= expressionLength);

    NSRange expressionOperandRange = NSMakeRange(0, 0);
    //if only character in string just recreating string
    if (expressionLength == 1) {
        expression = [NSMutableString new];
    } else if (validArguments) {
        //Delete according to cursor position
        NSUInteger deletionLength = (cursor.length)?: 1;
        NSUInteger newCursorLocation = deletionLength > 1? cursor.location : (cursor.location - 1);
        [expression deleteCharactersInRange:NSMakeRange(newCursorLocation, deletionLength)];
        //cursor should be moved to left since we added new digit to expression
        NSRange newCursor = NSMakeRange(newCursorLocation, 0);
        //Looking for number range
        expressionOperandRange = [self operandRangeWithCursorPosition:newCursor inString:expression];
        //extracting number from string
        if (expressionOperandRange.length) {
            NSString *expressionOperand = [expression substringWithRange:expressionOperandRange];
            NSString *formatedString = [self formatString:expressionOperand];
            [expression replaceCharactersInRange:expressionOperandRange withString:formatedString];
        }
    }
    completion(YES, nil, expression, expressionOperandRange);
}

- (NSString *)formatString:(NSString *)string {
    NSString *cleanedString = [string stringByReplacingOccurrencesOfString:RangeSign withString:@""];
    NSArray<NSString *> *stringComponents = [cleanedString componentsSeparatedByString:DotSign];
    NSString *wholeComponent = stringComponents.firstObject;
    NSNumber *stringNumber = [self.formatter numberFromString:wholeComponent];
    NSString *formatedString = [self.formatter stringFromNumber: stringNumber];
    if (stringComponents.count > 1 && formatedString) {
        formatedString = [formatedString stringByAppendingFormat:@"%@%@", DotSign, stringComponents[1]];
    }
    return formatedString?: @"";
}

- (BOOL)isStringAnOperator:(NSString *)string {
    return ([string isEqualToString:PlusSign] || [string isEqualToString:MinusSign] || [string isEqualToString:DivideSign] || [string isEqualToString:MultiplySign] || [string isEqualToString:CustomMultiplySign] || [string isEqualToString:CustomDivideSign]);
}

- (BOOL)isStringAnDigitPart:(NSString *)string {
    return (string.integerValue || [string isEqualToString:ZeroSign]|| [string isEqualToString:TripleZeroSign] || [string isEqualToString:DotSign]);
}


#pragma mark - Private

- (NSNumberFormatter *)createFormatter {
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:MaximumFractionDigits];
    return numberFormatter;
}

- (void)handleZeroLengthExpression:(NSMutableString *)expression withOperand:(NSString *)operand {
    if ([operand isEqualToString:DotSign]) {
        [expression appendFormat:@"%@%@", ZeroSign, DotSign];
    } else if ([operand isEqualToString:TripleZeroSign]) {
        [expression appendString:ZeroSign];
    } else {
        [expression appendString:operand];
    }
}

- (void)handleInitialOperationsInExpression:(NSMutableString *)expression operation:(NSString *)operator {
    if (![self isStringAnOperator:expression]) {
        [expression appendString:operator];
    } else if ([self isOperationAllowed:operator]) {
        if (!expression.length) {
            [expression appendString:operator];
        } else {
            [expression replaceCharactersInRange:NSMakeRange(0, 1) withString:operator];
        }
    }
}

- (NSRange)operandRangeWithCursorPosition:(NSRange)cursor inString:(NSString *)string {
    BOOL isValidCursor = cursor.location <= string.length;
    BOOL isStringValid = string.length;
    if (isStringValid && isValidCursor) {
        NSUInteger operandBeginLocation = cursor.location;
        NSUInteger operandEndLocation = cursor.location + cursor.length;
        //Seraching bounds of operand
        //to left
        if (cursor.location != 0) {
            for (int i = (int)cursor.location - 1; i >= 0; i--) {
                NSString *charString = [string substringWithRange:NSMakeRange((NSUInteger)i, 1)];
                operandBeginLocation = i;
                if ([self isStringAnOperator:charString]) {
                    operandBeginLocation = i + 1;
                    break;
                }
            }
        }
        //to right
        if (!(cursor.location > string.length - 1)) {
            for (int i = (int)(cursor.location + cursor.length); i < string.length; i++) {
                NSString *charString = [string substringWithRange:NSMakeRange((NSUInteger)i, 1)];
                operandEndLocation = i + 1;
                if ([self isStringAnOperator:charString]) {
                    operandEndLocation = i;
                    break;
                }
            }
        }
        NSUInteger length = (operandEndLocation - operandBeginLocation);
        return NSMakeRange(operandBeginLocation, length);
    }
    return cursor;
}


- (BOOL)isStringAnZeroSign:(NSString *)string {
    return ([string isEqualToString:ZeroSign] || [string isEqualToString:TripleZeroSign]);
}

- (BOOL)isOperationAllowed:(NSString *)operation {
    return ([operation isEqualToString:MinusSign] || [operation isEqualToString:PlusSign]);
}

@end

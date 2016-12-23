//
//  KeyboardConstans.h
//  KeyboardCalculator
//
//  Created by Evan Kostromin on 12/22/16.
//  Copyright © 2016 IvanKostromin. All rights reserved.
//

#ifndef KeyboardConstans_h
#define KeyboardConstans_h


#pragma mark - Validation

static NSString *const MathExpresionRegEx = @"^([-+/*]?\\d+(\\.\\d+)?)*";

#pragma mark - Number Formating

static NSInteger const MaximumFractionDigits = 10;

#pragma mark - Signs

static NSString *const PlusSign = @"+";
static NSString *const MinusSign = @"-";
static NSString *const CustomMultiplySign = @"×";
static NSString *const MultiplySign = @"*";
static NSString *const CustomDivideSign = @"÷";
static NSString *const DivideSign = @"/";
static NSString *const DotSign = @".";
static NSString *const RangeSign = @",";
static NSString *const TripleZeroSign = @"000";
static NSString *const ZeroSign = @"0";
static NSString *const EqualsSign = @"=";
static NSString *const DoneText = @"Done";

#pragma mark - Error

static NSString *const KeyBoardErrorDomain = @"KeyboardViewErrorDomain";
static NSInteger const ErrorCode = 1400;

typedef enum : NSUInteger {
    Zero = 0,
    One,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Dot,
    TripleZero = 1000,
} Digit;


typedef enum : NSUInteger {
    Plus = TripleZero + 1,
    Minus,
    Multiply,
    Divide,
} Operations;

#endif /* KeyboardConstans_h */

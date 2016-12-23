//
//  KeyboardView.m
//  KeyboardCalculator
//
//  Created by Evan Kostromin on 12/20/16.
//  Copyright © 2016 IvanKostromin. All rights reserved.
//

#import "KeyboardView.h"
#import "InputComposer.h"
#import "KeyboardConstans.h"

@implementation KeyboardColorScheme

+ (instancetype)initiWithColorsForTitles:(UIColor *)titles operators:(UIColor *)operators digits:(UIColor *)digits {
    KeyboardColorScheme *scheme = [[KeyboardColorScheme alloc] init];
    if (scheme) {
        scheme.titlesColor = titles;
        scheme.operatorsColor = operators;
        scheme.digitsColor = digits;
    }
    return scheme;
}

@end

@interface KeyboardView ()

@property (strong, nonatomic) IBOutletCollection (UIButton) NSArray *digitButtons;
@property (strong, nonatomic) IBOutletCollection (UIButton) NSArray *operationButtons;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;

@property (strong, nonatomic) InputComposer *composer;

@property (strong, nonatomic) NSError *calculationError;
@property (nonatomic) BOOL isCalculating;

@end

@implementation KeyboardView

#pragma mark - Lifecycle

- (instancetype)init {
    self = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil].firstObject;
    if (self) {
        _composer = [[InputComposer alloc] init];
        
    }
    return self;
}

- (instancetype)initWithColorScheme:(KeyboardColorScheme *)scheme {
    self = [self init];
    if (self) {
        _colorScheme = scheme;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupButtonsBorders];
}

#pragma mark - CustomMutators

- (void)setTextField:(UITextField *)textField {
    
    if (_textField) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UITextFieldTextDidChangeNotification object:_textField];
    }
    _textField = textField;
    _textField.inputView = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFiledDidChangeText:) name:UITextFieldTextDidChangeNotification object:_textField];
    
    //UITextFieldTextDidChangeNotification
}

- (void)setColorScheme:(KeyboardColorScheme *)colorScheme {
    _colorScheme = colorScheme;
    [self setupColors];
}

- (void)setCalculationError:(NSError *)calculationError {
    _calculationError = calculationError;
    [self.textField setTextColor:calculationError ? [UIColor redColor] : [UIColor blackColor]];
    if (calculationError) {
        [self.textField setTextColor:[UIColor redColor]];
        NSLog(@"Description: %@, FailReason: %@, RecoverySugesstion: %@", self.calculationError.localizedDescription, self.calculationError.localizedFailureReason, self.calculationError.localizedRecoverySuggestion);
    } else {
        [self.textField setTextColor:[UIColor blackColor]];
    }
}

#pragma mark - IBActions

- (IBAction)digitTap:(UIButton *)sender {
    self.calculationError = nil;
    [self processDigitInput:[self digitSignFromTag:sender.tag]];
}

- (IBAction)operationTap:(UIButton *)sender {
    self.calculationError = nil;
    [self processOperationInput:[self operationSignFromTag:sender.tag]];
}

- (IBAction)deleteTap:(UIButton *)sender {
    self.calculationError = nil;
    [self processDeleteOperation];
}

- (IBAction)clearTap:(UIButton *)sender {
    self.calculationError = nil;
    self.textField.text = @"";
}

- (IBAction)returnTap:(id)sender {
    if (self.isCalculating) {
        NSString *normalizedExpressionString = [self replaceCustomOperationSigns:self.textField.text];
        NSString *calculationResult = [self calculateExpression:normalizedExpressionString];
        if (calculationResult.length) {
            self.isCalculating = NO;
            self.textField.text = [self.composer formatString:calculationResult];
        }
        [self.returnButton setTitle:DoneText forState:UIControlStateNormal];
    } else {
        [self.textField resignFirstResponder];
    }
}

#pragma mark - Private

- (void)processDigitInput:(NSString *)digit {
    
    NSMutableString *copyText = [self.textField.text mutableCopy];
    NSRange cursorPosition = [self getCursorPosition];
    __weak typeof(self)weakSelf = self;
    [self.composer addOperand:digit to:copyText inRange:cursorPosition completion:^(BOOL success, NSError *error, NSString *validString, NSRange relativeStringRange) {
        weakSelf.textField.text = validString;
    }];
}

- (void)processOperationInput:(NSString *)operation
{
    self.isCalculating = YES;
    [self.returnButton setTitle:EqualsSign forState:UIControlStateNormal];
    NSMutableString *copyText = [self.textField.text mutableCopy];
    NSRange cursorPosition = [self getCursorPosition];
    __weak typeof(self)weakSelf = self;
    [self.composer addOperation:operation to:copyText inRange:cursorPosition completion:^(BOOL success, NSError *error, NSString *validString, NSRange relativeStringRange) {
        weakSelf.textField.text = validString;
    }];
}

- (void)processDeleteOperation
{
    NSMutableString *copyText = [self.textField.text mutableCopy];
    NSRange cursorPosition = [self getCursorPosition];
    __weak typeof(self)weakSelf = self;
    [self.composer deleteStringInRange:cursorPosition inString:copyText completion:^(BOOL success, NSError *error, NSString *validString, NSRange relativeStringRange) {
        weakSelf.textField.text = validString;
    }];    
}

- (NSRange)getCursorPosition
{
    UITextRange* range = self.textField.selectedTextRange;
    NSInteger location = [self.textField offsetFromPosition:self.textField.beginningOfDocument toPosition:range.start];
    NSInteger length = [self.textField offsetFromPosition:range.start toPosition:range.end];
    NSAssert(location >= 0, @"Location is valid.");
    NSAssert(length >= 0, @"Length is valid.");
    return NSMakeRange(location, length);
}

- (NSString *)replaceCustomOperationSigns:(NSString *)string
{
    NSString * result = [string stringByReplacingOccurrencesOfString:CustomMultiplySign withString:MultiplySign];
    result = [result stringByReplacingOccurrencesOfString:CustomDivideSign withString:DivideSign];
    result = [result stringByReplacingOccurrencesOfString:RangeSign withString:@""];
    return result;
}

#pragma mark UISetup

- (void)setupButtonsBorders {
    [self.digitButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL * _Nonnull stop) {
        [self setupBordersForButton:button];
            }];
    [self.operationButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL * _Nonnull stop) {
        [self setupBordersForButton:button];
    }];
    [self setupBordersForButton:self.deleteButton];
}

- (void)setupBordersForButton:(UIButton *)button {
    button.layer.borderWidth = 0.5;
    button.layer.borderColor = [UIColor colorWithWhite:0.83 alpha:1.0].CGColor;
}

- (void)setupColors {
    [self.digitButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL * _Nonnull stop) {
        [self  setTitleColor:self.colorScheme.titlesColor backgroundColor:self.colorScheme.digitsColor forButton:button];
    }];
    [self.operationButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL * _Nonnull stop) {
        [self  setTitleColor:self.colorScheme.titlesColor backgroundColor:self.colorScheme.operatorsColor forButton:button];
    }];
    [self setTitleColor:self.colorScheme.digitsColor  backgroundColor:self.colorScheme.titlesColor forButton:self.returnButton];
    [self setTitleColor:self.colorScheme.titlesColor backgroundColor:self.colorScheme.operatorsColor forButton:self.deleteButton];
}

- (void)setTitleColor:(UIColor *)title backgroundColor:(UIColor *)background forButton:(UIButton *)button {
    [button setBackgroundColor:background];
    [button setTitleColor:title forState:UIControlStateNormal];
    [button setTintColor:title];
}

#pragma mark Calculator

- (NSString *)operationSignFromTag:(NSUInteger)tag {
    switch (tag) {
        case Plus: return PlusSign;
        case Minus: return MinusSign;
        case Multiply: return CustomMultiplySign;
        case Divide: return CustomDivideSign;
        default: return @"";
            break;
    }
}

- (NSString *)digitSignFromTag:(NSUInteger)tag {
    switch (tag) {
        case Zero:
        case One:
        case Two:
        case Three:
        case Four:
        case Five:
        case Six:
        case Seven:
        case Eight:
        case Nine: return [NSString stringWithFormat:@"%lu", tag];
        case Dot: return DotSign;
        case TripleZero: return TripleZeroSign;
        default: return @"";
            break;
    }
}

- (NSString *)calculateExpression:(NSString *)expression {
    NSMutableArray *operators = [NSMutableArray new];
    NSMutableArray *operands  = [self operandsAndOperators:&operators fromString:expression];
    
    if (![self validateOperands:operands]) {
        self.calculationError = [NSError errorWithDomain:KeyBoardErrorDomain code:ErrorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Expression validation failure.", nil),
              NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Expression contains invalid symbols or symbols combinations", nil),
              NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please review expression", nil)}];
        return @"";
    }
    if (operators.count >= operands.count) {
        self.calculationError = [NSError errorWithDomain:KeyBoardErrorDomain code:ErrorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Calculation failure.", nil),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"To many operators", nil),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please review expression and add some digits!", nil)}];
        return @"";
    }
    if (!(operands.count && operators.count)) {
        self.calculationError = [NSError errorWithDomain:KeyBoardErrorDomain code:ErrorCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Calculation failure.", nil),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Couldn't find any digits or operations", nil),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please enter some digits and operations!", nil)}];
        return @"";
    }
    if ((operands.count == 1) && !operators.count) {
        return [operands firstObject];
    }
    //calculating separated operators and operands
    __block NSString *result = operands.firstObject;
    [operators enumerateObjectsUsingBlock:^(NSString *operator, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *operand = (NSString *)[operands objectAtIndex:idx + 1];
        result = [result stringByAppendingFormat:@"%@%@", operator, operand];
        NSExpression *calculableExpression = [NSExpression expressionWithFormat:result];
        id calculationResult = [calculableExpression expressionValueWithObject:nil context:nil];
        result = [NSString stringWithFormat:@"%@", calculationResult];
    }];
    self.calculationError = nil;
    return result;
}
- (NSMutableArray *)operandsAndOperators:(NSMutableArray **)operators fromString:(NSString *)string {
    
    NSMutableString *operand = [NSMutableString new];
    NSMutableArray *operands = [NSMutableArray new];
    BOOL isFirstSymbolAnOperation = [self.composer isStringAnOperator:[string substringWithRange:NSMakeRange(0, 1)]];
    BOOL isLastSymbolAnOperation = [self.composer isStringAnOperator:[string substringWithRange:NSMakeRange((string.length - 1), 1)]];
    
    for (int i = 0; i < string.length; i++) {
        NSString *character = [string substringWithRange:NSMakeRange(i, 1)];
        if ([self.composer isStringAnDigitPart:character]) {
            [operand appendString:character];
        } else if ([self.composer isStringAnOperator:character])  {
            [*operators addObject:character];
            if (operand.length) {
                [operands addObject:operand];
            }
            operand = [NSMutableString new];
        }
    }
    //include last operand into array
    if (operand.length) {
        [operands addObject:operand];
    }
    if (isLastSymbolAnOperation) {
        [*operators removeLastObject];
    }
    if (isFirstSymbolAnOperation) {
        NSMutableString *newFirstOperand = [operands firstObject];
        NSMutableString *firstOperation = [*operators firstObject];
        [newFirstOperand insertString:firstOperation atIndex:0];
        [*operators removeObjectAtIndex:0];
    }
    return operands;
}

- (BOOL)validateOperands:(NSMutableArray *)operands {
    __block BOOL validOperands = YES;
    [operands enumerateObjectsUsingBlock:^(NSString  *_Nonnull operand, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self isValidOperand:operand]) {
            validOperands = NO;
            *stop = YES;
        }
    }];
    return validOperands;
}

- (BOOL)isValidOperand:(NSString *)operand {
    BOOL isValid = NO;
    NSArray *operandComponents = [operand componentsSeparatedByString:DotSign];
    if (operandComponents.count <= 2) {
        isValid = YES;
    }
    //TODO: extra validation rules maybe in separate class
    
    return isValid;
}

#pragma mark - Notfications

- (void)textFiledDidChangeText:(NSNotification *)notification {
    NSLog(@"%@", notification);
    
    //TODO:additions to paste input
}

@end

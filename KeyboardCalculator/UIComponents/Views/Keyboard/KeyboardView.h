//
//  KeyboardView.h
//  KeyboardCalculator
//
//  Created by Evan Kostromin on 12/20/16.
//  Copyright © 2016 IvanKostromin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeyboardColorScheme : NSObject

@property (strong, nonatomic) UIColor *titlesColor;
@property (strong, nonatomic) UIColor *operatorsColor;
@property (strong, nonatomic) UIColor *digitsColor;

+ (instancetype)initiWithColorsForTitles:(UIColor *)titles operators:(UIColor *)operators digits:(UIColor *)digits;

@end

@interface KeyboardView : UIView

@property (weak, nonatomic) UITextField *textField;
@property (strong, nonatomic) KeyboardColorScheme *colorScheme;

- (instancetype)init;
- (instancetype)initWithColorScheme:(KeyboardColorScheme *)scheme;

@end


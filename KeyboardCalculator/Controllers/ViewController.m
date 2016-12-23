//
//  ViewController.m
//  KeyboardCalculator
//
//  Created by Evan Kostromin on 12/23/16.
//  Copyright © 2016 IvanKostromin. All rights reserved.
//

#import "ViewController.h"
#import "KeyboardView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    KeyboardView *inputView = [[KeyboardView alloc] init];
    inputView.colorScheme = [KeyboardColorScheme initiWithColorsForTitles:[UIColor whiteColor] operators:[UIColor grayColor] digits:[UIColor blackColor]];
    inputView.textField = self.textField;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

@end

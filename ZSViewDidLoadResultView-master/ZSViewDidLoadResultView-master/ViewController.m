//
//  ViewController.m
//  ZSViewDidLoadResultView-master
//
//  Created by safiri on 2018/8/8.
//  Copyright © 2018年 safiri. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+ZSLoadResultHint.h"

@interface ViewController ()<LoadResultDelegate,LoadResultDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loadResultDataSource = self;
    self.loadResultDelegate = self;
    
}
- (IBAction)showAndReloadLoadResultHintButtonClick:(id)sender {
    [self showAndReloadLoadResultHint];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

#pragma mark - LoadResultDataSource
- (NSAttributedString *)titleForLoadResultHint:(UIViewController *)viewController {
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    [attributes setObject:[UIFont fontWithName:@"HelveticaNeue-Medium" size:16.0] forKey:NSFontAttributeName];
    [attributes setObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:@"加载失败" attributes:attributes];
}
- (NSAttributedString *)descriptionForLoadResultHint:(UIViewController *)viewController {
    NSString *text = @"This allows you to share photos from your library and save photos to your camera roll.";
    UIFont *font = [UIFont systemFontOfSize:14.0];
    UIColor *textColor = [UIColor lightGrayColor];
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.lineSpacing = 2.0;
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    if (paragraph) [attributes setObject:paragraph forKey:NSParagraphStyleAttributeName];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    return attributedString;
}

- (UIImage *)imageForLoadResultHint:(UIViewController *)viewController {
    return [UIImage imageNamed:@"placeholder_dropbox"];
}

- (NSAttributedString *)buttonTitleForLoadResultHint:(UIViewController *)viewController forState:(UIControlState)state {
    NSString *text = @"Refresh";
    UIFont *font = [UIFont systemFontOfSize:16.0];
    UIColor *textColor = [UIColor blueColor];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)buttonBackgroundImageForLoadResultHint:(UIViewController *)viewController forState:(UIControlState)state {
    NSString *imageName;
    if (state == UIControlStateNormal) imageName = @"button_background_foursquare_normal";
    if (state == UIControlStateHighlighted) imageName = @"button_background_foursquare_highlight";
    
    UIEdgeInsets capInsets = UIEdgeInsetsMake(25.0, 25.0, 25.0, 25.0);
    UIEdgeInsets rectInsets = UIEdgeInsetsMake(0.0, 10, 0.0, 10);
    
    UIImage *image = [UIImage imageNamed:imageName];
    return [[image resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}


- (UIColor *)backgroundColorForLoadResultHint:(UIViewController *)viewController {
    return [UIColor brownColor];
}

#pragma mark - LoadResultDelegate Methods

- (void)loadResultHint:(UIViewController *)viewController didTapButton:(UIButton *)button {
    [self hideLoadResultHint];
}
- (void)loadResultHint:(UIViewController *)viewController didTapView:(UIView *)view {
    NSLog(@"tap loadResultHint");
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

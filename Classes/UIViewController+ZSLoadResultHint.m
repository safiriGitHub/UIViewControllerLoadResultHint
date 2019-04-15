//
//  UIViewController+ZSLoadResultHint.m
//  ZSViewDidLoadResultView-master
//
//  Created by safiri on 2018/8/8.
//  Copyright © 2018年 safiri. All rights reserved.
//

#import "UIViewController+ZSLoadResultHint.h"
#import <objc/runtime.h>

//MARK: - NSObject - lrhWeakObjectContainer
@interface ZSWeakObjectContainer : NSObject

@property (nonatomic, readonly, weak) id weakObject;

- (instancetype)initWithWeakObject:(id)object;

@end

@implementation ZSWeakObjectContainer

- (instancetype)initWithWeakObject:(id)object
{
    self = [super init];
    if (self) {
        _weakObject = object;
    }
    return self;
}

@end

//MARK: - interface - ZSResultHintView
@interface ZSResultHintView : UIView

@property (nonatomic, weak) UIViewController *ownerVC;
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *detailLabel;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIButton *button;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property (nonatomic, assign) CGFloat verticalOffset;
@property (nonatomic, assign) CGFloat verticalSpace;

@property (nonatomic, assign) BOOL fadeInOnDisplay;

- (void)setupConstraints;
- (void)prepareForReuse;

@end

//MARK: - extension - UIViewController
@interface UIViewController() <UIGestureRecognizerDelegate>
@property (nonatomic, readonly) ZSResultHintView *resultHintView;
@end

//MARK: - category imp - UIViewController
static char const * const kLoadResultHintDataSource =     "loadResultHintDataSource";
static char const * const kLoadResultHintDelegate =   "loadResultHintDelegate";
static char const * const kLoadResultHintView =       "loadResultHintView";
#define kEmptyImageViewAnimationKey @"com.dzn.emptyDataSet.imageViewAnimation"

@implementation UIViewController (ZSLoadResultHint)

//MARK: Getters (Public)
- (id<LoadResultDataSource>)loadResultDataSource {
    ZSWeakObjectContainer *container = objc_getAssociatedObject(self, kLoadResultHintDataSource);
    return container.weakObject;
}

- (id<LoadResultDelegate>)loadResultDelegate {
    ZSWeakObjectContainer *container = objc_getAssociatedObject(self, kLoadResultHintDelegate);
    return container.weakObject;
}

- (BOOL)isLoadResultHintVisible {
    UIView *view = objc_getAssociatedObject(self, kLoadResultHintView);
    return view ? !view.hidden : NO;
}

//MARK: Getters (Private)
- (ZSResultHintView *)resultHintView {
    ZSResultHintView *view = objc_getAssociatedObject(self, kLoadResultHintView);
    
    if (!view) {
        view = [ZSResultHintView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.hidden = YES;
        view.ownerVC = self;
        
        view.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(lrh_didTapContentView:)];
        view.tapGesture.delegate = self;
        [view addGestureRecognizer:view.tapGesture];
        
        [self setResultHintView:view];
    }
    return view;
}

- (BOOL)lrh_canDisplay {
    return self.loadResultDataSource && [self.loadResultDataSource conformsToProtocol:@protocol(LoadResultDataSource)];
}

//MARK: Setters (Public)
- (void)setLoadResultDataSource:(id<LoadResultDataSource>)loadResultDataSource {
    
    if (!loadResultDataSource || ![self lrh_canDisplay]) {
        [self lrh_invalidate];
    }
    
    objc_setAssociatedObject(self, kLoadResultHintDataSource, [[ZSWeakObjectContainer alloc] initWithWeakObject:loadResultDataSource], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setLoadResultDelegate:(id<LoadResultDelegate>)loadResultDelegate {
    if (!loadResultDelegate) {
        [self lrh_invalidate];
    }
    
    objc_setAssociatedObject(self, kLoadResultHintDelegate, [[ZSWeakObjectContainer alloc] initWithWeakObject:loadResultDelegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//MARK: Setters (Private)
- (void)setResultHintView:(ZSResultHintView *)resultHintView {
    objc_setAssociatedObject(self, kLoadResultHintView, resultHintView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//MARK: Reload Methods (Public)
- (void)showAndReloadLoadResultHint {
    [self lrh_reload];
}
- (void)showAndReloadLoadResultHintToFront {
    [self lrh_reload];
    [self.view bringSubviewToFront:self.resultHintView];
}

- (void)hideLoadResultHint {
    [self lrh_invalidate];
}
//MARK: Reload Methods (Private)
- (void)lrh_reload {
    if (![self lrh_canDisplay]) {
        return;
    }
    
    if ([self lrh_shouldDisplay] || [self lrh_shouldBeForcedToDisplay]) {
        [self lrh_willAppear];
        
        ZSResultHintView *view = self.resultHintView;
        view.fadeInOnDisplay = [self lrh_shouldFadeIn];
        if (!view.superview) {
            if (self.view.subviews.count > 1) {
                [self.view insertSubview:view atIndex:0];
            }else {
                [self.view addSubview:view];
            }
        }
        
        // Removing view resetting the view and its constraints it very important to guarantee a good state
        [view prepareForReuse];
        
        UIView *customView = [self lrh_customView];
        if (customView) {
            view.customView = customView;
        }else {
            // Get the data from the data source
            NSAttributedString *titleLabelString = [self lrh_titleLabelString];
            NSAttributedString *detailLabelString = [self lrh_detailLabelString];
            
            UIImage *buttonImage = [self lrh_buttonImageForState:UIControlStateNormal];
            NSAttributedString *buttonTitle = [self lrh_buttonTitleForState:UIControlStateNormal];
            
            UIImage *image = [self lrh_image];
            UIColor *imageTintColor = [self lrh_imageTintColor];
            UIImageRenderingMode renderingMode = imageTintColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
            
            view.verticalSpace = [self lrh_verticalSpace];
            
            // Configure Image
            if (image) {
                if ([image respondsToSelector:@selector(imageWithRenderingMode:)]) {
                    view.imageView.image = [image imageWithRenderingMode:renderingMode];
                    view.imageView.tintColor = imageTintColor;
                }
                else {
                    // iOS 6 fallback: insert code to convert imaged if needed
                    view.imageView.image = image;
                }
            }
            
            // Configure title label
            if (titleLabelString) {
                view.titleLabel.attributedText = titleLabelString;
            }
            
            // Configure detail label
            if (detailLabelString) {
                view.detailLabel.attributedText = detailLabelString;
            }
            
            // Configure button
            if (buttonImage) {
                [view.button setImage:buttonImage forState:UIControlStateNormal];
                [view.button setImage:[self lrh_buttonImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            }
            else if (buttonTitle) {
                [view.button setAttributedTitle:buttonTitle forState:UIControlStateNormal];
                [view.button setAttributedTitle:[self lrh_buttonTitleForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
                [view.button setBackgroundImage:[self lrh_buttonBackgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
                [view.button setBackgroundImage:[self lrh_buttonBackgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            }
        }
        
        // Configure offset
        view.verticalOffset = [self lrh_verticalOffset];
        
        // Configure the empty dataset view
        view.backgroundColor = [self lrh_backgroundColor];
        view.hidden = NO;
        view.clipsToBounds = YES;
        
        // Configure  userInteraction permission
        view.userInteractionEnabled = [self lrh_isTouchAllowed];
        
        [view setupConstraints];
        
        [UIView performWithoutAnimation:^{
            [view layoutIfNeeded];
        }];
        
        // Configure image view animation
        if ([self lrh_isImageViewAnimateAllowed])
        {
            CAAnimation *animation = [self lrh_imageAnimation];
            
            if (animation) {
                [self.resultHintView.imageView.layer addAnimation:animation forKey:kEmptyImageViewAnimationKey];
            }
        }
        else if ([self.resultHintView.imageView.layer animationForKey:kEmptyImageViewAnimationKey]) {
            [self.resultHintView.imageView.layer removeAnimationForKey:kEmptyImageViewAnimationKey];
        }
        
        // Notifies that the empty dataset view did appear
        [self lrh_didAppear];
    }
}
- (void)lrh_invalidate {
    [self lrh_willDisappear];
    
    if (self.resultHintView) {
        [self.resultHintView prepareForReuse];
        [self.resultHintView removeFromSuperview];
        
        [self setResultHintView:nil];
    }
    
    [self lrh_didDisappear];
}

//MARK: Data Source Getters
- (NSAttributedString *)lrh_titleLabelString {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(titleForLoadResultHint:)]) {
        NSAttributedString *string = [self.loadResultDataSource titleForLoadResultHint:self];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -titleForLoadResultHint:");
        return string;
    }
    return nil;
}

- (NSAttributedString *)lrh_detailLabelString {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(descriptionForLoadResultHint:)]) {
        NSAttributedString *string = [self.loadResultDataSource descriptionForLoadResultHint:self];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -descriptionForLoadResultHint:");
        return string;
    }
    return nil;
}

- (UIImage *)lrh_image {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(imageForLoadResultHint:)]) {
        UIImage *image = [self.loadResultDataSource imageForLoadResultHint:self];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -imageForLoadResultHint:");
        return image;
    }
    return nil;
}

- (CAAnimation *)lrh_imageAnimation {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(imageAnimationForLoadResultHint:)]) {
        CAAnimation *imageAnimation = [self.loadResultDataSource imageAnimationForLoadResultHint:self];
        if (imageAnimation) NSAssert([imageAnimation isKindOfClass:[CAAnimation class]], @"You must return a valid CAAnimation object for -imageAnimationForLoadResultHint:");
        return imageAnimation;
    }
    return nil;
}

- (UIColor *)lrh_imageTintColor {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(imageTintColorForLoadResultHint:)]) {
        UIColor *color = [self.loadResultDataSource imageTintColorForLoadResultHint:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"You must return a valid UIColor object for -imageTintColorForLoadResultHint:");
        return color;
    }
    return nil;
}

- (NSAttributedString *)lrh_buttonTitleForState:(UIControlState)state {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(buttonTitleForLoadResultHint:forState:)]) {
        NSAttributedString *string = [self.loadResultDataSource buttonTitleForLoadResultHint:self forState:state];
        if (string) NSAssert([string isKindOfClass:[NSAttributedString class]], @"You must return a valid NSAttributedString object for -buttonTitleForLoadResultHint:forState:");
        return string;
    }
    return nil;
}

- (UIImage *)lrh_buttonImageForState:(UIControlState)state {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(buttonImageForLoadResultHint:forState:)]) {
        UIImage *image = [self.loadResultDataSource buttonImageForLoadResultHint:self forState:state];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -buttonImageForLoadResultHint:forState:");
        return image;
    }
    return nil;
}

- (UIImage *)lrh_buttonBackgroundImageForState:(UIControlState)state {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(buttonBackgroundImageForLoadResultHint:forState:)]) {
        UIImage *image = [self.loadResultDataSource buttonBackgroundImageForLoadResultHint:self forState:state];
        if (image) NSAssert([image isKindOfClass:[UIImage class]], @"You must return a valid UIImage object for -buttonBackgroundImageForLoadResultHint:forState:");
        return image;
    }
    return nil;
}

- (UIColor *)lrh_backgroundColor {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(backgroundColorForLoadResultHint:)]) {
        UIColor *color = [self.loadResultDataSource backgroundColorForLoadResultHint:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"You must return a valid UIColor object for -backgroundColorForLoadResultHint:");
        return color;
    }
    return [UIColor clearColor];
}

- (UIView *)lrh_customView {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(customViewForLoadResultHint:)]) {
        UIView *view = [self.loadResultDataSource customViewForLoadResultHint:self];
        if (view) NSAssert([view isKindOfClass:[UIView class]], @"You must return a valid UIView object for -customViewForLoadResultHint:");
        return view;
    }
    return nil;
}

- (CGFloat)lrh_verticalOffset {
    
    CGFloat offset = 0.0;
    
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(verticalOffsetForLoadResultHint:)]) {
        offset = [self.loadResultDataSource verticalOffsetForLoadResultHint:self];
    }
    return offset;
}

- (CGFloat)lrh_verticalSpace {
    if (self.loadResultDataSource && [self.loadResultDataSource respondsToSelector:@selector(spaceHeightForLoadResultHint:)]) {
        return [self.loadResultDataSource spaceHeightForLoadResultHint:self];
    }
    return 0.0;
}

//MARK: Delegate Getters & Events (Private)
- (BOOL)lrh_shouldFadeIn {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintShouldFadeIn:)]) {
        return [self.loadResultDelegate loadResultHintShouldFadeIn:self];
    }
    return YES;
}

- (BOOL)lrh_shouldDisplay {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintShouldDisplay:)]) {
        return [self.loadResultDelegate loadResultHintShouldDisplay:self];
    }
    return YES;
}

- (BOOL)lrh_shouldBeForcedToDisplay {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintShouldBeForcedToDisplay:)]) {
        return [self.loadResultDelegate loadResultHintShouldBeForcedToDisplay:self];
    }
    return NO;
}

- (BOOL)lrh_isTouchAllowed {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintShouldAllowTouch:)]) {
        return [self.loadResultDelegate loadResultHintShouldAllowTouch:self];
    }
    return YES;
}

- (BOOL)lrh_isImageViewAnimateAllowed {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintShouldAnimateImageView:)]) {
        return [self.loadResultDelegate loadResultHintShouldAnimateImageView:self];
    }
    return NO;
}

- (void)lrh_willAppear {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintWillAppear:)]) {
        [self.loadResultDelegate loadResultHintWillAppear:self];
    }
}

- (void)lrh_didAppear {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintDidAppear:)]) {
        [self.loadResultDelegate loadResultHintDidAppear:self];
    }
}

- (void)lrh_willDisappear {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintWillDisappear:)]) {
        [self.loadResultDelegate loadResultHintWillDisappear:self];
    }
}

- (void)lrh_didDisappear {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHintDidDisappear:)]) {
        [self.loadResultDelegate loadResultHintDidDisappear:self];
    }
}

- (void)lrh_didTapContentView:(id)sender {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHint:didTapView:)]) {
        [self.loadResultDelegate loadResultHint:self didTapView:sender];
    }
}

- (void)lrh_didTapDataButton:(id)sender {
    if (self.loadResultDelegate && [self.loadResultDelegate respondsToSelector:@selector(loadResultHint:didTapButton:)]) {
        [self.loadResultDelegate loadResultHint:self didTapButton:sender];
    }
}

//MARK: UIGestureRecognizerDelegate Methods
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.view isEqual:self.resultHintView]) {
        return [self lrh_isTouchAllowed];
    }
    return YES;
}
@end
//MARK: - category - UIView+ZSConstraintBasedLayoutExtensions
@interface UIView (ZSConstraintBasedLayoutExtensions)
- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view attribute:(NSLayoutAttribute)attribute;
@end
@implementation UIView (DZNConstraintBasedLayoutExtensions)

- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view attribute:(NSLayoutAttribute)attribute {
    return [NSLayoutConstraint constraintWithItem:view
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self
                                        attribute:attribute
                                       multiplier:1.0
                                         constant:0.0];
}

@end

//MARK: - implementation - ZSResultHintView
@implementation ZSResultHintView
@synthesize contentView = _contentView, titleLabel = _titleLabel, detailLabel = _detailLabel, imageView = _imageView, button = _button;

//MARK: Initialization Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview {
    CGRect superviewBounds = self.superview.bounds;
    self.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(superviewBounds), CGRectGetHeight(superviewBounds));
    
    if (self.fadeInOnDisplay) {
        [UIView animateWithDuration:0.25 animations:^{
            self.contentView.alpha = 1.0;
        }];
    }else {
        self.contentView.alpha = 1.0;
    }
}

//MARK: Getters
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.backgroundColor = [UIColor clearColor];
        _contentView.userInteractionEnabled = YES;
        _contentView.alpha = 0;
    }
    return _contentView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = NO;
        _imageView.accessibilityIdentifier = @"empty set background image";
        
        [_contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];
        
        _titleLabel.font = [UIFont systemFontOfSize:27.0];
        _titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.accessibilityIdentifier = @"empty set title";
        
        [_contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.backgroundColor = [UIColor clearColor];
        
        _detailLabel.font = [UIFont systemFontOfSize:17.0];
        _detailLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _detailLabel.numberOfLines = 0;
        _detailLabel.accessibilityIdentifier = @"empty set detail label";
        
        [_contentView addSubview:_detailLabel];
    }
    return _detailLabel;
}
- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.backgroundColor = [UIColor clearColor];
        _button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _button.accessibilityIdentifier = @"empty set button";
        
        [_button addTarget:self action:@selector(didClickButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [_contentView addSubview:_button];
    }
    return _button;
}

- (BOOL)canShowImage {
    return (_imageView.image && _imageView.superview);
}

- (BOOL)canShowTitle {
    return (_titleLabel.attributedText.string.length > 0 && _titleLabel.superview);
}

- (BOOL)canShowDetail {
    return (_detailLabel.attributedText.string.length > 0 && _detailLabel.superview);
}

- (BOOL)canShowButton {
    if ([_button attributedTitleForState:UIControlStateNormal].string.length > 0 || [_button imageForState:UIControlStateNormal]) {
        return (_button.superview != nil);
    }
    return NO;
}

// MARK: Setters
- (void)setCustomView:(UIView *)customView {
    if (!customView) {
        return;
    }
    
    if (_customView) {
        [_customView removeFromSuperview];
        _customView = nil;
    }
    
    _customView = customView;
    _customView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_customView];
}

//MARK: Action Methods

- (void)didClickButton:(id)sender {
    SEL selector = NSSelectorFromString(@"lrh_didTapDataButton:");
    
    if ([self.ownerVC respondsToSelector:selector]) {
        [self.ownerVC performSelector:selector withObject:sender afterDelay:0.0f];
    }
}

- (void)removeAllConstraints {
    [self removeConstraints:self.constraints];
    [_contentView removeConstraints:_contentView.constraints];
}

- (void)prepareForReuse {
    
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _titleLabel = nil;
    _detailLabel = nil;
    _imageView = nil;
    _button = nil;
    _customView = nil;
    
    [self removeAllConstraints];
}

//MARK:  Auto-Layout Configuration

- (void)setupConstraints {
    // First, configure the content view constaints
    // The content view must alway be centered to its superview
    NSLayoutConstraint *centerXConstraint = [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterX];
    NSLayoutConstraint *centerYConstraint = [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterY];
    
    [self addConstraint:centerXConstraint];
    [self addConstraint:centerYConstraint];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    
    // When a custom offset is available, we adjust the vertical constraints' constants
    if (self.verticalOffset != 0 && self.constraints.count > 0) {
        centerYConstraint.constant = self.verticalOffset;
    }
    
    // If applicable, set the custom view's constraints
    if (_customView) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[customView]|" options:0 metrics:nil views:@{@"customView":_customView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[customView]|" options:0 metrics:nil views:@{@"customView":_customView}]];
    }
    else {
        CGFloat width = CGRectGetWidth(self.frame) ? : CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat padding = roundf(width/16.0);
        CGFloat verticalSpace = self.verticalSpace ? : 11.0; // Default is 11 pts
        
        NSMutableArray *subviewStrings = [NSMutableArray array];
        NSMutableDictionary *views = [NSMutableDictionary dictionary];
        NSDictionary *metrics = @{@"padding": @(padding)};
        
        // Assign the image view's horizontal constraints
        if (_imageView.superview) {
            
            [subviewStrings addObject:@"imageView"];
            views[[subviewStrings lastObject]] = _imageView;
            
            [self.contentView addConstraint:[self.contentView equallyRelatedConstraintWithView:_imageView attribute:NSLayoutAttributeCenterX]];
        }
        
        // Assign the title label's horizontal constraints
        if ([self canShowTitle]) {
            
            [subviewStrings addObject:@"titleLabel"];
            views[[subviewStrings lastObject]] = _titleLabel;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[titleLabel(>=0)]-(padding@750)-|"
                                                                                     options:0 metrics:metrics views:views]];
        }
        // or removes from its superview
        else {
            [_titleLabel removeFromSuperview];
            _titleLabel = nil;
        }
        
        // Assign the detail label's horizontal constraints
        if ([self canShowDetail]) {
            
            [subviewStrings addObject:@"detailLabel"];
            views[[subviewStrings lastObject]] = _detailLabel;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[detailLabel(>=0)]-(padding@750)-|"
                                                                                     options:0 metrics:metrics views:views]];
        }
        // or removes from its superview
        else {
            [_detailLabel removeFromSuperview];
            _detailLabel = nil;
        }
        
        // Assign the button's horizontal constraints
        if ([self canShowButton]) {
            
            [subviewStrings addObject:@"button"];
            views[[subviewStrings lastObject]] = _button;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(padding@750)-[button(>=0)]-(padding@750)-|"
                                                                                     options:0 metrics:metrics views:views]];
        }
        // or removes from its superview
        else {
            [_button removeFromSuperview];
            _button = nil;
        }
        
        
        NSMutableString *verticalFormat = [NSMutableString new];
        
        // Build a dynamic string format for the vertical constraints, adding a margin between each element. Default is 11 pts.
        for (int i = 0; i < subviewStrings.count; i++) {
            
            NSString *string = subviewStrings[i];
            [verticalFormat appendFormat:@"[%@]", string];
            
            if (i < subviewStrings.count-1) {
                [verticalFormat appendFormat:@"-(%.f@750)-", verticalSpace];
            }
        }
        
        // Assign the vertical constraints to the content view
        if (verticalFormat.length > 0) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|%@|", verticalFormat]
                                                                                     options:0 metrics:metrics views:views]];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // Return any UIControl instance such as buttons, segmented controls, switches, etc.
    if ([hitView isKindOfClass:[UIControl class]]) {
        return hitView;
    }
    
    // Return either the contentView or customView
    if ([hitView isEqual:_contentView] || [hitView isEqual:_customView]) {
        return hitView;
    }
    
    return nil;
}
@end

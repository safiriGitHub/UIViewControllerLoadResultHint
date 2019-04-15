//
//  UIViewController+ZSLoadResultHint.h
//  ZSViewDidLoadResultView-master
//
//  Created by safiri on 2018/8/8.
//  Copyright © 2018年 safiri. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol LoadResultDataSource;
@protocol LoadResultDelegate;

/**
 当某个UIViewController页面显示后，无相应内容时展示给用户的提示，类似于https://github.com/dzenbot/DZNLoadResultHint
 */
@interface UIViewController (ZSLoadResultHint)

@property (nonatomic, weak, nullable) IBOutlet id <LoadResultDataSource> loadResultDataSource;

@property (nonatomic, weak, nullable) IBOutlet id <LoadResultDelegate> loadResultDelegate;

@property (nonatomic, readonly, getter = isLoadResultHintVisible) BOOL loadResultHintVisible;

/**
 在self.view底层显示提示视图
 */
- (void)showAndReloadLoadResultHint;
/**
 在self.view顶层显示提示视图
 */
- (void)showAndReloadLoadResultHintToFront;
- (void)hideLoadResultHint;

@end

@protocol LoadResultDataSource <NSObject>
@optional

/**
 Asks the data source for the title .
 The dataset uses a fixed font style by default, if no attributes are set. If you want a different font style, return a attributed string.
 
 @param viewController A viewController subclass object informing the data source.
 @return An attributed string for the dataset title, combining font, text color, text pararaph style, etc.
 */
- (nullable NSAttributedString *)titleForLoadResultHint:(UIViewController *)viewController;

/**
 Asks the data source for the description .
 The dataset uses a fixed font style by default, if no attributes are set. If you want a different font style, return a attributed string.
 
 @param viewController A viewController subclass object informing the data source.
 @return An attributed string for the dataset description text, combining font, text color, text pararaph style, etc.
 */
- (nullable NSAttributedString *)descriptionForLoadResultHint:(UIViewController *)viewController;

/**
 Asks the data source for the image .
 
 @param viewController A UIViewController subclass informing the data source.
 @return An image for the dataset.
 */
- (nullable UIImage *)imageForLoadResultHint:(UIViewController *)viewController;


/**
 Asks the data source for a tint color of the image dataset. Default is nil.
 
 @param viewController A viewController subclass object informing the data source.
 @return A color to tint the image of the dataset.
 */
- (nullable UIColor *)imageTintColorForLoadResultHint:(UIViewController *)viewController;

/**
 *  Asks the data source for the image animation of the dataset.
 *
 *  @param viewController A viewController subclass object informing the delegate.
 *
 *  @return image animation
 */
- (nullable CAAnimation *)imageAnimationForLoadResultHint:(UIViewController *)viewController;

/**
 Asks the data source for the title to be used for the specified button state.
 The dataset uses a fixed font style by default, if no attributes are set. If you want a different font style, return a attributed string.
 
 @param viewController A viewController subclass object informing the data source.
 @param state The state that uses the specified title. The possible values are described in UIControlState.
 @return An attributed string for the dataset button title, combining font, text color, text pararaph style, etc.
 */
- (nullable NSAttributedString *)buttonTitleForLoadResultHint:(UIViewController *)viewController forState:(UIControlState)state;

/**
 Asks the data source for the image to be used for the specified button state.
 This method will override buttonTitleForLoadResultHint:forState: and present the image only without any text.
 
 @param viewController A viewController subclass object informing the data source.
 @param state The state that uses the specified title. The possible values are described in UIControlState.
 @return An image for the dataset button imageview.
 */
- (nullable UIImage *)buttonImageForLoadResultHint:(UIViewController *)viewController forState:(UIControlState)state;

/**
 Asks the data source for a background image to be used for the specified button state.
 There is no default style for this call.
 
 @param viewController A viewController subclass informing the data source.
 @param state The state that uses the specified image. The values are described in UIControlState.
 @return An attributed string for the dataset button title, combining font, text color, text pararaph style, etc.
 */
- (nullable UIImage *)buttonBackgroundImageForLoadResultHint:(UIViewController *)viewController forState:(UIControlState)state;

/**
 Asks the data source for the background color of the dataset. Default is clear color.
 
 @param viewController A viewController subclass object informing the data source.
 @return A color to be applied to the dataset background view.
 */
- (nullable UIColor *)backgroundColorForLoadResultHint:(UIViewController *)viewController;

/**
 Asks the data source for a custom view to be displayed instead of the default views such as labels, imageview and button. Default is nil.
 Use this method to show an activity view indicator for loading feedback, or for complete custom empty data set.
 Returning a custom view will ignore -offsetForLoadResultHint and -spaceHeightForLoadResultHint configurations.
 
 @param viewController A viewController subclass object informing the delegate.
 @return The custom view.
 */
- (nullable UIView *)customViewForLoadResultHint:(UIViewController *)viewController;

/**
 Asks the data source for a offset for vertical alignment of the content. Default is 0.
 
 @param viewController A viewController subclass object informing the delegate.
 @return The offset for vertical alignment.
 */
- (CGFloat)verticalOffsetForLoadResultHint:(UIViewController *)viewController;

/**
 Asks the data source for a vertical space between elements. Default is 11 pts.
 
 @param viewController A viewController subclass object informing the delegate.
 @return The space height between elements.
 */
- (CGFloat)spaceHeightForLoadResultHint:(UIViewController *)viewController;

@end

/**
 The object that acts as the delegate of the LoadResultHint.
 @discussion The delegate can adopt the LoadResultDelegate protocol. The delegate is not retained. All delegate methods are optional.
 
 @discussion All delegate methods are optional. Use this delegate for receiving action callbacks.
 */
@protocol LoadResultDelegate <NSObject>
@optional

/**
 Asks the delegate to know if the LoadResultHint should fade in when displayed. Default is YES.
 
 @param viewController A viewController subclass object informing the delegate.
 @return YES if the LoadResultHint should fade in.
 */
- (BOOL)loadResultHintShouldFadeIn:(UIViewController *)viewController;

/**
 Asks the delegate to know if the LoadResultHint should still be displayed when had load content success. Default is NO
 
 @param viewController A viewController subclass object informing the delegate.
 @return YES if LoadResultHint should be forced to display
 */
- (BOOL)loadResultHintShouldBeForcedToDisplay:(UIViewController *)viewController;

/**
 Asks the delegate to know if the LoadResultHint should be rendered and displayed. Default is YES.
 
 @param viewController A viewController subclass object informing the delegate.
 @return YES if the LoadResultHint should show.
 */
- (BOOL)loadResultHintShouldDisplay:(UIViewController *)viewController;

/**
 Asks the delegate for touch permission. Default is YES.
 
 @param viewController A viewController subclass object informing the delegate.
 @return YES if the LoadResultHint receives touch gestures.
 */
- (BOOL)loadResultHintShouldAllowTouch:(UIViewController *)viewController;

/**
 Asks the delegate for image view animation permission. Default is NO.
 Make sure to return a valid CAAnimation object from imageAnimationForloadResultHint:
 
 @param viewController A viewController subclass object informing the delegate.
 @return YES if the LoadResultHint is allowed to animate
 */
- (BOOL)loadResultHintShouldAnimateImageView:(UIViewController *)viewController;

/**
 Tells the delegate that the LoadResultHint view was tapped.
 Use this method either to resignFirstResponder of a textfield or searchBar.
 
 @param viewController A viewController subclass informing the delegate.
 @param view the view tapped by the user
 */
- (void)loadResultHint:(UIViewController *)viewController didTapView:(UIView *)view;

/**
 Tells the delegate that the action button was tapped.
 
 @param viewController A viewController subclass informing the delegate.
 @param button the button tapped by the user
 */
- (void)loadResultHint:(UIViewController *)viewController didTapButton:(UIButton *)button;

/**
 Tells the delegate that the empty data set will appear.
 
 @param viewController A viewController subclass informing the delegate.
 */
- (void)loadResultHintWillAppear:(UIViewController *)viewController;

/**
 Tells the delegate that the empty data set did appear.
 
 @param viewController A viewController subclass informing the delegate.
 */
- (void)loadResultHintDidAppear:(UIViewController *)viewController;

/**
 Tells the delegate that the empty data set will disappear.
 
 @param viewController A viewController subclass informing the delegate.
 */
- (void)loadResultHintWillDisappear:(UIViewController *)viewController;

/**
 Tells the delegate that the empty data set did disappear.
 
 @param viewController A viewController subclass informing the delegate.
 */
- (void)loadResultHintDidDisappear:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

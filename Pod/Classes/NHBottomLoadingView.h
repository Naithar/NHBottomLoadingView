//
//  NHBottomLoadingView.h
//  Pods
//
//  Created by Sergey Minakov on 06.05.15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NHBottomLoadingViewState) {
    NHBottomLoadingViewStateLoading,
    NHBottomLoadingViewStateNoResults,
    NHBottomLoadingViewStateFinished,
    NHBottomLoadingViewStateFailed,
    NHBottomLoadingViewStateView
};

@interface NHBottomLoadingView : NSObject

@property (nonatomic, readonly, assign) NHBottomLoadingViewState viewState;


@property (nonatomic, copy) NSString *noResultText;
@property (nonatomic, strong) UIColor *noResultsTextColor;
@property (nonatomic, strong) UIFont *noResultsTextFont;

@property (nonatomic, copy) NSString *failedText;
@property (nonatomic, copy) NSString *failedNoConnectionText;
@property (nonatomic, strong) UIColor *failedTextColor;
@property (nonatomic, strong) UIFont *failedTextFont;

@property (nonatomic, assign) BOOL isLoading;

- (instancetype)initWithScrollView:(UIScrollView*)scrollView;

- (void)setState:(NHBottomLoadingViewState)state;
- (void)setState:(NHBottomLoadingViewState)state animated:(BOOL)animated;

- (void)setView:(UIView*)view forKey:(NSString*)key;
- (void)setView:(UIView*)view withHeight:(CGFloat)height forKey:(NSString*)key;
- (void)setViewWithKey:(NSString*)key;
- (void)setViewWithKey:(NSString*)key animated:(BOOL)animated;

- (void)stopRefreshing;

@end

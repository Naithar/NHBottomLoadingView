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

- (instancetype)initWithScrollView:(UIScrollView*)scrollView;

- (void)setState:(NHBottomLoadingViewState)state;
- (void)setState:(NHBottomLoadingViewState)state animated:(BOOL)animated;
@end

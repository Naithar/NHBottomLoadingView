//
//  NHBottomLoadingView.m
//  Pods
//
//  Created by Sergey Minakov on 06.05.15.
//
//

#import "NHBottomLoadingView.h"

@interface NHBottomLoadingView ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) NHBottomLoadingViewState viewState;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIImageView *loadingImageView;

@end

@implementation NHBottomLoadingView

- (instancetype)initWithScrollView:(UIScrollView*)scrollView {
    self = [super init];

    if (self) {
        _scrollView = scrollView;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _viewState = NHBottomLoadingViewStateLoading;

    [self setupLoadingView];

    [self setState:_viewState];
}

- (void)setupLoadingView {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 50)];
    self.loadingView.backgroundColor = [UIColor redColor];

    self.loadingImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.loadingImageView.backgroundColor = [UIColor greenColor];
    [self.loadingImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.loadingImageView.image = [UIImage imageNamed:@"NHBottomView.loading.png"];

    [self.loadingView addSubview:self.loadingImageView];

    [self.loadingView addConstraint:[NSLayoutConstraint constraintWithItem:self.loadingImageView
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.loadingView
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1.0
                                                                  constant:0]];

    [self.loadingView addConstraint:[NSLayoutConstraint constraintWithItem:self.loadingImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.loadingView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0]];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.toValue = @(M_PI * 2.0f);
    animation.duration = 0.75;
    animation.removedOnCompletion = NO;
    animation.cumulative = YES;
    animation.repeatCount = HUGE;

    [self.loadingImageView.layer addAnimation:animation forKey:@"rotation"];
}

- (void)setState:(NHBottomLoadingViewState)state {
    [self setState:state animated:NO];
}

- (void)setState:(NHBottomLoadingViewState)state animated:(BOOL)animated {
    if (state == NHBottomLoadingViewStateView) {
        return;
    }
    
    switch (state) {
        case NHBottomLoadingViewStateLoading:
            if ([self.scrollView isKindOfClass:[UITableView class]]) {
                ((UITableView*)self.scrollView).tableFooterView = self.loadingView;
            }
            break;
        default:
            break;
    }

    if (animated) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.scrollView layoutIfNeeded];
                         } completion:nil];
    }
    else {
        [self.scrollView layoutIfNeeded];
    }
    self.viewState = state;
}

- (UIView*)viewForCurrentState {
    return nil;
}

- (void)dealloc {

}

@end

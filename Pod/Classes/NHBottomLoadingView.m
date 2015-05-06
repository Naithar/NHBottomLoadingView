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

@property (nonatomic, strong) UIView *finishedView;

@property (nonatomic, strong) UIView *noResultsView;
@property (nonatomic, strong) UILabel *noResultsLabel;

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
    [self setupFinishedView];
    [self setupFailedView];
    [self setupNoResultsView];

    [self setState:_viewState];
}

- (void)setupFinishedView {
    self.finishedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
    self.finishedView.backgroundColor = [UIColor blackColor];
}

- (void)setupFailedView {

}

- (void)updateFiledView {

}

- (void)setupNoResultsView {
    self.noResultsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 50)];
    self.noResultsLabel.backgroundColor = [UIColor blueColor];

    self.noResultsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.noResultsLabel.numberOfLines = 0;
    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
    [self.noResultsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.noResultsLabel.backgroundColor = [UIColor grayColor];
    self.noResultsLabel.text = NSLocalizedStringFromTable(@"default.noresults", @"NHBottomLoadingView", nil);

    [self.noResultsView addSubview:self.noResultsLabel];

    [self.noResultsView addConstraint:[NSLayoutConstraint constraintWithItem:self.noResultsLabel
                                                                   attribute:NSLayoutAttributeLeft
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.noResultsView
                                                                   attribute:NSLayoutAttributeLeft
                                                                  multiplier:1.0
                                                                    constant:25]];

    [self.noResultsView addConstraint:[NSLayoutConstraint constraintWithItem:self.noResultsLabel
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.noResultsView
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0
                                                                    constant:-25]];

    [self.noResultsView addConstraint:[NSLayoutConstraint constraintWithItem:self.noResultsLabel
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.noResultsView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0]];
}

- (void)setupLoadingView {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 80)];
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
        case NHBottomLoadingViewStateFinished:
            if ([self.scrollView isKindOfClass:[UITableView class]]) {
                ((UITableView*)self.scrollView).tableFooterView = self.finishedView;
            }
            break;
        case NHBottomLoadingViewStateNoResults:
            if ([self.scrollView isKindOfClass:[UITableView class]]) {
                ((UITableView*)self.scrollView).tableFooterView = self.noResultsView;
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
    switch (self.viewState) {
        case NHBottomLoadingViewStateLoading:
            return self.loadingView;
        case NHBottomLoadingViewStateFinished:
            return self.finishedView;
        case NHBottomLoadingViewStateNoResults:
            return self.noResultsView;
        default:
            break;
    }
    return nil;
}

- (void)dealloc {
    NSLog(@"dealloc");
}

@end

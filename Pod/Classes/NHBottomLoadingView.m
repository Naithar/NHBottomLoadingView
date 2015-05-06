//
//  NHBottomLoadingView.m
//  Pods
//
//  Created by Sergey Minakov on 06.05.15.
//
//

#import "NHBottomLoadingView.h"

@interface NHBottomLoadingView ()

@property (nonatomic, strong) NSMutableDictionary *viewDictionary;
@property (nonatomic, copy) NSString *viewKey;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) NHBottomLoadingViewState viewState;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIImageView *loadingImageView;

@property (nonatomic, strong) UIView *finishedView;

@property (nonatomic, strong) UIView *noResultsView;
@property (nonatomic, strong) UILabel *noResultsLabel;

@property (nonatomic, strong) UIView *failedView;
@property (nonatomic, strong) UIImageView *failedImageView;
@property (nonatomic, strong) UILabel *failedLabel;

@property (nonatomic, assign) BOOL refreshing;
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
    _viewDictionary = [[NSMutableDictionary alloc] init];
    _isLoading = YES;

    [self setupLoadingView];
    [self setupFinishedView];
    [self setupFailedView];
    [self setupNoResultsView];

    [self.scrollView addObserver:self
                      forKeyPath:@"backgroundColor"
                         options:NSKeyValueObservingOptionNew
                         context:nil];

    [self.scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                         context:nil];

    [self setState:_viewState];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.scrollView) {
        if ([keyPath isEqualToString:@"backgroundColor"]) {
            UIColor *newColor = change[NSKeyValueChangeNewKey];

            self.loadingView.backgroundColor = newColor;
            self.loadingImageView.backgroundColor = newColor;

            self.noResultsView.backgroundColor = newColor;
            self.noResultsLabel.backgroundColor = newColor;

            self.failedView.backgroundColor = newColor;
            self.failedLabel.backgroundColor = newColor;
            self.failedImageView.backgroundColor = newColor;

            self.finishedView.backgroundColor = newColor;
        }
        else if ([keyPath isEqualToString:@"contentOffset"]) {
            CGPoint oldValue = [change[NSKeyValueChangeOldKey] CGPointValue];
            CGPoint newValue = [change[NSKeyValueChangeNewKey] CGPointValue];

            if (!CGPointEqualToPoint(oldValue, newValue)) {

                CGFloat offset = newValue.y + self.scrollView.bounds.size.height;
                CGFloat contentHeight = self.scrollView.contentSize.height - [self viewForCurrentState].bounds.size.height;
                if (self.isLoading
                    && self.viewState == NHBottomLoadingViewStateLoading
                    && !self.refreshing
                    && offset >= contentHeight) {
                    [self startRefreshing];
                }
                else if (self.isLoading
                         && self.viewState == NHBottomLoadingViewStateFailed
                         && offset <= contentHeight) {
                    [self stopRefreshing];
                    [self setState:NHBottomLoadingViewStateLoading];
                }
            }
        }
    }
}

- (void)setupFinishedView {
    self.finishedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
    self.finishedView.backgroundColor = self.scrollView.backgroundColor;
}

- (void)setupFailedView {
    self.failedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 125)];
    self.failedLabel.opaque = YES;
    self.failedView.backgroundColor = self.scrollView.backgroundColor;

    self.failedImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.failedImageView.opaque = YES;
    self.failedImageView.backgroundColor = self.scrollView.backgroundColor;
    self.failedImageView.image = [UIImage imageNamed:@"NHBottomView.refresh.png"];
    [self.failedImageView setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.failedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.failedLabel.opaque = YES;
    self.failedLabel.backgroundColor = self.scrollView.backgroundColor;
    self.failedLabel.numberOfLines = 0;
    self.failedLabel.textAlignment = NSTextAlignmentCenter;
    self.failedLabel.textColor = self.failedTextColor ?: [UIColor blackColor];
    self.failedLabel.font = self.failedTextFont ?: [UIFont systemFontOfSize:17];
    [self.failedLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.failedLabel.text = self.failedText ?: NSLocalizedStringFromTable(@"defaul.failed", @"NHBottomLoadingView", nil);

    [self.failedView addSubview:self.failedImageView];
    [self.failedView addSubview:self.failedLabel];

    [self.failedView addConstraint:[NSLayoutConstraint constraintWithItem:self.failedImageView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.failedView
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:15]];

    [self.failedView addConstraint:[NSLayoutConstraint constraintWithItem:self.failedImageView
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.failedView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0 constant:0]];

    [self.failedView addConstraint:[NSLayoutConstraint constraintWithItem:self.failedLabel
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.failedImageView
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:15]];

    [self.failedView addConstraint:[NSLayoutConstraint constraintWithItem:self.failedLabel
                                                                   attribute:NSLayoutAttributeLeft
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.failedView
                                                                   attribute:NSLayoutAttributeLeft
                                                                  multiplier:1.0
                                                                    constant:25]];

    [self.failedView addConstraint:[NSLayoutConstraint constraintWithItem:self.failedLabel
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.failedView
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0
                                                                    constant:-25]];
}

- (void)updateFailedView {
    BOOL internetConnection = YES;

    if (!internetConnection) {
        self.failedLabel.text = self.failedNoConnectionText ?: NSLocalizedStringFromTable(@"defaul.failed-connection", @"NHBottomLoadingView", nil);
    }
    else {
        self.failedLabel.text = self.failedText ?: NSLocalizedStringFromTable(@"defaul.failed", @"NHBottomLoadingView", nil);
    }
}

- (void)setupNoResultsView {
    self.noResultsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 50)];
    self.noResultsView.opaque = YES;
    self.noResultsView.backgroundColor = self.scrollView.backgroundColor;

    self.noResultsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.noResultsView.opaque = YES;
    self.noResultsLabel.numberOfLines = 0;
    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
    [self.noResultsLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.noResultsLabel.backgroundColor = self.scrollView.backgroundColor;
    self.noResultsLabel.textColor = self.noResultsTextColor ?: [UIColor blackColor];
    self.noResultsLabel.font = self.noResultsTextFont ?: [UIFont systemFontOfSize:17];
    self.noResultsLabel.text = self.noResultText ?: NSLocalizedStringFromTable(@"default.noresults", @"NHBottomLoadingView", nil);

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
    self.loadingView.opaque = YES;
    self.loadingView.backgroundColor = self.scrollView.backgroundColor;

    self.loadingImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.loadingImageView.opaque = YES;
    self.loadingImageView.backgroundColor = self.scrollView.backgroundColor;
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
        case NHBottomLoadingViewStateFailed:
            [self updateFailedView];
            if ([self.scrollView isKindOfClass:[UITableView class]]) {
                ((UITableView*)self.scrollView).tableFooterView = self.failedView;
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

    self.viewKey = nil;
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
        case NHBottomLoadingViewStateFailed:
            return self.failedView;
        case NHBottomLoadingViewStateView:
            return self.viewDictionary[self.viewKey][@"view"];
        default:
            break;
    }
    return nil;
}

- (void)setView:(UIView*)view
         forKey:(NSString*)key {
    [self setView:view withHeight:0 forKey:key];
}

- (void)setView:(UIView*)view
     withHeight:(CGFloat)height
         forKey:(NSString*)key {
    self.viewDictionary[key] = @{
                                 @"view" : view,
                                 @"targetHeight" : @(height)
                                 };
}

- (void)setViewWithKey:(NSString*)key {
    [self setViewWithKey:key
                animated:NO];
}

- (void)setViewWithKey:(NSString*)key
              animated:(BOOL)animated {
    UIView *view = self.viewDictionary[key][@"view"];
    CGFloat targetHeight = [self.viewDictionary[key][@"targetHeight"] floatValue];

    if (view
        && ![view isKindOfClass:[NSNull class]]) {

        if (targetHeight > 0) {
            CGRect viewBounds = view.bounds;
            viewBounds.size.height = targetHeight;
            view.bounds = viewBounds;
            [view layoutIfNeeded];
        }

        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            ((UITableView*)self.scrollView).tableFooterView = view;
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

        self.viewKey = key;
        self.viewState = NHBottomLoadingViewStateView;
    }
}

- (void)startRefreshing {
    if (self.refreshing) {
        return;
    }

    self.refreshing = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setState:NHBottomLoadingViewStateFailed];
        [((UITableView*)self.scrollView) reloadData];
    });
}

- (void)stopRefreshing {
    self.refreshing = NO;
}

- (void)setNoResultsTextFont:(UIFont *)noResultsTextFont {
    [self willChangeValueForKey:@"noResultsTextFont"];
    _noResultsTextFont = noResultsTextFont;
    self.noResultsLabel.font = noResultsTextFont ?: [UIFont systemFontOfSize:17];
    [self didChangeValueForKey:@"noResultsTextFont"];
}

- (void)setNoResultsTextColor:(UIColor *)noResultsTextColor {
    [self willChangeValueForKey:@"noResultsTextColor"];
    _noResultsTextColor = noResultsTextColor;
    self.noResultsLabel.textColor = noResultsTextColor ?: [UIColor blackColor];
    [self didChangeValueForKey:@"noResultsTextColor"];
}


- (void)setFailedTextFont:(UIFont *)failedTextFont {
    [self willChangeValueForKey:@"failedTextFont"];
    _failedTextFont = failedTextFont;
    self.failedLabel.font = failedTextFont ?: [UIFont systemFontOfSize:17];
    [self didChangeValueForKey:@"failedTextFont"];
}

- (void)setFailedTextColor:(UIColor *)failedTextColor {
    [self willChangeValueForKey:@"failedTextColor"];
    _failedTextColor = failedTextColor;
    self.failedLabel.textColor = failedTextColor ?: [UIColor blackColor];
    [self didChangeValueForKey:@"failedTextColor"];
}

- (void)setNoResultText:(NSString *)noResultText {
    [self willChangeValueForKey:@"noResultText"];
    _noResultText = noResultText;

    self.noResultsLabel.text = _noResultText ?: NSLocalizedStringFromTable(@"default.noresults", @"NHBottomLoadingView", nil);
    [self didChangeValueForKey:@"noResultText"];
}

- (void)setFailedText:(NSString *)failedText {
    [self willChangeValueForKey:@"failedText"];
    _failedText = failedText;

    [self updateFailedView];
    [self didChangeValueForKey:@"failedText"];
}

- (void)setFailedNoConnectionText:(NSString *)failedNoConnectionText {
    [self willChangeValueForKey:@"failedNoConnectionText"];
    _failedNoConnectionText = failedNoConnectionText;

    [self updateFailedView];
    [self didChangeValueForKey:@"failedNoConnectionText"];
}

- (void)dealloc {
    [self.scrollView removeObserver:self forKeyPath:@"backgroundColor"];
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end

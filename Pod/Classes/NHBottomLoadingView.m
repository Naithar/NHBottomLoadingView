//
//  NHBottomLoadingView.m
//  Pods
//
//  Created by Sergey Minakov on 06.05.15.
//
//

#import "NHBottomLoadingView.h"
#import <unistd.h>
#import <netdb.h>

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

@property (nonatomic, assign) CGFloat previousContentSize;
@end

@implementation NHBottomLoadingView

- (instancetype)initWithScrollView:(UIScrollView*)scrollView {
    return [self initWithScrollView:scrollView withBlock:nil];
}


- (instancetype)initWithScrollView:(UIScrollView*)scrollView
                         withBlock:(NHBottomLoadingViewBlock)block {
    self = [super init];
    
    if (self) {
        _scrollView = scrollView;
        _refreshBlock = block;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _viewState = NHBottomLoadingViewStateLoading;
    _viewDictionary = [[NSMutableDictionary alloc] init];
    _isLoading = YES;
    
    _loadingOffset = 0;
    
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
    
    [self.scrollView addObserver:self
                      forKeyPath:@"contentSize"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                         context:nil];
    
    [self.scrollView addObserver:self
                      forKeyPath:@"contentInset"
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
                [self tryReloadWithOffset:newValue.y];
            }
        }
        else if ([keyPath isEqualToString:@"contentSize"]) {
            CGSize newValue = [change[NSKeyValueChangeNewKey] CGSizeValue];
            CGSize oldValue = [change[NSKeyValueChangeOldKey] CGSizeValue];
            
            if (!CGSizeEqualToSize(oldValue, newValue)
                && oldValue.height != 0
                && newValue.height != 0) {
                [self tryReloadWithOffset:self.scrollView.contentOffset.y checkContentSize:YES];
            }
        }
        else if ([keyPath isEqualToString:@"contentInset"]) {
            UIEdgeInsets newValue = [change[NSKeyValueChangeNewKey] UIEdgeInsetsValue];
            UIEdgeInsets oldValue = [change[NSKeyValueChangeOldKey] UIEdgeInsetsValue];
            
            if (!UIEdgeInsetsEqualToEdgeInsets(oldValue, newValue)) {
                [self tryReloadWithOffset:self.scrollView.contentOffset.y];
            }
        }
    }
}

- (void)tryReloadWithOffset:(CGFloat)offsetValue {
    [self tryReloadWithOffset:offsetValue checkContentSize:NO];
}

- (void)tryReloadWithOffset:(CGFloat)offsetValue checkContentSize:(BOOL)checkSize {
    CGFloat offset = offsetValue + self.scrollView.bounds.size.height;
    CGFloat contentHeight = self.scrollView.contentSize.height - [self viewForCurrentState].bounds.size.height;
    
    if ((self.previousContentSize != contentHeight || !checkSize)
        && contentHeight > 0) {
        
        if (self.isLoading
            && self.viewState == NHBottomLoadingViewStateLoading
            && !self.refreshing
            && offset + self.loadingOffset >= contentHeight) {
            [self startRefreshing];
        }
        else if (self.isLoading
                 && self.viewState == NHBottomLoadingViewStateFailed
                 && offset <= contentHeight) {
            [self stopRefreshing];
            [self setState:NHBottomLoadingViewStateLoading];
        }
        
        
    }
    
    self.previousContentSize = contentHeight;
}

- (void)setupFinishedView {
    self.finishedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
    self.finishedView.backgroundColor = self.scrollView.backgroundColor;
}

- (void)setupFailedView {
    self.failedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 150)];
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
    //    self.failedLabel.textColor = self.failedTextColor ?: [UIColor blackColor];
    //    self.failedLabel.font = self.failedTextFont ?: [UIFont systemFontOfSize:17];
    [self.failedLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    //    self.failedLabel.text = self.failedText ?: NSLocalizedStringFromTable(@"default.failed", @"NHBottomLoadingView", nil);
    [self updateFailedView];
    
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
                                                                 constant:10]];
    
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
    
    [self.failedView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshTouch:)]];
}

//http://stackoverflow.com/questions/8812459/easiest-way-to-detect-internet-connection-on-ios
-(BOOL)isNetworkAvailable
{
    char *hostname;
    struct hostent *hostinfo;
    hostname = "google.com";
    hostinfo = gethostbyname (hostname);
    if (hostinfo == NULL){
        return NO;
    }
    else{
        return YES;
    }
}

- (void)updateFailedView {
    BOOL internetConnection = [self isNetworkAvailable];
    
    NSString *text;
    NSString *subtext = self.failedSubtext ?: NSLocalizedStringFromTable(@"default.subtext", @"NHBottomLoadingView", nil);
    
    if (!internetConnection) {
        text = self.failedNoConnectionText ?: NSLocalizedStringFromTable(@"default.failed-connection", @"NHBottomLoadingView", nil);
    }
    else {
        text = self.failedText ?: NSLocalizedStringFromTable(@"default.failed", @"NHBottomLoadingView", nil);
    }
    
    NSMutableAttributedString *tempFailedText = [[NSMutableAttributedString alloc] init];
    
    [tempFailedText appendAttributedString:[[NSAttributedString alloc] initWithString:text attributes:@{
                                                                                                        NSFontAttributeName : self.failedTextFont ?: [UIFont systemFontOfSize:17],
                                                                                                        NSForegroundColorAttributeName : self.failedTextColor ?: [UIColor blackColor]
                                                                                                        }]];
    
    [tempFailedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    [tempFailedText appendAttributedString:[[NSAttributedString alloc] initWithString:subtext attributes:@{
                                                                                                           NSFontAttributeName : self.failedSubtextFont ?: [UIFont systemFontOfSize:14],
                                                                                                           NSForegroundColorAttributeName : self.failedSubtextColor ?: [UIColor grayColor]
                                                                                                           }]];
    self.failedLabel.attributedText = tempFailedText;
}

- (void)setupNoResultsView {
    self.noResultsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)];
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
    
    [self.noResultsView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshTouch:)]];
}

- (void)setupLoadingView {
    self.loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 80)];
    self.loadingView.opaque = YES;
    self.loadingView.backgroundColor = self.scrollView.backgroundColor;
    
    self.loadingImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.loadingImageView.opaque = YES;
    self.loadingImageView.backgroundColor = self.scrollView.backgroundColor;
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
    
    self.viewKey = nil;
    self.viewState = state;
    
    if (state == NHBottomLoadingViewStateFailed) {
        [self updateFailedView];
    }
    
    if (animated) {
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionTransitionNone|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             if ([self.scrollView isKindOfClass:[UITableView class]]) {
                                 ((UITableView*)self.scrollView).tableFooterView = [self viewForCurrentState];
                             }
                             [self.scrollView layoutIfNeeded];
                         } completion:nil];
    }
    else {
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            ((UITableView*)self.scrollView).tableFooterView = [self viewForCurrentState];
        }
        [self.scrollView layoutIfNeeded];
    }
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

- (UIView*)setViewWithKey:(NSString*)key {
    return [self setViewWithKey:key
                       animated:NO];
}

- (UIView*)setViewWithKey:(NSString*)key
                 animated:(BOOL)animated {
    UIView *view = self.viewDictionary[key][@"view"];
    CGFloat targetHeight = [self.viewDictionary[key][@"targetHeight"] floatValue];
    
    if (view
        && ![view isKindOfClass:[NSNull class]]) {
        
        self.viewKey = key;
        self.viewState = NHBottomLoadingViewStateView;
        
        if (targetHeight > 0) {
            CGRect viewBounds = view.bounds;
            viewBounds.size.height = targetHeight;
            view.bounds = viewBounds;
            view.frame = view.bounds;
            [view layoutIfNeeded];
            view.clipsToBounds = YES;
        }
        
        if (animated) {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionNone
                             animations:^{
                                 if ([self.scrollView isKindOfClass:[UITableView class]]) {
                                     ((UITableView*)self.scrollView).tableFooterView = view;
                                 }
                                 [self.scrollView layoutIfNeeded];
                             } completion:nil];
        }
        else {
            if ([self.scrollView isKindOfClass:[UITableView class]]) {
                ((UITableView*)self.scrollView).tableFooterView = view;
            }
            [self.scrollView layoutIfNeeded];
        }
        
        
        
        return view;
    }
    
    return nil;
}

- (void)refreshTouch:(UITapGestureRecognizer*)recognizer {
    [self stopRefreshing];
    [self setState:NHBottomLoadingViewStateLoading animated:YES];
    [self startRefreshing];
}

- (void)startRefreshing {
    if (self.refreshing) {
        return;
    }
    
    self.refreshing = YES;
    
    if (self.refreshBlock) {
        self.refreshBlock();
    }
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
    [self didChangeValueForKey:@"failedTextFont"];
    [self updateFailedView];
}

- (void)setFailedSubtextFont:(UIFont *)failedSubtextFont {
    [self willChangeValueForKey:@"failedSubtextFont"];
    _failedSubtextFont = failedSubtextFont;
    [self didChangeValueForKey:@"failedSubtextFont"];
    [self updateFailedView];
}

- (void)setFailedTextColor:(UIColor *)failedTextColor {
    [self willChangeValueForKey:@"failedTextColor"];
    _failedTextColor = failedTextColor;
    [self didChangeValueForKey:@"failedTextColor"];
    [self updateFailedView];
}

- (void)setFailedSubtextColor:(UIColor *)failedSubtextColor {
    [self willChangeValueForKey:@"failedSubtextColor"];
    _failedSubtextColor = failedSubtextColor;
    [self didChangeValueForKey:@"failedSubtextColor"];
    [self updateFailedView];
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

- (void)setFailedSubtext:(NSString *)failedSubtext {
    [self willChangeValueForKey:@"failedSubtext"];
    _failedSubtext = failedSubtext;
    
    [self updateFailedView];
    [self didChangeValueForKey:@"failedSubtext"];
}

- (void)dealloc {
    self.refreshBlock = nil;
    self.viewDictionary = nil;
    self.viewKey = nil;
    [self.scrollView removeObserver:self forKeyPath:@"backgroundColor"];
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.scrollView removeObserver:self forKeyPath:@"contentInset"];
}

@end

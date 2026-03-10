#import "utils.m"
#import <QuartzCore/QuartzCore.h>
#import <WebKit/WebKit.h>

@interface ZystalWebViewContainerView : NSView

@property(nonatomic, weak) WKWebView *webView;

@end

@implementation ZystalWebViewContainerView

- (void)setFrameSize:(NSSize)newSize {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [super setFrameSize:newSize];
    [CATransaction commit];
}

- (void)layout {
    [super layout];
    if (self.webView) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self.webView setFrame:[self bounds]];
        [CATransaction commit];
    }
}

@end

static WKWebView *webViewFromPtr(NSView *view) {
    if (!view)
        return nil;
    if ([view isKindOfClass:[WKWebView class]])
        return (WKWebView *)view;

    for (NSView *subview in [view subviews]) {
        WKWebView *webView = webViewFromPtr(subview);
        if (webView)
            return webView;
    }

    return nil;
}

static void ensureWebViewFillsContentView(NSWindow *window) {
    NSView *contentView = [window contentView];
    WKWebView *webView = webViewFromPtr(contentView);
    if (!webView)
        return;

    if ([contentView isKindOfClass:[ZystalWebViewContainerView class]]) {
        ZystalWebViewContainerView *container = (ZystalWebViewContainerView *)contentView;
        container.webView = webView;
        [webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [webView setFrame:[container bounds]];
        return;
    }

    ZystalWebViewContainerView *container =
        [[ZystalWebViewContainerView alloc] initWithFrame:[contentView frame]];
    [container setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [container setAutoresizesSubviews:YES];
    container.webView = webView;

    [webView removeFromSuperview];
    [window setContentView:container];
    [webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [webView setFrame:[container bounds]];
    [container addSubview:webView];
    [container setWantsLayer:YES];
    [container.layer setBackgroundColor:CGColorGetConstantColor(kCGColorClear)];
    [webView setWantsLayer:YES];
    [webView.layer setBackgroundColor:CGColorGetConstantColor(kCGColorClear)];
}

void setWebViewTransparent(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    ensureWebViewFillsContentView(window);
    WKWebView *webView = webViewFromPtr([window contentView]);
    if (!webView)
        return;
    [webView setValue:@(NO) forKey:@"drawsBackground"];
    [[webView enclosingScrollView] setDrawsBackground:NO];
}

void setVibrancy(void *window_ptr, NSInteger material) {
    NSWindow *window = windowFromPtr(window_ptr);
    ensureWebViewFillsContentView(window);

    NSView *contentView = [window contentView];
    if (![contentView isKindOfClass:[ZystalWebViewContainerView class]])
        return;

    for (NSView *subview in [[contentView subviews] copy]) {
        if ([subview isKindOfClass:[NSVisualEffectView class]])
            [subview removeFromSuperview];
    }

    NSVisualEffectView *vev = [[NSVisualEffectView alloc]
        initWithFrame:[contentView bounds]];
    [vev setMaterial:(NSVisualEffectMaterial)material];
    [vev setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [vev setState:NSVisualEffectStateActive];
    [vev setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [contentView addSubview:vev positioned:NSWindowBelow relativeTo:nil];
}

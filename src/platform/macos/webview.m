#import "utils.m"
#import <WebKit/WebKit.h>

@interface ZystalWebViewContainerView : NSView

@property(nonatomic, weak) WKWebView *webView;

@end

@implementation ZystalWebViewContainerView

- (void)layout {
    [super layout];
    if (self.webView)
        [self.webView setFrame:[self bounds]];
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

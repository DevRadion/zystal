#import "utils.m"
#import <WebKit/WebKit.h>

static WKWebView *webViewFromPtr(NSView *view) {
    if ([view isKindOfClass:[WKWebView class]])
        return (WKWebView *)view;
    return nil;
}

void setWebViewTransparent(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    WKWebView *webView = webViewFromPtr([window contentView]);
    if (!webView)
        return;
    [webView setValue:@(NO) forKey:@"drawsBackground"];
    [[webView enclosingScrollView] setDrawsBackground:NO];
}

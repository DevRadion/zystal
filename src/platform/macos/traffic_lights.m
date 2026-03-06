#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static const char kTrafficLightXKey;
static const char kTrafficLightYKey;
static const char kTrafficLightSpacingKey;

static NSView *findTitlebarContainerView(NSWindow *window) {
    NSView *frameView = window.contentView.superview;
    for (NSView *subview in frameView.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"TitlebarContainerView"])
            return subview;
    }
    return nil;
}

static void repositionTrafficLights(NSWindow *window, NSView *containerView) {
    NSNumber *xVal = objc_getAssociatedObject(window, &kTrafficLightXKey);
    NSNumber *yVal = objc_getAssociatedObject(window, &kTrafficLightYKey);
    NSNumber *spacingVal = objc_getAssociatedObject(window, &kTrafficLightSpacingKey);

    if (!xVal || !yVal || !spacingVal)
        return;

    CGFloat x = xVal.doubleValue;
    CGFloat yFromTop = yVal.doubleValue;
    CGFloat spacing = spacingVal.doubleValue;

    NSButton *closeBtn = [window standardWindowButton:NSWindowCloseButton];
    NSButton *miniBtn = [window standardWindowButton:NSWindowMiniaturizeButton];
    NSButton *zoomBtn = [window standardWindowButton:NSWindowZoomButton];
    if (!closeBtn)
        return;

    NSView *superview = closeBtn.superview;
    if (!superview)
        return;

    CGFloat buttonH = closeBtn.frame.size.height;
    CGFloat containerH = containerView ? containerView.frame.size.height : superview.frame.size.height;
    CGFloat yInContainer = containerH - buttonH - yFromTop;

    CGFloat yFinal;
    if (containerView && superview != containerView) {
        NSPoint pt = [superview convertPoint:NSMakePoint(0, yInContainer) fromView:containerView];
        yFinal = pt.y;
    } else {
        yFinal = yInContainer;
    }

    closeBtn.frame = NSMakeRect(x, yFinal, closeBtn.frame.size.width, buttonH);
    miniBtn.frame = NSMakeRect(x + spacing, yFinal, miniBtn.frame.size.width, miniBtn.frame.size.height);
    zoomBtn.frame =
        NSMakeRect(x + spacing * 2, yFinal, zoomBtn.frame.size.width, zoomBtn.frame.size.height);
}

static void (*original_container_layout)(id, SEL);
static void (*original_themeframe_layout)(id, SEL);

// Swizzled onto NSTitlebarContainerView. Covers titlebar-internal changes (toolbar, key state).
static void swizzled_container_layout(id self, SEL _cmd) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    original_container_layout(self, _cmd);
    NSWindow *window = [(NSView *)self window];
    if (window)
        repositionTrafficLights(window, (NSView *)self);
    [CATransaction commit];
}

// Swizzled onto NSThemeFrame. Covers all window resizes (its size always changes).
static void swizzled_themeframe_layout(id self, SEL _cmd) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    original_themeframe_layout(self, _cmd);
    NSWindow *window = [(NSView *)self window];
    if (window)
        repositionTrafficLights(window, findTitlebarContainerView(window));
    [CATransaction commit];
}

static void swizzleLayout(Class cls, IMP replacement, void (**original)(id, SEL)) {
    Method m = class_getInstanceMethod(cls, @selector(layout));
    if (!m)
        return;
    *original = (void (*)(id, SEL))method_getImplementation(m);
    method_setImplementation(m, replacement);
}

static void installSwizzles(NSWindow *window) {
    static bool installed = false;
    if (installed)
        return;
    installed = true;

    Class containerCls = NSClassFromString(@"NSTitlebarContainerView");
    if (containerCls)
        swizzleLayout(containerCls, (IMP)swizzled_container_layout, &original_container_layout);

    NSView *themeFrame = window.contentView.superview;
    if (themeFrame)
        swizzleLayout([themeFrame class], (IMP)swizzled_themeframe_layout, &original_themeframe_layout);
}

void setTrafficLightsPosition(void *window_ptr, double x, double y, double spacing) {
    NSWindow *window = (__bridge NSWindow *)window_ptr;
    installSwizzles(window);

    objc_setAssociatedObject(window, &kTrafficLightXKey, @(x), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(window, &kTrafficLightYKey, @(y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(
        window, &kTrafficLightSpacingKey, @(spacing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    repositionTrafficLights(window, findTitlebarContainerView(window));
}

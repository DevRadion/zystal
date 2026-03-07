#import "utils.m"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <WebKit/WebKit.h>

static NSWindowStyleMask styleMaskFromTag(uint8_t tag) {
    switch (tag) {
    case 0:
        return NSWindowStyleMaskBorderless;
    case 1:
        return NSWindowStyleMaskTitled;
    case 2:
        return NSWindowStyleMaskClosable;
    case 3:
        return NSWindowStyleMaskMiniaturizable;
    case 4:
        return NSWindowStyleMaskResizable;
    case 5:
        return NSWindowStyleMaskUnifiedTitleAndToolbar;
    case 6:
        return NSWindowStyleMaskFullScreen;
    case 7:
        return NSWindowStyleMaskFullSizeContentView;
    default:
        return 0;
    }
}

void insertStyleMask(void *window_ptr, uint8_t tag) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setStyleMask:([window styleMask] | styleMaskFromTag(tag))];
}

void removeStyleMask(void *window_ptr, uint8_t tag) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setStyleMask:([window styleMask] & ~styleMaskFromTag(tag))];
}

void setTitleVisibility(void *window_ptr, bool is_visible) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setTitleVisibility:(is_visible ? NSWindowTitleVisible : NSWindowTitleHidden)];
}

void setTitleBarAppearsTransparent(void *window_ptr, bool is_appears_transparent) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setTitlebarAppearsTransparent:is_appears_transparent];
}

void setMovableByWindowBackground(void *window_ptr, bool is_movable) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setMovableByWindowBackground:is_movable];
}

void setWindowBackgroundColor(void *window_ptr, double r, double g, double b, double a) {
    NSWindow *window = windowFromPtr(window_ptr);
    NSColor *color = [NSColor colorWithSRGBRed:r green:g blue:b alpha:a];
    [window setBackgroundColor:color];
    [window setOpaque:(a >= 1.0)];
}

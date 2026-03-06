// macos_window.m
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

static NSWindow *windowFromPtr(void *window_ptr) { return (__bridge NSWindow *)window_ptr; }

static NSWindowStyleMask styleMaskFromTag(uint8_t tag) {
    // borderless,
    // titled,
    // closable,
    // miniaturizable,
    // resizable,
    // unified_title_and_toolbar,
    // full_screen,
    // full_size_content_view,

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
    window.styleMask |= styleMaskFromTag(tag);
}

void removeStyleMask(void *window_ptr, uint8_t tag) {
    NSWindow *window = windowFromPtr(window_ptr);
    window.styleMask &= ~styleMaskFromTag(tag);
}

void setTitleVisibility(void *window_ptr, bool is_visible) {
    NSWindow *window = windowFromPtr(window_ptr);
    window.titleVisibility = is_visible ? NSWindowTitleVisible : NSWindowTitleHidden;
}

void setTitleBarAppearsTransparent(void *window_ptr, bool is_appears_transparent) {
    NSWindow *window = windowFromPtr(window_ptr);
    window.titlebarAppearsTransparent = is_appears_transparent;
}

void setMovableByWindowBackground(void *window_ptr, bool is_movable) {
    NSWindow *window = windowFromPtr(window_ptr);
    window.movableByWindowBackground = is_movable;
}

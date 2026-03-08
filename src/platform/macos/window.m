#import "utils.m"
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <WebKit/WebKit.h>

struct WPoint {
    uint16 x;
    uint16 y;
};

struct WSize {
    uint16 width;
    uint16 height;
};

struct WRect {
    struct WSize size;
    struct WPoint origin;
};

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

void setTitle(void *window_ptr, const char *title) {
    NSString *title_string = [[NSString alloc] initWithUTF8String:title];
    NSWindow *window = windowFromPtr(window_ptr);
    [window setTitle:title_string];
}

void setRect(void *window_ptr, struct WRect *rect, bool animated, bool display) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setFrame:(NSMakeRect(rect->origin.x, rect->origin.y, rect->size.width, rect->size.height))
             display:(display)animate:(animated)];
}

void getRect(void *window_ptr, struct WRect *out) {
    NSWindow *window = windowFromPtr(window_ptr);
    out->size.width = window.frame.size.width;
    out->size.height = window.frame.size.height;
    out->origin.x = window.frame.origin.x;
    out->origin.y = window.frame.origin.y;
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

// --- Window Constraints ---

void setMinSize(void *window_ptr, struct WSize *size) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setMinSize:NSMakeSize(size->width, size->height)];
}

void setMaxSize(void *window_ptr, struct WSize *size) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setMaxSize:NSMakeSize(size->width, size->height)];
}

// --- Window Visibility ---

void showWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window makeKeyAndOrderFront:nil];
}

void hideWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window orderOut:nil];
}

void focusWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window makeKeyAndOrderFront:nil];
    if (@available(macOS 14.0, *)) {
        [NSApp activate];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [NSApp activateIgnoringOtherApps:YES];
#pragma clang diagnostic pop
    }
}

bool isWindowVisible(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    return [window isVisible];
}

// --- Window State ---

void minimizeWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window miniaturize:nil];
}

void maximizeWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window zoom:nil];
}

void closeWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window performClose:nil];
}

void toggleFullScreen(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    if (!([window styleMask] & NSWindowStyleMaskFullScreen)) {
        [window toggleFullScreen:nil];
    }
}

void restoreWindow(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    if ([window isMiniaturized]) [window deminiaturize:nil];
    if ([window styleMask] & NSWindowStyleMaskFullScreen) [window toggleFullScreen:nil];
    if ([window isZoomed]) [window zoom:nil];
}

// --- Window Level/Ordering ---

void setAlwaysOnTop(void *window_ptr, bool on_top) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window setLevel:(on_top ? NSFloatingWindowLevel : NSNormalWindowLevel)];
}

void orderWindowFront(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window orderFront:nil];
}

void orderWindowBack(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);
    [window orderBack:nil];
}

// --- Window Dragging ---

// Persistent monitor captures every mouseDown so we have the NSEvent
// available when the async bind() callback fires from the webview.
static id mouseDownMonitor = nil;
static NSEvent *lastMouseDownEvent = nil;

void startDragging(void *window_ptr) {
    NSWindow *window = windowFromPtr(window_ptr);

    // Lazily install a persistent mouseDown monitor
    if (!mouseDownMonitor) {
        mouseDownMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown
                                                                handler:^NSEvent *(NSEvent *event) {
            lastMouseDownEvent = event;
            return event;
        }];
    }

    // Use the captured mouseDown event, fall back to currentEvent
    NSEvent *event = lastMouseDownEvent ?: [NSApp currentEvent];
    lastMouseDownEvent = nil; // Clear after use to prevent stale drags
    if (event && event.type == NSEventTypeLeftMouseDown) {
        [window performWindowDragWithEvent:event];
    }
}

void removeDragMonitor(void) {
    if (mouseDownMonitor) {
        [NSEvent removeMonitor:mouseDownMonitor];
        mouseDownMonitor = nil;
    }
    lastMouseDownEvent = nil;
}

#import <Cocoa/Cocoa.h>

static NSWindow *windowFromPtr(void *window_ptr) { return (__bridge NSWindow *)window_ptr; }

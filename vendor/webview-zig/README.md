# webview-zig

[![](https://img.shields.io/github/v/tag/thechampagne/webview-zig?label=version)](https://github.com/thechampagne/webview-zig/releases/latest) [![](https://img.shields.io/github/license/thechampagne/webview-zig)](https://github.com/thechampagne/webview-zig/blob/main/LICENSE)

Zig binding for a tiny cross-platform **webview** library to build modern cross-platform GUIs.

<p align="center">
<img src="https://raw.githubusercontent.com/devradion/webview-zig/main/.github/assets/screenshot.png"/>
</p>

### Requirements
 - [Zig Compiler](https://ziglang.org/) - **0.16.0**
 - Unix
   - [GTK3](https://gtk.org/) and [WebKitGTK](https://webkitgtk.org/)
 - Windows
   - [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
 - macOS
   - [WebKit](https://webkit.org/)

### Usage

```
zig fetch --save https://github.com/thechampagne/webview-zig/archive/refs/heads/main.tar.gz
```

`build.zig.zon`:
```zig
.{
    .dependencies = .{
        .webview = .{
            .url = "https://github.com/devradion/webview-zig/archive/refs/heads/main.tar.gz" ,
          //.hash = "12208586373679a455aa8ef874112c93c1613196f60137878d90ce9d2ae8fb9cd511",
        },
    },
}
```
`build.zig`:
```zig
const webview = b.dependency("webview", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("webview", webview.module("webview"));
exe.linkLibrary(webview.artifact("webviewStatic")); // or "webviewShared" for shared library
// exe.linkSystemLibrary("webview"); to link with installed prebuilt library without building
```

### API

```zig
const WebView = struct {

    const WebViewVersionInfo = struct {
        version: struct {
            major: c_uint,
            minor: c_uint,
            patch: c_uint,
        },
        version_number: [32]c_char,
        pre_release: [48]c_char,
        build_metadata: [48]c_char,
    };

    const DispatchCallback = *const fn (?*anyopaque, ?*anyopaque) callconv(.c) void;

    const BindCallback = *const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.c) void;

    const WindowSizeHint = enum(c_uint) {
        none,
        min,
        max,
        fixed
    };

    const NativeHandle = enum(c_uint) {
        ui_window,
        ui_widget,
        browser_controller
    };

    const WebViewError = error {
        MissingDependency,
        Canceled,
        InvalidState,
        InvalidArgument,
        Unspecified,
        Duplicate,
        NotFound,
    };

    fn create(debug: bool, window: ?*anyopaque) WebView;

    fn run(self: WebView) WebViewError!void;

    fn terminate(self: WebView) WebViewError!void;
    
    fn dispatch(self: WebView, func: DispatchCallback, arg: ?*anyopaque) WebViewError!void;
    
    fn getWindow(self: WebView) ?*anyopaque;

    fn getNativeHandle(self: WebView, kind: NativeHandle) ?*anyopaque;
    
    fn setTitle(self: WebView, title: [:0]const u8) WebViewError!void;
    
    fn setSize(self: WebView, width: i32, height: i32, hint: WindowSizeHint) WebViewError!void;
    
    fn navigate(self: WebView, url: [:0]const u8) WebViewError!void;
    
    fn setHtml(self: WebView, html: [:0]const u8) WebViewError!void;
    
    fn init(self: WebView, js: [:0]const u8) WebViewError!void;
    
    fn eval(self: WebView, js: [:0]const u8) WebViewError!void;
    
    fn bind(self: WebView, name: [:0]const u8, func: BindCallback, arg: ?*anyopaque) WebViewError!void;
    
    fn unbind(self: WebView, name: [:0]const u8) WebViewError!void;
    
    fn ret(self: WebView ,seq: [:0]const u8, status: i32, result: [:0]const u8) WebViewError!void;
    
    fn version() *const WebViewVersionInfo;

    fn destroy(self: WebView) WebViewError!void;
}
```

#### Function docs

All methods that return `WebViewError!void` can fail with one of:
`MissingDependency`, `Canceled`, `InvalidState`, `InvalidArgument`, `Unspecified`, `Duplicate`, `NotFound`.

`create` itself does not return an error union. If creation fails at the native layer,
the internal handle may be null and later calls can fail (typically with `InvalidState`).

##### `create(debug, window) -> WebView`
Creates a new webview instance.

| Parameter | Type | Description |
| --- | --- | --- |
| `debug` | `bool` | Enables debug mode (for example, developer tools where supported). |
| `window` | `?*anyopaque` | Optional native window handle to embed into. If null, webview creates and manages its own top-level window. |

##### `run(self) -> WebViewError!void`
Starts the main UI loop and blocks until the window closes or `terminate` is called.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |

##### `terminate(self) -> WebViewError!void`
Requests the running UI loop to stop.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |

##### `dispatch(self, func, arg) -> WebViewError!void`
Schedules a callback to run on the UI thread.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `func` | `DispatchCallback` | C callback executed on the UI thread; receives `(webview_handle, arg)`. |
| `arg` | `?*anyopaque` | Optional user data passed to `func`. |

##### `getWindow(self) -> ?*anyopaque`
Returns the top-level native window handle.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |

##### `getNativeHandle(self, kind) -> ?*anyopaque`
Returns a platform-specific native handle.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `kind` | `NativeHandle` | `ui_window` (`GtkWindow*`/`NSWindow*`/`HWND`), `ui_widget` (`GtkWidget*`/`NSView*`/`HWND`), or `browser_controller` (`WebKitWebView*`/`WKWebView*`/`ICoreWebView2Controller*`). |

##### `setTitle(self, title) -> WebViewError!void`
Sets the native window title.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `title` | `[:0]const u8` | Zero-terminated UTF-8 title string. |

##### `setSize(self, width, height, hint) -> WebViewError!void`
Sets the window size and sizing behavior.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `width` | `i32` | Window width in pixels. |
| `height` | `i32` | Window height in pixels. |
| `hint` | `WindowSizeHint` | Sizing hint: `none`, `min`, `max`, or `fixed`. |

Note: On GTK4, `max` has no effect due to backend limitations.

##### `navigate(self, url) -> WebViewError!void`
Navigates the webview to a URL (including `data:` URLs).

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `url` | `[:0]const u8` | Zero-terminated URL string. |

##### `setHtml(self, html) -> WebViewError!void`
Loads HTML content directly.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `html` | `[:0]const u8` | Zero-terminated HTML string. |

##### `init(self, js) -> WebViewError!void`
Injects JavaScript that runs on every page load (before `window.onload`).

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `js` | `[:0]const u8` | Zero-terminated JavaScript source. |

##### `eval(self, js) -> WebViewError!void`
Evaluates JavaScript in the current page context.

Use `bind`/`ret` when you need to pass values back to native code.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `js` | `[:0]const u8` | Zero-terminated JavaScript source. |

##### `bind(self, name, func, arg) -> WebViewError!void`
Exposes a native callback as a JavaScript function.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `name` | `[:0]const u8` | JavaScript function name. |
| `func` | `BindCallback` | Native callback receiving `(id, req, arg)`, where `req` is a JSON array string of JS arguments. |
| `arg` | `?*anyopaque` | Optional user data passed to `func`. |

Can return `Duplicate` if `name` is already bound.

##### `unbind(self, name) -> WebViewError!void`
Removes a previously bound JavaScript function.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `name` | `[:0]const u8` | Bound JavaScript function name. |

Can return `NotFound` if `name` is not currently bound.

##### `ret(self, seq, status, result) -> WebViewError!void`
Sends a response to a JavaScript binding call.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |
| `seq` | `[:0]const u8` | Call identifier received as the first `BindCallback` argument. |
| `status` | `i32` | Result status (`0` for success, non-zero for error). |
| `result` | `[:0]const u8` | Valid JSON value to return to JS, or an empty string for `undefined`. |

##### `version() -> *const WebViewVersionInfo`
Returns webview library version information.

##### `destroy(self) -> WebViewError!void`
Destroys the webview instance and releases resources.

| Parameter | Type | Description |
| --- | --- | --- |
| `self` | `WebView` | The webview instance. |

### References
 - [webview](https://github.com/webview/webview/tree/0.12.0) - **0.12.0**

### License

This repo is released under the [MIT License](https://github.com/thechampagne/webview-zig/blob/main/LICENSE).

Third party code:
 - [external/WebView2](https://github.com/thechampagne/webview-zig/tree/main/external/WebView2) licensed under the [BSD-3-Clause License](https://github.com/thechampagne/webview-zig/tree/main/external/WebView2/LICENSE).


# Plan for MVP

## General
1) The library itself should be able to communicate with frontend (without code gen) and vice-versa
2) It should be able to generate a new project with package managers like bun, npm, etc
    - Should generate a project with frontend, backend and demo page without so much bs code that user will be deleting
3) Project should compile in .app on macos (windows is tier 2 support for now)
4) Package manager should have a custom script which will start dev server and run zig build afterwards

## TODO's
### Events
1. Add event passing backend -> frontend (native webview events?)
2. Add event passing frontend -> backend (listening for events on backend?)
3. Wrap the communication in dev friendly abstraction 

### Project gen
1. Create a simple demo project 
2. Figure out how other projects making their proj code gen :) 
3. Profit
After this it's important to allow using dev tools in webview and make window more customizable

### MacOS build
1. Maybe try to create own script which will wrap exe in folder with app extension?

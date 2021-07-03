const std = @import("std");
usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
});

var window: *SDL_Window = undefined;
//var renderer: *SDL_Renderer = undefined;
var surface: *SDL_Surface = undefined;

pub fn init() !void {
    // init just video (we have audio on our own)
    if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
    {
        return error.SDLInitFail;
    }
    window = SDL_CreateWindow(
          "SDL Starter",
          SDL_WINDOWPOS_UNDEFINED,
          SDL_WINDOWPOS_UNDEFINED,
          256,
          256,
          SDL_WINDOW_SHOWN
      ).?;
    surface = SDL_GetWindowSurface(window);
}

pub fn update() bool {
    var e: SDL_Event = undefined;

    while( SDL_PollEvent( &e ) != 0 )
    {
        //User requests quit
        if( e.type == SDL_QUIT )
        {
            return false;
        }
    }

    _ = SDL_UpdateWindowSurface( window );

    return true;
}

pub fn deinit() void {
    SDL_DestroyWindow( window );
    SDL_Quit();
}

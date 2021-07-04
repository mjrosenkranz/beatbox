const std = @import("std");
usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
});

var window: *SDL_Window = undefined;
var renderer: *SDL_Renderer = undefined;

pub fn init() !void {
    // init just video (we have audio on our own)
    if( SDL_Init(SDL_INIT_VIDEO) < 0 )
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

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED).?;
}

const KeyState = enum {
    Pressed,
    Released,
    None
};

// keys we are interested in
const targ = [_]usize {
    SDL_SCANCODE_Z, SDL_SCANCODE_X, SDL_SCANCODE_C, SDL_SCANCODE_V,
    SDL_SCANCODE_A, SDL_SCANCODE_S, SDL_SCANCODE_D, SDL_SCANCODE_F,
    SDL_SCANCODE_Q, SDL_SCANCODE_W, SDL_SCANCODE_E, SDL_SCANCODE_R,
    SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_4,
};

/// the state of the keys
pub var key_states: [16]KeyState = [_]KeyState{.None} ** 16;

var last_key_state: [16]bool = [_]bool{false} ** 16;

pub fn update() bool {
    var e: SDL_Event = undefined;

    while( SDL_PollEvent(&e) != 0 )
    {
        //User requests quit
        if(e.type == SDL_QUIT)
        {
            return false;
        }
    }

    _ = SDL_PumpEvents();

    // update keyboard state
    const keys = SDL_GetKeyboardState(null);
    key_states = [_]KeyState{.None} ** key_states.len;
    var i: usize = 0;
    while (i < targ.len) : (i+=1) {
        const pressed = keys[targ[i]] == 1;
        if (last_key_state[i] != pressed) {
                key_states[i] = if (pressed) KeyState.Pressed else KeyState.Released;
        }
        last_key_state[i] = pressed;
    }

    return true;
}

pub fn draw() void {
    _ = SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
    _ = SDL_RenderClear(renderer);
    _ = SDL_RenderPresent(renderer);
}

pub fn deinit() void {
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

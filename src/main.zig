const std = @import("std");
const sound = @import("sound.zig");


pub fn main() anyerror!void {

    try sound.setup();
    defer sound.shutdown();

    sound.loop();
   
    return;
}

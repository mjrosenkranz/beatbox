const std = @import("std");
const sound = @import("sound.zig");


pub fn main() anyerror!void {
    var ss = sound.Sounder.init();
    try ss.setup();
    defer ss.deinit();
    ss.loop();
    return;
}

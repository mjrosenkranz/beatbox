const std = @import("std");
const sound = @import("sound.zig");


pub fn main() anyerror!void {
    const ss = try sound.Sounder.init();
    defer ss.deinit();
    ss.loop();
    return;
}

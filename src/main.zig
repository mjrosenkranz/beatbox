const std = @import("std");
const os = std.os;
const math = std.math;
const sound = @import("sound.zig");
const input = @import("input.zig");
const osc = @import("oscillator.zig");
const env = @import("envelope.zig");


const keyboard = 
\\|   |   |   |   |   | |   |   |   |   | |   | |   |   |   |
\\|   | S |   |   | F | | G |   |   | J | | K | | L |   |   |
\\|   |___|   |   |___| |___|   |   |___| |___| |___|   |   |__
\\|     |     |     |     |     |     |     |     |     |     |
\\|  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  ,  |  .  |  /  |
\\|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
;

pub var freq: f64 = 0.0;
/// the base frequency of A2
const baseFreq = 110.0;
/// The 12th root since we are using the western scale
const d12thRootOf2 = std.math.pow(f64, 2.0, 1.0 / 12.0);
var myenv: env.ASDR = .{};
/// osc for our sine wave
inline fn makeNoise(t: f64) f64 {
    //return myenv.getAmp(t) * osc.osc(freq, t, .sin);
    return myenv.getAmp(t) * (
          osc.osc(freq*1.0, t, .sin)
        + osc.osc(freq*0.5, t, .sqr)
    );
}

pub fn main() anyerror!void {
    try input.init();
    defer input.deinit();
    // note we are playing
    var ss = sound.Sounder.init();
    ss.user_fn = makeNoise;
    try ss.setup();
    defer ss.deinit();


    //try input.init();
    //defer input.deinit();
    //var raw = try os.tcgetattr(0);
    //raw.iflag &= ~(@as(u16, os.BRKINT | os.ICRNL | os.INPCK | os.ISTRIP | os.IXON));
    //raw.oflag &= ~(@as(u8, os.OPOST));
    //raw.cflag |= (os.CS8);
    //raw.lflag &= ~(@as(u16, os.ECHO | os.ICANON | os.IEXTEN | os.ISIG));
    ////raw.cc[VMIN] = 0;
    ////raw.cc[VTIME] = 1;
    //try os.tcsetattr(0, os.TCSA.FLUSH, raw);

    //const stdin = std.io.getStdIn().inStream();
    //const stdout = std.io.getStdOut().outStream();
    //var char: u8 = undefined;
    const kb = [_]input.KeyCode{.KEY_Z,.KEY_S,.KEY_X,.KEY_C,.KEY_F,.KEY_V,.KEY_G,.KEY_N,
        .KEY_J,.KEY_M,.KEY_K,.KEY_COMMA,.KEY_L,.KEY_DOT,.KEY_SLASH};
    var currKey: i8 = -1;

    while (true) {
        var keyPressed = false;

        const char = try input.update();

        if (char[@enumToInt(input.KeyCode.KEY_Q)]) {
            std.log.info("quitting!", .{});
            break;
        }

        var k: usize = 0;
        while (k < kb.len) : (k+=1) {
            if (char[@enumToInt(kb[k])] and k != currKey) {
                @atomicStore(f64, &freq, baseFreq * std.math.pow(f64, d12thRootOf2, @intToFloat(f64, k)), .SeqCst);
                myenv.noteOn(ss.getTime());
                keyPressed = true;
                currKey = @intCast(i8, k);
            }
        }

        if (!keyPressed) {
            currKey = -1;
            myenv.noteOff(ss.getTime());
        }
    }


    //_ = try stdout.write("\x1b[2J");
    //_ = try stdout.write("\x1b[H");
    //// re-enable cursor
    //_ = try stdout.write("\x1B[?25h");
    //// Restore the original termios
    //try os.tcsetattr(0, os.TCSA.FLUSH, raw);
}

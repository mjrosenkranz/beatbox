const std = @import("std");
const os = std.os;
const math = std.math;
const sound = @import("sound.zig");
const input = @import("input.zig");

var r = std.rand.DefaultPrng.init(12345);

const keyboard = 
\\|   |   |   |   |   | |   |   |   |   | |   | |   |   |   |
\\|   | S |   |   | F | | G |   |   | J | | K | | L |   |   |
\\|   |___|   |   |___| |___|   |   |___| |___| |___|   |   |__
\\|     |     |     |     |     |     |     |     |     |     |
\\|  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  ,  |  .  |  /  |
\\|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
;

/// the base frequency of A2
const baseFreq = 110.0;
/// The 12th root since we are using the western scale
const d12thRootOf2 = std.math.pow(f64, 2.0, 1.0 / 12.0);
var freq: f64 = 0.0;

/// angular velocity helper func
inline fn w(hertz: f64) f64 {
    return 2.0 * math.pi * hertz;
}

const OscType = enum {
    /// normal sin wave
    sin,
    /// square wave
    sqr,
    /// triangle wave
    tri,
    /// real saw wave
    asaw,
    /// digital saw wave
    dsaw,
    /// random noise
    noise,
};

inline fn osc(hertz: f64 , dt: f64, oscType: OscType) f64 {
    return switch (oscType) {
        .sin => @sin(w(freq) * dt),
        .sqr => {
            if (@sin(w(freq) * dt) > 0) {
                return 1;
            } else {
                return 0;
            }
        },
        .tri => math.asin(@sin(w(freq) * dt)) * 2.0 / math.pi,
        .dsaw => (2.0 / math.pi) * (hertz * math.pi * @mod(dt, 1.0/hertz) - (2.0 / math.pi)),
        // TODO: fix this
        .asaw => {
            var output: f64 = 0.0;
            var n: f64 = 0;
            while(n < 40) : (n+=1) {
                output += (@sin(n * w(hertz) * dt)) / n;
            }
            return output * (2.0 / math.pi);
        },
        .noise => r.random.float(f64),
    };
}

/// osc for our sine wave
inline fn makeNoise(x: f64) f64 {
    return osc(freq, x, .tri);
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
            if (char[@enumToInt(kb[k])]) {
                @atomicStore(f64, &freq, baseFreq * std.math.pow(f64, d12thRootOf2, @intToFloat(f64, k)), .SeqCst);
                keyPressed = true;
            }
        }

        if (!keyPressed) {
            currKey = -1;
            @atomicStore(f64, &freq, 0.0, .SeqCst);
        }
    }


    //_ = try stdout.write("\x1b[2J");
    //_ = try stdout.write("\x1b[H");
    //// re-enable cursor
    //_ = try stdout.write("\x1B[?25h");
    //// Restore the original termios
    //try os.tcsetattr(0, os.TCSA.FLUSH, raw);
}

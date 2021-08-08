//! Backend for playing sounds on the sound card

const std = @import("std");
//const frame = @import("../frame.zig");

pub const Frame = packed struct {
    l: f32 = 0.0,
    r: f32 = 0.0,

    const Self = @This();

    /// multiply both values by amount
    pub fn times(self: Self, val: f32) callconv(.Inline) Self {
        return .{
            .l = self.l * val,
            .r = self.r * val,
        };
    }

    /// add the values of two frames together
    pub fn add(self: Self, other: Self) callconv(.Inline) Self {
        return .{
            .l = self.l + other.l,
            .r = self.r + other.r,
        };
    }

    /// clamp the values in the frame to -1 to 1
    pub fn clip(self: Self) callconv(.Inline) Self {
        return .{
            .l = math.clamp(self.l, -1, 1),
            .r = math.clamp(self.l, -1, 1),
        };
    }
};
/// import our alsa backend
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
    @cDefine("ALSA_PCM_NEW_HW_PARAMS_API", "1");
});

const AlsaError = error {
    FailedToOpen,
    FailedToSetHardware,
};

// samples per block 256
// blocks per queue 8
pub const Output = struct {
    /// sample rate of output
    rate: u32= 44100,
    /// number of channles (stero vs mono)
    channels: u8 = 2,
    /// hw handle used to control sound card
    handle: ?*c.snd_pcm_t = null,
    /// buffer for holding samples for the given block
    buffer: []i16 = undefined,
    /// number of frames per block
    frames: c.snd_pcm_uframes_t = 256,
    /// number of blocks we will use
    blocks: u8 = 4,
    /// callback function for creating sound
    //user_fn: ?fn(f64) Frame,
    /// cpu time
    cpu_time: f64 = 0.0,
    /// thread the main ouput loop will run in
    thread: *std.Thread = undefined,
    /// are we still running this app
    running: bool = true,

    allocator: *std.mem.Allocator,

    const Self = @This();

    // helper function to verify alsa functions
    fn validate(err: c_int) void {
        if (err < 0) {
            std.debug.warn("Alsa error: {s}\n", .{c.snd_strerror(err)});
        }
    }

    pub fn setup(self: *Self) !void {
        var params: ?*c.snd_pcm_hw_params_t = null;
        var rc: i32 = 0;
        var dir: i32 = 0;
        if (c.snd_pcm_open(&self.handle, "default",
                c._snd_pcm_stream.SND_PCM_STREAM_PLAYBACK, 0) != 0) {
            std.log.err("{s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToOpen;
        }

        validate(c.snd_pcm_hw_params_malloc(&params));

        validate(c.snd_pcm_hw_params_any(self.handle, params));

        validate(c.snd_pcm_hw_params_set_access(self.handle, params, c.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED));

        validate(c.snd_pcm_hw_params_set_format(self.handle, params,
            c.snd_pcm_format_t.SND_PCM_FORMAT_S16_LE));

        validate(c.snd_pcm_hw_params_set_channels(self.handle, params, self.channels));

        validate(c.snd_pcm_hw_params_set_rate_near(self.handle, params, &self.rate, &dir));

        validate(c.snd_pcm_hw_params_set_periods(self.handle, params, self.blocks, 0));

        validate(c.snd_pcm_hw_params_set_period_size_near(self.handle, params, &self.frames, &dir));

        rc = c.snd_pcm_hw_params(self.handle, params);
        if (rc < 0) {
            std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToSetHardware;
        }

        self.buffer = try self.allocator.alloc(i16, self.frames * self.channels);

        //self.thread = try std.Thread.spawn(loop, self);
    }

    fn loop(self: *Self) void {
        var total_frames: usize = 0;
        var j: i32 = 0;
        var y: f64 = 0;
        var x: f64 = 0;

        self.cpu_time = 0.0;
        const timeStep: f64 = 1.0/@intToFloat(f64, self.rate);

        var f = Frame{};

        var back = try self.allocator.alloc(i16, self.frames * self.channels);

        while (self.running) {
            //var f = self.user_fn.?(self.cpu_time).clip();
            f.l = @sin(2.0 * std.math.pi * 440.0 * @floatCast(f32, self.cpu_time));
            f.r = @sin(2.0 * std.math.pi * 440.0 * @floatCast(f32, self.cpu_time));
            
            self.buffer[0 + @intCast(usize, j)*2] = @floatToInt(i16, f.l * 32767);
            self.buffer[1 + @intCast(usize, j)*2] = @floatToInt(i16, f.r * 32767);
            self.cpu_time += timeStep;

            // If we have a buffer full of samples, write 1 period of 
            //samples to the sound card
            j+=1;
            if(j == self.frames){
                j = @intCast(i32, c.snd_pcm_writei(self.handle, &self.buffer[0], self.frames));

                // Check for under runs
                if (j < 0){
                    _ = c.snd_pcm_prepare(self.handle);
                    std.log.err("underrun", .{});
                }
                j = 0;
            }
        }
    }

    pub fn getTime(self: Self) callconv(.Inline) f64 {
        return self.cpu_time;
    }

    pub fn deinit(self: *Self) void {
        self.running = false;
        self.thread.wait();
        self.allocator.free(self.buffer);
        _ = c.snd_pcm_drain(self.handle);
        _ = c.snd_pcm_close(self.handle);

    }
};

test "run" {
    var o = Output{.allocator = std.testing.allocator};
    try o.setup();
    o.loop();
    o.deinit();
}

const std = @import("std");
const math = std.math;
const instrument = @import("instrument.zig");
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
    @cDefine("ALSA_PCM_NEW_HW_PARAMS_API", "1");
});

const AlsaError = error {
    FailedToOpen,
    FailedToSetHardware,
};

const alloc = std.heap.page_allocator;

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

pub const SoundOut = struct {
    rate: u32,
    amp: f64,
    channels: u8,
    handle: ?*c.snd_pcm_t = null,
    //buffer: []Frame = undefined,
    buffer: []i16 = undefined,
    frames: c.snd_pcm_uframes_t = 0,
    user_fn: ?fn(f64) Frame = null,
    /// global time
    gTime: f64 = 0.0,
    thread: *std.Thread = undefined,
    running: bool = true,

    const Self = @This();

    // TODO: get settings from struct
    pub fn init() Self {
        return Self{
            .rate = 44100,
            .amp = 16000,
            .channels = 2,
            .user_fn = null,
        };
    }

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

        _ = c.snd_pcm_hw_params_malloc(&params);

        _ = c.snd_pcm_hw_params_any(self.handle, params);

        _ = c.snd_pcm_hw_params_set_access(self.handle, params, c.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED);

        validate(c.snd_pcm_hw_params_set_format(self.handle, params,
            //c.snd_pcm_format_t.SND_PCM_FORMAT_FLOAT));
            c.snd_pcm_format_t.SND_PCM_FORMAT_S16_LE));

        _ = c.snd_pcm_hw_params_set_channels(self.handle, params, self.channels);

        _ = c.snd_pcm_hw_params_set_rate_near(self.handle, params, &self.rate, &dir);

        self.frames = 4;
        _ = c.snd_pcm_hw_params_set_period_size_near(self.handle, params, &self.frames, &dir);

        rc = c.snd_pcm_hw_params(self.handle, params);
        if (rc < 0) {
            std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToSetHardware;
        }

        //self.buffer = try alloc.alloc(Frame, self.frames);
        self.buffer = try alloc.alloc(i16, self.frames * self.channels);

        std.log.info("Starting new thread", .{});
        self.thread = try std.Thread.spawn(loop, self);
    }

    fn loop(self: *Self) void {
        var total_frames: usize = 0;
        var j: usize = 0;
        var y: f64 = 0;
        var x: f64 = 0;

        self.gTime = 0.0;
        const timeStep: f64 = 1.0/@intToFloat(f64, self.rate);

        while (self.running) {
            var frame = self.user_fn.?(self.gTime).clip();
            self.buffer[0 + j*2] = @floatToInt(i16, frame.l * 32767);
            self.buffer[1 + j*2] = @floatToInt(i16, frame.r * 32767);
            self.gTime += timeStep;

            // If we have a buffer full of samples, write 1 period of 
            //samples to the sound card
            j+=1;
            if(j == self.frames){
                j = @intCast(usize, c.snd_pcm_writei(self.handle, &self.buffer[0], self.frames));

                // Check for under runs
                if (j < 0){
                    c.snd_pcm_prepare(self.handle);
                }
                j = 0;
            }
        }
    }

    pub fn getTime(self: Self) callconv(.Inline) f64 {
        return self.gTime;
    }

    pub fn deinit(self: *Self) void {
        self.running = false;
        self.thread.wait();
        alloc.free(self.buffer);
        _ = c.snd_pcm_drain(self.handle);
        _ = c.snd_pcm_close(self.handle);

    }
};

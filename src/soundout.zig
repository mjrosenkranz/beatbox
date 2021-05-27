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

pub const SoundOut = struct {
    rate: u32,
    amp: f64,
    channels: u8,
    handle: ?*c.snd_pcm_t = null,
    //buffer: []i8 = undefined,
    buffer: []f32 = undefined,
    frames: c.snd_pcm_uframes_t = 0,
    user_fn: ?fn(f64) [2]f32 = null,
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

        _ = c.snd_pcm_hw_params_set_format(self.handle, params,
            //c.snd_pcm_format_t.SND_PCM_FORMAT_S16_LE);
            c.snd_pcm_format_t.SND_PCM_FORMAT_FLOAT_LE);

        _ = c.snd_pcm_hw_params_set_channels(self.handle, params, self.channels);

        _ = c.snd_pcm_hw_params_set_rate_near(self.handle, params, &self.rate, &dir);

        self.frames = 4;
        _ = c.snd_pcm_hw_params_set_period_size_near(self.handle, params, &self.frames, &dir);

        rc = c.snd_pcm_hw_params(self.handle, params);
        if (rc < 0) {
            std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToSetHardware;
        }

        //self.buffer = try alloc.alloc(i8, self.frames * @sizeOf(i16) * self.channels);
        self.buffer = try alloc.alloc(f32, self.frames * @sizeOf(f32) * self.channels);
        self.thread = try std.Thread.spawn(loop, self);
    }

    fn loop(self: *Self) void {
        var total_frames: usize = 0;
        var j: usize = 0;
        var y: f64 = 0;
        var x: f64 = 0;
        //var sample: i32 = 0;
        var sample: [4]u8 = undefined;

        self.gTime = 0.0;
        const timeStep: f64 = 1.0/@intToFloat(f64, self.rate);

        while (self.running) {
            // get the user function
//            y = math.clamp(self.user_fn.?(self.gTime), -1.0, 1.0);

            const floats = self.user_fn.?(self.gTime);
            //sample = self.user_fn.?(self.gTime);
            //self.buffer[0 + 4*j] = @bitCast(i8, sample[0]);
            //self.buffer[1 + 4*j] = @bitCast(i8, sample[1]);
            //self.buffer[2 + 4*j] = @bitCast(i8, sample[2]);
            //self.buffer[3 + 4*j] = @bitCast(i8, sample[3]);

            // get two i16s from the buffer
            //const i16s = @bitCast([2]i16, sample);
            // get number 0 to 1 for each i16
            //const floats = [_]f32 {
            //    @intToFloat(f32, i16s[0]) / 65536.0,
            //    @intToFloat(f32, i16s[1]) / 65536.0,
            //};
            //// translate back into integer samples
            //const isample = [_]i32 {
            //    @floatToInt(i32, self.amp * floats[0]),
            //    @floatToInt(i32, self.amp * floats[1]),
            //};
            self.buffer[0 + 2*j] = floats[0];
            self.buffer[1 + 2*j] = floats[1];

            //self.buffer[0 + 4*j] = @truncate(i8, (isample[0]));
            //self.buffer[1 + 4*j] = @truncate(i8, isample[0] >> 8);
            //self.buffer[2 + 4*j] = @truncate(i8, (isample[1]));
            //self.buffer[3 + 4*j] = @truncate(i8, isample[1] >> 8);

            self.gTime += timeStep;

            // If we have a buffer full of samples, write 1 period of 
            //samples to the sound card
            j+=1;
            total_frames+=1;
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

    pub fn getTime(self: Self) f64 {
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


fn dummyfn(x: f64) f64 {
    return 0.0;
}

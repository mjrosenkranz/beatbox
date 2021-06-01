const std = @import("std");
const frame = @import("frame.zig");
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
    buffer: []i16 = undefined,
    frames: c.snd_pcm_uframes_t = 0,
    user_fn: ?fn(f64) frame.Frame = null,
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
        var hwparams: ?*c.snd_pcm_hw_params_t = null;
        var swparams: ?*c.snd_pcm_sw_params_t = null;
        var rc: i32 = 0;
        var dir: i32 = 0;
        if (c.snd_pcm_open(&self.handle, "default",
                c._snd_pcm_stream.SND_PCM_STREAM_PLAYBACK, 0) != 0) {
            std.log.err("{s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToOpen;
        }

        // get a new hardware param struct
        validate(c.snd_pcm_hw_params_malloc(&hwparams));

        // fill in any parameters already set
        validate(c.snd_pcm_hw_params_any(self.handle, hwparams));

        // set frames to be interleaved
        validate(c.snd_pcm_hw_params_set_access(self.handle, hwparams, c.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED));

        // set the format
        validate(c.snd_pcm_hw_params_set_format(self.handle, hwparams,
            c.snd_pcm_format_t.SND_PCM_FORMAT_S16_LE));

        // set number of channels
        validate(c.snd_pcm_hw_params_set_channels(self.handle, hwparams, self.channels));

        // set the sample rate
        validate(c.snd_pcm_hw_params_set_rate_near(self.handle, hwparams, &self.rate, &dir));

//        self.frames = 4;
//        _ = c.snd_pcm_hw_params_set_period_size_near(self.handle, hwparams, &self.frames, &dir);

        rc = c.snd_pcm_hw_params(self.handle, hwparams);
        if (rc < 0) {
            std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToSetHardware;
        }
        _ = c.snd_pcm_hw_params_free(hwparams);

        // allocate sw params
        validate(c.snd_pcm_sw_params_malloc(&swparams));

        // fill the struct with current values
        validate(c.snd_pcm_sw_params_current(self.handle, swparams));

        // set minimum sample wakeup time
        validate(c.snd_pcm_sw_params_set_avail_min(self.handle, swparams, 4096));
        // set start threshold
        validate(c.snd_pcm_sw_params_set_start_threshold(self.handle, swparams, 0));
        // set sw params
        if(c.snd_pcm_sw_params(self.handle, swparams) < 0) {
            @panic("could not set software params");
        }

        if(c.snd_pcm_prepare(self.handle) < 0) {
            @panic("could not prepare sound card");
        }

        //self.buffer = try alloc.alloc(i16, self.frames * self.channels);
        self.buffer = try alloc.alloc(i16, 4096 * 2);

        std.log.info("Starting new thread", .{});
        self.thread = try std.Thread.spawn(loop, self);
    }

    fn loop(self: *Self) void {
        var total_frames: usize = 0;
        var y: f64 = 0;
        var x: f64 = 0;

        self.gTime = 0.0;
        const timeStep: f64 = 1.0/@intToFloat(f64, self.rate);

        while (self.running) {

            // wait until the interface is ready
            validate(c.snd_pcm_wait(self.handle, 1000));

            // find out how many frames to deliver
            var framesNeeded = c.snd_pcm_avail_update(self.handle);

            // check if theres an xrun, bail out for now
            if (framesNeeded < 0 and framesNeeded == -c.EPIPE) {
                std.log.warn("xrun!!!", .{});
                break;
            }

            // clamp to the max frames in our buffer
            framesNeeded = if (framesNeeded > 4096) 4096 else framesNeeded;
                std.log.info("frames needed: {}", .{framesNeeded});

            // otherwise we are safe to continue
            // fill the buffer
            var j: usize = 0;
            while (j < framesNeeded) : (j += 1) {
                var f = self.user_fn.?(self.gTime).clip();
                self.buffer[0 + @intCast(usize, j)*2] = @floatToInt(i16, f.l * 32767);
                self.buffer[1 + @intCast(usize, j)*2] = @floatToInt(i16, f.r * 32767);
                self.gTime += timeStep;
            }
            // write buffer out
            if (c.snd_pcm_writei(self.handle, &self.buffer[0], @intCast(c_ulong, framesNeeded)) < 0) {
                std.log.warn("couldn't write to card?", .{});
                _ = c.snd_pcm_prepare(self.handle);
            }

            // If we have a buffer full of samples, write 1 period of 
            //samples to the sound card
            //j+=1;
            //if(j == self.frames){
            //    j = @intCast(i32, c.snd_pcm_writei(self.handle, &self.buffer[0], self.frames));

            //    // Check for under runs
            //    if (j < 0){
            //        _ = c.snd_pcm_prepare(self.handle);
            //    }
            //    j = 0;
            //}
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

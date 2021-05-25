const std = @import("std");
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
    @cDefine("ALSA_PCM_NEW_HW_PARAMS_API", "1");
});

const AlsaError = error {
    FailedToOpen,
    FailedToSetHardware,
};

const alloc = std.heap.page_allocator;

pub const Sounder = struct {
    rate: u32,
    amp: f64,
    channels: u8,
    handle: ?*c.snd_pcm_t = null,
    buffer: []i8 = undefined,
    frames: c.snd_pcm_uframes_t = 0,
    user_fn: ?fn(f64) f64 = null,
    thread: *std.Thread = undefined,

    const Self = @This();

    // TODO: get settings from struct
    pub fn init() Self {
        return Self{
            .rate = 44100,
            .amp = 15000,
            .channels = 2,
            .user_fn = dummyfn,
        };
    }

    pub fn setup(self: *Self) !void {
        var params: ?*c.snd_pcm_hw_params_t = null;
        var rc: i32 = 0;
        var dir: i32 = 0;
        if (c.snd_pcm_open(&self.handle, "default",
                c._snd_pcm_stream.SND_PCM_STREAM_PLAYBACK, 0) != 0) {
            std.log.err("{c}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToOpen;
        }

        _ = c.snd_pcm_hw_params_malloc(&params);

        _ = c.snd_pcm_hw_params_any(self.handle, params);

        _ = c.snd_pcm_hw_params_set_access(self.handle, params, c.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED);

        _ = c.snd_pcm_hw_params_set_format(self.handle, params,
            c.snd_pcm_format_t.SND_PCM_FORMAT_S16_BE);

        _ = c.snd_pcm_hw_params_set_channels(self.handle, params, self.channels);

        _ = c.snd_pcm_hw_params_set_rate_near(self.handle, params, &self.rate, &dir);

        self.frames = 4;
        _ = c.snd_pcm_hw_params_set_period_size_near(self.handle, params, &self.frames, &dir);

        rc = c.snd_pcm_hw_params(self.handle, params);
        if (rc < 0) {
            std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToSetHardware;
        }

        self.buffer = try alloc.alloc(i8, self.frames * @sizeOf(i16) * self.channels);
        self.thread = try std.Thread.spawn(self,loop);
    }

    fn loop(self: *Self) void {
        var i: i32 = 0;
        var j: usize = 0;
        var y: f64 = 0;
        var x: f64 = 0;
        var sample: i32 = 0;
        while (true) : (i+=1){
            x = @intToFloat(f64, i) / @intToFloat(f64, self.rate);
            // get the user function
            y = self.user_fn.?(x);
            sample = @floatToInt(i32, self.amp * y);

            self.buffer[0 + 4*j] = @truncate(i8, sample >> 8);
            self.buffer[1 + 4*j] = @truncate(i8, (sample));
            self.buffer[2 + 4*j] = @truncate(i8, sample >> 8);
            self.buffer[3 + 4*j] = @truncate(i8, (sample));

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

    pub fn deinit(self: Self) void {
        self.thread.wait();
        alloc.free(self.buffer);
        _ = c.snd_pcm_drain(self.handle);
        _ = c.snd_pcm_close(self.handle);

    }
};


fn dummyfn(x: f64) f64 {
    return 0.0;
}

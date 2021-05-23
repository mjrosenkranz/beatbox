const std = @import("std");
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
    @cDefine("ALSA_PCM_NEW_HW_PARAMS_API", "1");
});

const freq: f64 = 440.0;
inline fn wav(x: f64) f64 {
    const y = @sin(2.0 * 3.14159 * freq * x);
    return y;
}

const AlsaError = error {
    FailedToOpen,
    FailedToSetHardware,
};

const alloc = std.heap.page_allocator;

pub const Sounder = struct {
    // TODO: check if we can create something with these settings

    rate: i32,
    amp: f64,
    handle: ?*c.snd_pcm_t = null,
    buffer: []i8 = undefined,
    frames: c.snd_pcm_uframes_t = 0,

    const Self = @This();

    pub fn init() !Self {
        var rate: c_uint = 44100;
        var handle: ?*c.snd_pcm_t = null;
        var params: ?*c.snd_pcm_hw_params_t = null;
        var buffer: []i8 = undefined;
        var frames: c.snd_pcm_uframes_t = 0;
        var rc: i32 = 0;
        var dir: i32 = 0;

        // Open PCM device for playback. */
        if (c.snd_pcm_open(&handle, "default",
            c._snd_pcm_stream.SND_PCM_STREAM_PLAYBACK, 0) != 0) {
            std.log.err("{c}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToOpen;
        }

        // Allocate a hardware parameters object. */
        _ = c.snd_pcm_hw_params_malloc(&params);

        // Fill it in with default values. */
        _ = c.snd_pcm_hw_params_any(handle, params);

        // Set the desired hardware parameters. */

        // Interleaved mode */
        _ = c.snd_pcm_hw_params_set_access(handle, params,
            c.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED);

        // Signed 16-bit little-endian format */
        _ = c.snd_pcm_hw_params_set_format(handle, params,
            c.snd_pcm_format_t.SND_PCM_FORMAT_S16_BE);

        // Two channels (stereo) */
        _ = c.snd_pcm_hw_params_set_channels(handle, params, 2);

        // 44100 bits/second sampling rate (CD quality) */
        _ = c.snd_pcm_hw_params_set_rate_near(handle, params, &rate, &dir);

        // Set period size to 32 frames. */
        frames = 4;
        _ = c.snd_pcm_hw_params_set_period_size_near(handle, params, &frames, &dir);

        // Write the parameters to the driver */
        rc = c.snd_pcm_hw_params(handle, params);
        if (rc < 0) {
            std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
            return AlsaError.FailedToSetHardware;
        }

        buffer = try alloc.alloc(i8, frames * 4);

        return Self{
            .rate = @intCast(i32, rate),
            .amp= 10000,
            .handle = handle,
            //.params = params,
            .buffer = buffer,
            .frames = frames,
        };
    }

    pub fn loop(self: Self) void {
        var i: i32 = 0;
        var j: usize = 0;
        var y: f64 = 0;
        var x: f64 = 0;
        var sample: i32 = 0;

        while (true) : (i+=1){
            x = @intToFloat(f64, i) / @intToFloat(f64, self.rate);
            y = wav(x);
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
        alloc.free(self.buffer);
        _ = c.snd_pcm_drain(self.handle);
        _ = c.snd_pcm_close(self.handle);

    }
};


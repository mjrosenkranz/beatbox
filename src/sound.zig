const std = @import("std");
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
    @cDefine("ALSA_PCM_NEW_HW_PARAMS_API", "1");
});

const freq: f64 = 440.0;
inline fn wav(dt: f64) f64 {
    const o = @sin(2.0 * 3.14159 * freq * x);
    return o;
}

const rate = 44100;
const amp = 10000;
const seconds = 3;
var rc: i32 = 0;
var size: u64 = 0;
var handle: ?*c.snd_pcm_t = undefined;
var params: ?*c.snd_pcm_hw_params_t = undefined;
var val: u32 = undefined;
var dir: i32 = 0;
var frames: c.snd_pcm_uframes_t = 0;
var sample: i32 = 0;
var y: f64 = 0;
var x: f64 = 0;
const alloc = std.heap.page_allocator;
var buffer: []i8 = undefined;


pub fn setup() !void {
    // Open PCM device for playback. */
    rc = c.snd_pcm_open(&handle, "default",
        c._snd_pcm_stream.SND_PCM_STREAM_PLAYBACK, 0);
    if (rc < 0) {
        std.log.err("{c}", .{c.snd_strerror(rc)});
        return;
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
    val = 44100;
    _ = c.snd_pcm_hw_params_set_rate_near(handle, params, &val, &dir);

    // Set period size to 32 frames. */
    frames = 4;
    _ = c.snd_pcm_hw_params_set_period_size_near(handle, params, &frames, &dir);

    // Write the parameters to the driver */
    rc = c.snd_pcm_hw_params(handle, params);
    if (rc < 0) {
        std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
        return;
    }

    buffer = try alloc.alloc(i8, frames * 4);
}

pub fn loop() void {
    var i: i32 = 0;
    var j: usize = 0;
    while (true) : (i+=1){
        x = @intToFloat(f64, i) / @intToFloat(f64, rate);
        y = wav(x);
        sample = @floatToInt(i32, amp * y);

        buffer[0 + 4*j] = @truncate(i8, sample >> 8);
        buffer[1 + 4*j] = @truncate(i8, (sample));
        buffer[2 + 4*j] = @truncate(i8, sample >> 8);
        buffer[3 + 4*j] = @truncate(i8, (sample));

        // If we have a buffer full of samples, write 1 period of 
        //samples to the sound card
        j+=1;
        if(j == frames){
            j = @intCast(usize, c.snd_pcm_writei(handle, &buffer[0], frames));

            // Check for under runs
            if (j < 0){
                c.snd_pcm_prepare(handle);
            }
            j = 0;
        }
    }
}

pub fn shutdown() void {
    alloc.free(buffer);
    _ = c.snd_pcm_drain(handle);
    _ = c.snd_pcm_close(handle);

}

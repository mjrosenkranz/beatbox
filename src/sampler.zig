// TODO: functions for converting samples
pub const Sample = struct {
    // TODO change this to an array of frames
    data: []u8,
};

pub const Sampler = struct {
    volume: f64 = 1.0,
    sample: Sample,

    pub fn play(n: *notes.Note) soundout.Frame {

        // index into the sample based on the time
        const i = @mod(@floatToInt(usize, t * 44100), sample.data.len/4);
        const sample_bytes = [_]u8{
            sample.data[0 + 4*i],
            sample.data[1 + 4*i], 
            sample.data[2 + 4*i], 
            sample.data[3 + 4*i],
        };


        const i16s = @bitCast([2]i16, snare_bytes);

        //get number -1 to 1 for each i16
        var frame: soundout.Frame = .{
            .l = @intToFloat(f64, i16s[0]) / 65536.0,
            .r = @intToFloat(f64, i16s[1]) / 65536.0,
        };

        return frame.times(volume);
    }
};

//const snare = @embedFile("../samples/Snare_s16le.raw");

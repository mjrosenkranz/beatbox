const notes = @import("notes.zig");

pub const ASDR = struct {
    attack: f64 = 0.1,
    decay: f64 = 0.1,
    release: f64 = 0.2,

    startAmp: f64 = 1.0,
    sustainAmp: f64 = 0.8,

    const Self = @This();

    pub fn getAmp(self: Self, t: f64, n: *notes.Note) f64 {
        var amp: f64 = 0.0;
        // emplitude for release
        var ramp: f64 = 0.0;

        if (n.on > n.off) {
            const lifeTime = t - n.on;
            // attack
            if (lifeTime <= self.attack) {
                amp = (lifeTime / self.attack) * self.startAmp;
            }

            // decay
            if (lifeTime > self.attack and lifeTime <= (self.attack + self.decay)) {
                amp = ((lifeTime - self.attack)/self.decay) * (self.sustainAmp - self.startAmp) + self.startAmp;
            }

            // sustain
            if (lifeTime > (self.attack + self.decay)) {
                amp = self.sustainAmp;
            }
        } else {
            const lifeTime = n.off - n.on;
            // attack
            if (lifeTime <= self.attack) {
                ramp = (lifeTime / self.attack) * self.startAmp;
            }

            // decay
            if (lifeTime > self.attack and lifeTime <= (self.attack + self.decay)) {
                ramp = ((lifeTime - self.attack)/self.decay) * (self.sustainAmp - self.startAmp) + self.startAmp;
            }

            // sustain
            if (lifeTime > (self.attack + self.decay)) {
                ramp = self.sustainAmp;
            }
            // R
            amp = ((t - n.off) / self.release) * (0.0 - ramp) + ramp;
            // deactivate the note if we have finished the release
            if (t > n.off + self.release)
                n.active = false;

        }



        if (amp < 0.0001) {
            return 0.0;
        }

        return amp;
    }
};

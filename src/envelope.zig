pub const ASDR = struct {
    attack: f64 = 0.1,
    decay: f64 = 0.1,
    release: f64 = 0.2,

    startAmp: f64 = 1.0,
    sustainAmp: f64 = 0.8,

    const Self = @This();

    pub fn getAmp(self: Self, t: f64, on: f64, off: f64) f64 {
        var amp: f64 = 0.0;
        // emplitude for release
        var ramp: f64 = 0.0;

        if (on > off) {
            const lifeTime = t - on;
            // attack
            if (lifeTime <= self.attack) {
                amp = (lifeTime / self.attack) * self.startAmp;
            }

            // decay
            if (lifeTime > self.attack and lifeTime <= (self.attack + self.decay)) {
                //     | how far we are into decay   | difference in amp    | add the initial amp
                //     V                             V                      V
                amp = ((lifeTime - self.attack)/self.decay) * (self.sustainAmp - self.startAmp) + self.startAmp;
            }

            // sustain
            if (lifeTime > (self.attack + self.decay)) {
                amp = self.sustainAmp;
            }
        } else {
            const lifeTime = off - on;
            // attack
            if (lifeTime <= self.attack) {
                ramp = (lifeTime / self.attack) * self.startAmp;
            }

            // decay
            if (lifeTime > self.attack and lifeTime <= (self.attack + self.decay)) {
                //     | how far we are into decay   | difference in amp    | add the initial amp
                //     V                             V                      V
                ramp = ((lifeTime - self.attack)/self.decay) * (self.sustainAmp - self.startAmp) + self.startAmp;
            }

            // sustain
            if (lifeTime > (self.attack + self.decay)) {
                ramp = self.sustainAmp;
            }
            // R
            amp = ((t - off) / self.release) * (0.0 - ramp) + ramp;
        }


        if (amp < 0.0001) {
            return 0.0;
        }

        return amp;
    }

//    pub fn noteOn(self: *Self, t: f64) void {
//        self.triggerOnTime = t;
//        self.isNoteOn = true;
//    }
//
//    pub fn noteOff(self: *Self, t: f64) void {
//        self.triggerOffTime = t;
//        self.isNoteOn = false;
//    }
};

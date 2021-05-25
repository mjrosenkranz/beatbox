
pub const ASDR = struct {
    attack: f64 = 0.1,
    decay: f64 = 0.01,
    release: f64 = 0.2,

    startAmp: f64 = 1.0,
    sustainAmp: f64 = 0.8,

    triggerOnTime: f64 = 0.0,
    triggerOffTime: f64 = 0.0,

    isNoteOn: bool = false,

    const Self = @This();

    pub fn getAmp(self: Self, t: f64) f64 {
        var amp: f64 = 0.0;
        // time since note was pressed:
        const lifeTime = t - self.triggerOnTime;

        if (self.isNoteOn) {
            // ADS
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
            // R
            amp = ((t - self.triggerOffTime) / self.release) * (0.0 - self.sustainAmp) + self.sustainAmp;
        }

        if (amp < 0.0001) {
            return 0.0;
        }
        return amp;
    }

    pub fn noteOn(self: *Self, t: f64) void {
        self.triggerOnTime = t;
        self.isNoteOn = true;
    }

    pub fn noteOff(self: *Self, t: f64) void {
        self.triggerOffTime = t;
        self.isNoteOn = false;
    }
};

const math = @import("std").math;
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

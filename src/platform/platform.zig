// TODO: hide this from public api and separate keyboard from gui
pub const backend = @import("backend.zig");

/// Sound output
const output = @import("output.zig");
pub const Output = output.Output;

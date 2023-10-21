const std = @import("std");

const s = @import("./server.zig");

pub fn main() !void {
    var server = s.Server{};
    try server.Listen("127.0.0.1", 8888);
}
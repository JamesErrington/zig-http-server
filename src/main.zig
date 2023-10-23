const std = @import("std");

const s = @import("./server.zig");
const req = @import("./request.zig");

pub fn main() !void {
    const request = req.MakeRoute("/{user}/{id}"){ .params = .{ .id = "hello", .user = "mum" } };
    _ = request;

    var server = s.Server{};
    try server.Listen("127.0.0.1", 8888);
}
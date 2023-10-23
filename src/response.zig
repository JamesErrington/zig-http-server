const std = @import("std");
const http = @import("./http.zig");

const DEFAULT_VERSION = http.Version.@"HTTP/1.1";
const DEFAULT_STATUS = http.Status.OK;

const Parts = struct {
    version: http.Version = DEFAULT_VERSION,
    status: http.Status = DEFAULT_STATUS,
    body: ?[]const u8 = null,
};

pub const Response = struct {
    parts: Parts,

    pub fn builder() Builder {
        return Builder{ .inner = Parts{} };
    }

    pub fn into_buffer(self: Response, buffer: []u8) []u8 {
        return std.fmt.bufPrint(buffer, "{s} {}\r\n\r\n", .{@tagName(self.parts.version), @intFromEnum(self.parts.status)}) catch unreachable;
    }
};

const Builder = struct {
    inner: Parts,

    pub fn status(self: *Builder, new_status: http.Status) *Builder {
        self.inner.status = new_status;
        return self;
    }

    pub fn build(self: *Builder) Response {
        return Response {
            .parts = self.inner,
        };
    }
};
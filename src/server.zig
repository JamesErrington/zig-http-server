const std = @import("std");
const builtin = @import("builtin");
const http = @import("./http.zig");
const res = @import("./response.zig");

const os = std.os;
const mem = std.mem;
const debug = std.debug;
const assert = std.debug.assert;

const Header = std.StringHashMap([]const u8);

pub const Server = struct {
    const Self = @This();

    sockfd: ?os.socket_t = null,

    pub fn Listen(self: *Self, host: []const u8, port: u16) !void {
        self.sockfd = try os.socket(2, 1, 6);
        defer os.close(self.sockfd.?);

        const addr = try make_sockaddr(host, port);
        try os.bind(self.sockfd.?, &addr, @sizeOf(os.sockaddr));

        try os.listen(self.sockfd.?, 5);
        debug.print("Server listening on {s}:{d}\n", .{host, port});

        while (true) {
            var incoming_addr: ?*os.sockaddr = null;
            var addr_size: ?*os.socklen_t = null;
            const connfd = try os.accept(self.sockfd.?, incoming_addr, addr_size, 0);
            defer os.close(connfd);

            var buffer: [1024]u8 = undefined;
            const bytes = try os.read(connfd, &buffer);
            debug.print("Read {} bytes:\n", .{bytes});

            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            var arena = std.heap.ArenaAllocator.init(gpa.allocator());
            const allocator = arena.allocator();
            defer arena.deinit();

            var headers = Header.init(allocator);
            parse_request(buffer[0..bytes], &headers);

            var builder = res.Response.builder();
            const response = builder.status(http.Status.OK).build();
            debug.print("Response(Version: {}, Status: {})", .{response.parts.version, response.parts.status});
            var response_buffer: [1024]u8 = undefined;

            _ = try os.write(connfd, response.into_buffer(&response_buffer));   
        }
    }
};

// os.sockaddr{.family = 2, .data = [14]u8{ 0x22, 0xb8, 0x7f, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }}
fn make_sockaddr(host: []const u8, port: u16) !os.sockaddr {
    var sockaddr = comptime brk: {
        break :brk switch(builtin.os.tag) {
            .windows => os.sockaddr{
                .family = 2,
                .data = undefined,
            },
            .macos => os.sockaddr{
                .family = 2,
                .data = undefined,
                .len = 0,
            },
            else => unreachable,
        };
    };

    const bytes = std.mem.toBytes(port);
    comptime assert(bytes.len == 2);
    // Swap bytes to be the right order
    // @FIXME: this probably isn't compatible everywhere
    sockaddr.data[0] = bytes[1];
    sockaddr.data[1] = bytes[0];

    var s: usize = 0; var idx: usize = 2;
    for (host, 0..) |char, i| {
        if (char == '.' or i == host.len-1) {
            const end = if (i == host.len-1) i + 1 else i;
            const byte = try std.fmt.parseInt(u8, host[s..end], 10);
            sockaddr.data[idx] = byte;
            s = i + 1; idx += 1;
        }
    }

    return sockaddr;
}

fn parse_request(bytes: []const u8, headers: *Header) void {
    var iter = mem.tokenizeAny(u8, bytes, "\r\n");

    // GET / HTTP/1.1
    const request_line = iter.next() orelse unreachable;
    const method_end_idx = mem.indexOfScalar(u8, request_line, ' ') orelse unreachable;
    const method_str = request_line[0..method_end_idx];
    const method = std.meta.stringToEnum(http.Method, method_str) orelse unreachable;
    debug.print("Method: {any}\n", .{method});

    const version_start_idx = mem.lastIndexOfScalar(u8, request_line, ' ') orelse unreachable;
    const version_str = request_line[version_start_idx+1..];
    debug.print("Version: {s}\n", .{version_str});

    const target = request_line[method_end_idx+1..version_start_idx];
    debug.print("Target: {s}\n", .{target});

    while (iter.next()) |header_line| {
        const sep_idx = mem.indexOfScalar(u8, header_line, ':') orelse unreachable;
        const key = header_line[0..sep_idx];
        const value = header_line[sep_idx+2..];

        debug.print("{s}: {s}\n", .{key, value});
        headers.put(key, value) catch unreachable;
    }
}
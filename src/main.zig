const std = @import("std");

const os = std.os;
const mem = std.mem;
const debug = std.debug;
const assert = std.debug.assert;

const Header = std.StringHashMap([][]const u8);

pub fn main() !void {
    var sockfd = try os.socket(2, 1, 6);
    defer os.close(sockfd);
    
    const addr = try make_sockaddr("127.0.0.1", 8888);
    try os.bind(sockfd, &addr, @sizeOf(os.sockaddr));
    std.log.info("Socket bound!", .{});

    try os.listen(sockfd, 5);
    std.log.info("Socket listening!", .{});

    while (true) {
        var incoming_addr: ?*os.sockaddr = null;
        var addr_size: ?*os.socklen_t = null;
        const connfd = try os.accept(sockfd, incoming_addr, addr_size, 0);
        defer os.close(connfd);
        std.log.info("Connection accepted!", .{});

        var buffer: [1024]u8 = undefined;
        const bytes = try os.read(connfd, &buffer);
        std.log.info("Read {} bytes:", .{bytes});
        std.debug.print("{s}\n", .{buffer[0..bytes]});

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        var arena = std.heap.ArenaAllocator.init(gpa.allocator());
        const allocator = arena.allocator();
        defer arena.deinit();

        var headers = Header.init(allocator);
        parse_request(buffer[0..bytes], &headers);

        _ = try os.write(connfd, &buffer);   
    }
}

// os.sockaddr{.family = 2, .data = [14]u8{ 0x22, 0xb8, 0x7f, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }}
fn make_sockaddr(host: []const u8, port: u16) !os.sockaddr {
    var addr = os.sockaddr{
        .family = 2,
        .data = undefined,
    };

    const bytes = std.mem.toBytes(port);
    comptime assert(bytes.len == 2);
    // Swap bytes to be the right order
    // @FIXME: this probably isn't compatible everywhere
    addr.data[0] = bytes[1];
    addr.data[1] = bytes[0];

    var s: usize = 0; var idx: usize = 2;
    for (host, 0..) |char, i| {
        if (char == '.' or i == host.len-1) {
            const end = if (i == host.len-1) i + 1 else i;
            const byte = try std.fmt.parseInt(u8, host[s..end], 10);
            addr.data[idx] = byte;
            s = i + 1; idx += 1;
        }
    }

    return addr;
}

fn parse_request(bytes: []const u8, headers: *Header) void {
    _ = headers;
    var iter = mem.tokenizeAny(u8, bytes, "\r\n");
    const request_line = iter.next() orelse unreachable;

    const method_end_idx = mem.indexOfScalar(u8, request_line, ' ') orelse unreachable;
    const method_str = request_line[0..method_end_idx];
    debug.print("{s}\n", .{method_str});
}
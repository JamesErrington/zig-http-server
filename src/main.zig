const std = @import("std");
const os = std.os;
const assert = std.debug.assert;

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

    std.debug.print("{any}\n", .{addr.data});
    return addr;
}
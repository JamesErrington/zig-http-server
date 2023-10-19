const std = @import("std");
const os = std.os;

const addr = os.sockaddr{.family = 2, .data = [14]u8{ 0x22, 0xb8, 0x7f, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }};

pub fn main() !void {
    var socket = try os.socket(2, 1, 6);
    
    try os.bind(socket, &addr, @sizeOf(os.sockaddr));
    std.log.info("Socket bound!", .{});

    try os.listen(socket, 5);
    std.log.info("Socket listening!", .{});


    while (true) {
        var incoming_addr: ?*os.sockaddr = null;
        var addr_size: ?*os.socklen_t = null;
        const connfd = try os.accept(socket, incoming_addr, addr_size, 0);
        std.log.info("Connection accepted!", .{});

        var buffer: [1024]u8 = undefined;
        const bytes = try os.read(connfd, &buffer);
        std.log.info("Read {} bytes:", .{bytes});
        std.debug.print("{s}\n", .{buffer[0..bytes]});

        _ = try os.write(connfd, &buffer);
        
        os.close(connfd);
    }
}
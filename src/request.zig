const std = @import("std");

pub fn Request(comptime Params: type) type {
    return struct {
        params: Params
    };
}

pub fn MakeRoute(comptime path: []const u8, ) type {
    // We can find an upper limit of params by just counting how many { we see
    comptime var upper = 0;
    inline for (path) |char| {
        if (char == '{') {
            upper += 1;
        }
    }

    // @TODO: If we see no {, we can ignore this construction phase completely
    if (upper == 0) {

    }

    comptime var params: [upper][]const u8 = undefined;
    comptime var param_i = 0;

    // Find all the strings contained between {} and extract them as field names in the struct
    {
        comptime var i = 0;
        inline while (i < path.len) : (i += 1) {
            // Search for a { or }
            inline while (i < path.len) : (i += 1) {
                switch (path[i]) {
                    '{', '}' => break,
                    else => continue,
                }
            }
            // @TODO: add escape logic {{ }}
            // If we find a close brace first we are missing the opening one
            if (path[i] == '}') {
                @compileError("missing opening {");
            }

            i += 1;
            const start_index = i;
            
            // Find the }
            inline while (i < path.len and path[i] != '}') : (i += 1) {}
            // If we reach the end we didn't find the closing brace
            if (i >= path.len) {
                @compileError("missing closing }");
            }
            // If the closing } is next to the opening { we are missing a name
            if (i == start_index) {
                @compileError("missing param name");
            }
            // @TODO: Add a check for valid names

            params[param_i] = path[start_index..i];
            param_i += 1;
        }
    }

    comptime var fields: [param_i]std.builtin.Type.StructField = undefined;
    comptime var i = 0;
    inline while (i < param_i) : (i += 1) {
        const param_name = params[i];
        fields[i] = .{
            .name = param_name,
            .type = []const u8,
            .default_value = null,
            .is_comptime = false,
            .alignment = 0,
        };
    }

    const ParamsType = @Type(.{
        .Struct = .{
            .layout = .Auto,
            .fields = &fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        }
    });

    return Request(ParamsType);
}
pub const Version = enum {
    @"HTTP/1.1",   
};

// https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
pub const Method = enum {
    GET,
};

// https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
pub const Status = enum(u10) {
    OK = 200,
    INTERNAL_SERVER_ERROR = 500,
};
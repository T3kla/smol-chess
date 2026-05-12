const std = @import("std");
const chess = @import("chess.zig");
const print = std.debug.print;

pub const W = 80;
pub const H = 60;

pub fn main(init: std.process.Init) !void {
    var obuff: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(init.io, &obuff);
    const stdout = &writer.interface;

    var ibuff: [64]u8 = undefined;
    var reader = std.Io.File.stdin().reader(init.io, &ibuff);
    const stdin = &reader.interface;

    var board = chess.Board.init();

    var turn: u32 = 0;
    while (true) : (turn += 0) {
        try stdout.print("\x1B[2J\x1B[H", .{});

        try board.printBoard(stdout);
        try stdout.print("         {s} turn: ", .{if (turn % 2 == 0) "White" else "Black"});

        try stdout.flush();

        const bare_line = try stdin.takeDelimiter('\n') orelse continue;
        _ = std.mem.trim(u8, bare_line, "\r");
    }
}

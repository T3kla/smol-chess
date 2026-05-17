const std = @import("std");
const chess = @import("chess.zig");
const Color = chess.Piece.Color;
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    var obuff: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(init.io, &obuff);
    const stdout = &writer.interface;

    var ibuff: [64]u8 = undefined;
    var reader = std.Io.File.stdin().reader(init.io, &ibuff);
    const stdin = &reader.interface;

    var board = chess.Board.init();

    var t: u64 = 0;

    while (true) {
        const color = if (t % 2 == 0) Color.white else Color.black;

        try stdout.print("\x1B[2J\x1B[H", .{});
        try board.printBoard(stdout);
        try stdout.print("         {s} turn: ", .{if (color == Color.white) "White" else "Black"});
        try stdout.flush();

        const bare_line = try stdin.takeDelimiter('\n') orelse continue;
        const line = std.mem.trim(u8, bare_line, "\r");

        _ = board.select(line[0..2], color) catch |err| switch (err) {
            error.InvalidInput => continue,
            error.InvalidColor => continue,
        };

        t += 1;
    }
}

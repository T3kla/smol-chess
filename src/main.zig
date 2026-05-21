const std = @import("std");
const chess = @import("chess.zig");
const Color = chess.Color;
const print = std.debug.print;

const ROWS = 21;
const COLS = 36;

pub fn main(init: std.process.Init) !void {
    var obuff: [1024]u8 = undefined;
    var writer = std.Io.File.stdout().writer(init.io, &obuff);
    const stdout = &writer.interface;

    var ibuff: [128]u8 = undefined;
    var reader = std.Io.File.stdin().reader(init.io, &ibuff);
    const stdin = &reader.interface;

    var board = chess.Board.init();

    var moves: u8 = 0;

    while (true) {
        const turn: Color = if (moves % 2 == 0) .white else .black;

        try stdout.print("\n{s:^36}\n", .{"Smol-Chess"});
        try board.printBoard(stdout);

        while (true) {
            try stdout.print("{s}s select -> ", .{if (moves % 2 == 0) "White" else "Black"});
            try stdout.flush();

            const bare_line = try stdin.takeDelimiter('\n') orelse continue;
            const line = std.mem.trim(u8, bare_line, "\r");

            if (line.len != 2) {
                try clearRows(stdout, 1);
                continue;
            }

            const pos = inputToPos(line[0..2]) catch {
                try clearRows(stdout, 1);
                continue;
            };

            board.select(turn, pos.r, pos.c) catch {
                try clearRows(stdout, 1);
                continue;
            };

            break;
        }

        try clearRows(stdout, ROWS);

        moves += 1;
    }
}

// \x1b[F    => cursor up
// \x1B[A    => cursor up, keeps column
// \x1b[nG   => cursor to col n
// \x1B[K    => wipe row

fn clearRows(stdout: *std.Io.Writer, n: usize) !void {
    try stdout.print("\x1B[K", .{});
    for (0..n) |_|
        try stdout.print("\x1B[A\x1B[K", .{});

    // try stdout.flush();
}

fn inputToPos(pos: *const [2]u8) !struct { r: i8, c: i8 } {
    if (pos[0] < 'a' or pos[0] > 'h') return error.InvalidInput;
    if (pos[1] < '1' or pos[1] > '8') return error.InvalidInput;
    const row: i8 = @intCast(7 - (pos[1] - '1'));
    const col: i8 = @intCast(pos[0] - 'a');
    return .{ .r = row, .c = col };
}

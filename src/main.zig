const std = @import("std");
const log = std.debug.print;

const Board = @import("board.zig");
const Piece = @import("piece.zig");

const ROWS = 21;
const COLS = 36;

pub fn main(init: std.process.Init) !void {
    var ibuff: [128]u8 = undefined;
    var reader = std.Io.File.stdin().reader(init.io, &ibuff);
    const stdin = &reader.interface;

    var board = Board.init();

    var moves: u8 = 0;

    while (true) {
        const turn: Piece.Color = if (moves % 2 == 0) .white else .black;

        log("\n{s:^36}\n", .{"Smol-Chess"});
        try board.print();

        while (true) {
            log("{s}s select -> ", .{if (moves % 2 == 0) "White" else "Black"});

            const bare_line = try stdin.takeDelimiter('\n') orelse continue;
            const line = std.mem.trim(u8, bare_line, "\r");

            if (line.len != 2) {
                try clearRows(1);
                continue;
            }

            const pos = inputToPos(line[0..2]) catch {
                try clearRows(1);
                continue;
            };

            board.select(turn, pos.r, pos.c) catch {
                try clearRows(1);
                continue;
            };

            break;
        }

        try clearRows(ROWS);

        moves += 1;
    }
}

// \x1b[F    => cursor up
// \x1B[A    => cursor up, keeps column
// \x1b[nG   => cursor to col n
// \x1B[K    => wipe row

fn clearRows(n: usize) !void {
    log("\x1B[K", .{});
    for (0..n) |_|
        log("\x1B[A\x1B[K", .{});
}

fn inputToPos(pos: *const [2]u8) !struct { r: i8, c: i8 } {
    if (pos[0] < 'a' or pos[0] > 'h') return error.InvalidInput;
    if (pos[1] < '1' or pos[1] > '8') return error.InvalidInput;
    const row: i8 = @intCast(7 - (pos[1] - '1'));
    const col: i8 = @intCast(pos[0] - 'a');
    return .{ .r = row, .c = col };
}

const std = @import("std");
const main = @import("main.zig");

pub const Piece = packed struct {
    pub const Selected = enum(u1) { y, n };
    pub const Color = enum(u1) { white, black };
    pub const Kind = enum(u6) { none, pawn, rook, knight, bishop, queen, king };

    selected: Selected = .y,
    color: Color = .white,
    kind: Kind = .none,

    pub fn init(s: Selected, c: Color, k: Kind) Piece {
        return .{ .selected = s, .color = c, .kind = k };
    }

    pub fn edit(self: *Piece, c: Color, k: Kind) void {
        self.color = c;
        self.kind = k;
    }

    pub fn select(self: *Piece, s: Selected) void {
        self.selected = s;
    }

    pub fn toString(self: Piece) []const u8 {
        return switch (self.color) {
            .white => switch (self.kind) {
                .rook => "♜",
                .knight => "♞",
                .bishop => "♝",
                .king => "♚",
                .queen => "♛",
                .pawn => "♟",
                .none => " ",
            },
            .black => switch (self.kind) {
                .rook => "♖",
                .knight => "♘",
                .bishop => "♗",
                .king => "♔",
                .queen => "♕",
                .pawn => "♙",
                .none => " ",
            },
        };
    }
};

pub const Board = struct {
    data: [8][8]Piece = undefined,

    pub fn init() Board {
        return Board{ .data = .{
            .{
                Piece{ .color = .black, .kind = .rook },
                Piece{ .color = .black, .kind = .knight },
                Piece{ .color = .black, .kind = .bishop },
                Piece{ .color = .black, .kind = .queen },
                Piece{ .color = .black, .kind = .king },
                Piece{ .color = .black, .kind = .knight },
                Piece{ .color = .black, .kind = .bishop },
                Piece{ .color = .black, .kind = .rook },
            },
            .{Piece{ .color = .black, .kind = .pawn }} ** 8,
            .{Piece{ .kind = .none }} ** 8,
            .{Piece{ .kind = .none }} ** 8,
            .{Piece{ .kind = .none }} ** 8,
            .{Piece{ .kind = .none }} ** 8,
            .{Piece{ .color = .white, .kind = .pawn }} ** 8,
            .{
                Piece{ .color = .white, .kind = .rook },
                Piece{ .color = .white, .kind = .knight },
                Piece{ .color = .white, .kind = .bishop },
                Piece{ .color = .white, .kind = .queen },
                Piece{ .color = .white, .kind = .king },
                Piece{ .color = .white, .kind = .knight },
                Piece{ .color = .white, .kind = .bishop },
                Piece{ .color = .white, .kind = .rook },
            },
        } };
    }

    pub fn reset(self: Board) void {
        self.data = init().data;
    }

    pub fn printBoard(self: Board, stdout: *std.Io.Writer) !void {
        const board_top = "╭───┬───┬───┬───┬───┬───┬───┬───╮\n";
        const board_mid = "├───┼───┼───┼───┼───┼───┼───┼───┤\n";
        const board_bot = "╰───┴───┴───┴───┴───┴───┴───┴───╯\n";

        for (0..16) |i| {
            switch (i) {
                0 => try stdout.print("{s}", .{board_top}),
                16 => try stdout.print("{s}", .{board_bot}),
                else => {
                    if (i % 2 == 0)
                        try stdout.print("{s}", .{board_mid})
                    else
                        try printLine(self, stdout, @intCast((i - 1) / 2));
                },
            }
        }

        try stdout.print("{s}", .{board_bot});
    }

    fn printLine(self: Board, stdout: *std.Io.Writer, l: u8) !void {
        for (0..8) |i|
            try stdout.print("│ {s} ", .{self.data[l][i].toString()});
        try stdout.print("│\n", .{});
    }
};

const dbglg = std.debug.print;

test "Piece struct size" {
    const size: u8 = @sizeOf(Piece);
    dbglg(" is {d} bytes! ", .{size});
    try std.testing.expect(size <= 1);
}

test "Piece toChar" {
    var p = Piece.init(.n, .black, .queen);
    try std.testing.expectEqualStrings(p.toString(), "♕");
    p.edit(.white, .knight);
    try std.testing.expectEqualStrings(p.toString(), "♞");
    p.edit(.black, .knight);
    try std.testing.expectEqualStrings(p.toString(), "♘");
}

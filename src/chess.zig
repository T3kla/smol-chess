const std = @import("std");
const main = @import("main.zig");

pub const Status = enum(u2) { none, selected, possibility };
pub const Color = enum(u1) { white, black };
pub const Kind = enum(u5) { none, pawn, rook, knight, bishop, queen, king };

pub const Piece = packed struct {
    status: Status = .none,
    color: Color = .white,
    kind: Kind = .none,

    pub fn init(s: Status, c: Color, k: Kind) Piece {
        return .{ .status = s, .color = c, .kind = k };
    }

    pub fn edit(self: *Piece, c: Color, k: Kind) void {
        self.color = c;
        self.kind = k;
    }

    pub fn select(self: *Piece, s: Status) void {
        self.status = s;
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

    const Error = error{
        InvalidInput,
        NotYourTurn,
        CantMove,
        Ilegal,
        SelectedNone,
    };

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

    pub fn get(self: *Board, r: i8, c: i8) ?*Piece {
        if (bounds(r, c))
            return &self.data[@intCast(r)][@intCast(c)]
        else
            return null;
    }

    pub fn reset(self: Board) void {
        self.data = init().data;
    }

    pub fn select(self: *Board, turn: Color, row: i8, col: i8) Error!void {
        var piece = self.get(row, col) orelse return Error.InvalidInput;

        if (piece.color != turn) return Error.NotYourTurn;

        switch (piece.kind) {
            .none => return Error.SelectedNone,
            .pawn => pawn(self, turn, row, col),
            .rook => {},
            .knight => knight(self, turn, row, col),
            .bishop => {},
            .queen => {},
            .king => {},
        }

        // only if it can move or eat it should be selected, else send an error
        // will have to check every piece

        piece.select(.selected);
    }

    fn knight(self: *Board, clr: Color, row: i8, col: i8) void {
        const moves = [_][2]i8{
            .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 },
            .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 },
        };

        for (moves) |i|
            if (self.get(row + i[0], col + i[1])) |p|
                if (p.kind == .none or p.kind != .none and p.color != clr)
                    p.select(.possibility);
    }

    fn pawn(self: *Board, clr: Color, row: i8, col: i8) void {
        const sense: i8 = if (clr == Color.white) -1 else 1;
        const r = row + sense;

        if (self.get(r, col)) |p| if (p.kind == Kind.none)
            p.select(.possibility);
        if (self.get(r, col + 1)) |p| if (p.kind != Kind.none and p.color != clr)
            p.select(.possibility);
        if (self.get(r, col - 1)) |p| if (p.kind != Kind.none and p.color != clr)
            p.select(.possibility);
    }

    fn bounds(r: i8, c: i8) bool {
        return r >= 0 and r <= 7 and c >= 0 and c <= 7;
    }

    pub fn printBoard(self: Board, stdout: *std.Io.Writer) !void {
        const board_top = "  ╭───┬───┬───┬───┬───┬───┬───┬───╮\n";
        const board_mid = "  ├───┼───┼───┼───┼───┼───┼───┼───┤\n";
        const board_bot = "  ╰───┴───┴───┴───┴───┴───┴───┴───╯\n";
        const board_ltr = "    a   b   c   d   e   f   g   h  \n";

        try stdout.print("{s}", .{board_top});
        inline for (0..7) |i| {
            try printLine(self, stdout, @intCast(2 * i + 1));
            try stdout.print("{s}", .{board_mid});
        }
        try printLine(self, stdout, @intCast(15));
        try stdout.print("{s}", .{board_bot});
        try stdout.print("{s}", .{board_ltr});
    }

    fn printLine(self: Board, stdout: *std.Io.Writer, line: u8) !void {
        const y: u8 = @intCast((line - 1) / 2);
        try stdout.print("{d} │", .{8 - y});
        for (0..8) |x| {
            try printPiece(stdout, self.data[y][x]);
            try stdout.print("│", .{});
        }
        try stdout.print("\n", .{});
    }

    fn printPiece(stdout: *std.Io.Writer, piece: Piece) !void {
        // \x1b[31m foreground color to red 37=white 30=black
        // \x1b[0m  reset terminal's defaults
        // example: try stdout.print(" \x1b[31m{s}\x1b[0m ", .{piece.toString()});

        switch (piece.status) {
            .none => try stdout.print(" {s} ", .{piece.toString()}),
            .selected => try stdout.print(" \x1b[31m{s}\x1b[0m ", .{piece.toString()}),
            .possibility => {
                if (piece.kind == Kind.none)
                    try stdout.print(" \x1b[32m✖\x1b[0m ", .{})
                else
                    try stdout.print(" \x1b[32m{s}\x1b[0m ", .{piece.toString()});
            },
        }
    }
};

test "Piece struct size" {
    const size: u8 = @sizeOf(Piece);
    try std.testing.expect(size <= 1);
}

test "Piece toChar" {
    var p = Piece.init(.none, .black, .queen);
    try std.testing.expectEqualStrings(p.toString(), "♕");
    p.edit(.white, .knight);
    try std.testing.expectEqualStrings(p.toString(), "♞");
    p.edit(.black, .knight);
    try std.testing.expectEqualStrings(p.toString(), "♘");
}

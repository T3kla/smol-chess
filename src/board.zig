const Self = @This();

const log = @import("std").debug.print;

const Writer = @import("std").Io.Writer;
const Piece = @import("piece.zig");

data: [8][8]Piece = undefined,

const moves_ortho = [4][7][2]i8{
    .{ .{ 1, 0 }, .{ 2, 0 }, .{ 3, 0 }, .{ 4, 0 }, .{ 5, 0 }, .{ 6, 0 }, .{ 7, 0 } },
    .{ .{ -1, 0 }, .{ -2, 0 }, .{ -3, 0 }, .{ -4, 0 }, .{ -5, 0 }, .{ -6, 0 }, .{ -7, 0 } },
    .{ .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 }, .{ 0, 4 }, .{ 0, 5 }, .{ 0, 6 }, .{ 0, 7 } },
    .{ .{ 0, -1 }, .{ 0, -2 }, .{ 0, -3 }, .{ 0, -4 }, .{ 0, -5 }, .{ 0, -6 }, .{ 0, -7 } },
};

const moves_diagonal = [4][7][2]i8{
    .{ .{ 1, 1 }, .{ 2, 2 }, .{ 3, 3 }, .{ 4, 4 }, .{ 5, 5 }, .{ 6, 6 }, .{ 7, 7 } },
    .{ .{ 1, -1 }, .{ 2, -2 }, .{ 3, -3 }, .{ 4, -4 }, .{ 5, -5 }, .{ 6, -6 }, .{ 7, -7 } },
    .{ .{ 1, 1 }, .{ 2, 2 }, .{ 3, 3 }, .{ 4, 4 }, .{ 5, 5 }, .{ 6, 6 }, .{ 7, 7 } },
    .{ .{ 1, 1 }, .{ 2, 2 }, .{ 3, 3 }, .{ 4, 4 }, .{ 5, 5 }, .{ 6, 6 }, .{ 7, 7 } },
};

const moves_knight = [8][2]i8{
    .{ 2, 1 }, .{ 2, -1 }, .{ -2, 1 }, .{ -2, -1 },
    .{ 1, 2 }, .{ 1, -2 }, .{ -1, 2 }, .{ -1, -2 },
};

const moves_king = [8][2]i8{
    .{ 0, 1 }, .{ 0, -1 }, .{ 1, 0 },  .{ -1, 0 },
    .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 },
};

const Error = error{
    InvalidInput,
    NotYourTurn,
    CantMove,
    Ilegal,
    SelectedNone,
};

pub fn init() Self {
    return Self{ .data = .{
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

fn get(self: *Self, r: i8, c: i8) ?*Piece {
    if (bounds(r, c))
        return &self.data[@intCast(r)][@intCast(c)]
    else
        return null;
}

fn reset(self: Self) void {
    self.data = init().data;
}

pub fn select(self: *Self, turn: Piece.Color, row: i8, col: i8) Error!void {
    var piece = self.get(row, col) orelse return Error.InvalidInput;

    if (piece.color != turn) return Error.NotYourTurn;

    switch (piece.kind) {
        .none => return Error.SelectedNone,
        .pawn => pawn(self, turn, row, col),
        .rook => rook(self, turn, row, col),
        .knight => knight(self, turn, row, col),
        .bishop => bishop(self, turn, row, col),
        .queen => queen(self, turn, row, col),
        .king => king(self, turn, row, col),
    }

    // only if it can move or eat it should be selected, else send an error
    // will have to check every piece

    piece.select(.selected);
}

fn pawn(self: *Self, clr: Piece.Color, row: i8, col: i8) void {
    const sense: i8 = if (clr == .white) -1 else 1;
    const r = row + sense;

    if (self.get(r, col)) |p| if (p.kind == .none)
        p.select(.possibility);
    if (self.get(r, col + 1)) |p| if (p.kind != .none and p.color != clr)
        p.select(.possibility);
    if (self.get(r, col - 1)) |p| if (p.kind != .none and p.color != clr)
        p.select(.possibility);
}

fn rook(self: *Self, clr: Piece.Color, row: i8, col: i8) void {
    inline for (moves_ortho) |dir| for (dir) |i|
        if (self.get(row + i[0], col + i[1])) |p| {
            if (p.kind == .none) {
                p.select(.possibility);
                continue;
            } else if (p.color != clr)
                p.select(.possibility);
            break;
        };
}

fn knight(self: *Self, clr: Piece.Color, row: i8, col: i8) void {
    inline for (moves_knight) |i|
        if (self.get(row + i[0], col + i[1])) |p|
            if (p.kind == .none or p.kind != .none and p.color != clr)
                p.select(.possibility);
}

fn bishop(self: *Self, clr: Piece.Color, row: i8, col: i8) void {
    inline for (moves_diagonal) |dir| for (dir) |i|
        if (self.get(row + i[0], col + i[1])) |p| {
            if (p.kind == .none) {
                p.select(.possibility);
                continue;
            } else if (p.color != clr)
                p.select(.possibility);
            break;
        };
}

fn queen(self: *Self, clr: Piece.Color, row: i8, col: i8) void {
    inline for (moves_ortho ++ moves_diagonal) |dir| for (dir) |i|
        if (self.get(row + i[0], col + i[1])) |p| {
            if (p.kind == .none) {
                p.select(.possibility);
                continue;
            } else if (p.color != clr)
                p.select(.possibility);
            break;
        };
}

fn king(self: *Self, clr: Piece.Color, row: i8, col: i8) void {
    inline for (moves_king) |i|
        if (self.get(row + i[0], col + i[1])) |p|
            if (p.kind == .none or p.kind != .none and p.color != clr)
                p.select(.possibility);
}

fn bounds(r: i8, c: i8) bool {
    return r >= 0 and r <= 7 and c >= 0 and c <= 7;
}

pub fn print(self: Self) !void {
    const board_top = "  ╭───┬───┬───┬───┬───┬───┬───┬───╮\n";
    const board_mid = "  ├───┼───┼───┼───┼───┼───┼───┼───┤\n";
    const board_bot = "  ╰───┴───┴───┴───┴───┴───┴───┴───╯\n";
    const board_ltr = "    a   b   c   d   e   f   g   h  \n";

    log("{s}", .{board_top});
    inline for (0..7) |i| {
        try printLine(self, @intCast(2 * i + 1));
        log("{s}", .{board_mid});
    }
    try printLine(self, @intCast(15));
    log("{s}", .{board_bot});
    log("{s}", .{board_ltr});
}

fn printLine(self: Self, line: u8) !void {
    const y: u8 = @intCast((line - 1) / 2);
    log("{d} │", .{8 - y});
    for (0..8) |x| {
        try printPiece(self.data[y][x]);
        log("│", .{});
    }
    log("\n", .{});
}

fn printPiece(piece: Piece) !void {
    // \x1b[31m foreground color to red 37=white 30=black
    // \x1b[0m  reset terminal's defaults
    // example: try stdout.print(" \x1b[31m{s}\x1b[0m ", .{piece.toString()});

    switch (piece.status) {
        .none => log(" {s} ", .{piece.toString()}),
        .selected => log(" \x1b[31m{s}\x1b[0m ", .{piece.toString()}),
        .possibility => {
            if (piece.kind == .none)
                log(" \x1b[32m·\x1b[0m ", .{})
            else
                log(" \x1b[32m{s}\x1b[0m ", .{piece.toString()});
        },
    }
}

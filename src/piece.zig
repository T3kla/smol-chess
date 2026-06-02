const Self = @This();

status: Status = .none,
color: Color = .white,
kind: Kind = .none,

pub const Status = enum(u2) { none, selected, possibility };
pub const Color = enum(u1) { white, black };
pub const Kind = enum(u5) { none, pawn, rook, knight, bishop, queen, king };

pub fn init(s: Status, c: Color, k: Kind) Self {
    return .{ .status = s, .color = c, .kind = k };
}

pub fn edit(self: *Self, c: Color, k: Kind) void {
    self.color = c;
    self.kind = k;
}

pub fn select(self: *Self, s: Status) void {
    self.status = s;
}

pub fn toString(self: Self) []const u8 {
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

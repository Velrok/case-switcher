const CaseMode = enum {
    TitleCase,
    CamelCase,
    SnakeCase,
    KebabCase,
    ConstCase,
};

pub fn main() !void {
    // read a word from std in
    // have a list of case transformers:

    // TitleCase
    // camelCase
    // snake_case
    // kebab-case
    // CONST_CASE

    var arena = std.heap.ArenaAllocator.init(
        std.heap.page_allocator,
    );
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdin_reader = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;
    const line = try stdin_reader.readUntilDelimiter(&buffer, '\n');

    print("line: {s}\n", .{line});
    const mode = identifyCase(line);
    print("mode: {any}\n", .{mode});
    var words = switch (mode) {
        .SnakeCase, .ConstCase => std.mem.splitScalar(u8, line, '_'),
        .KebabCase => std.mem.splitScalar(u8, line, '-'),

        .TitleCase => std.debug.panic("not supported yet", .{}),
        .CamelCase => std.debug.panic("not supported yet", .{}),
    };

    var lowercaseWords = std.ArrayList([]u8).init(allocator);

    while (words.next()) |word| {
        try lowercaseWords.append(try std.ascii.allocLowerString(allocator, word));
    }

    for (lowercaseWords.items) |lowercaseWord| {
        print("lowercaseWord: {s}\n", .{lowercaseWord});
    }
}

}

fn identifyCase(word: []const u8) CaseMode {
    const indexOfScalar = std.mem.indexOfScalar;
    if (indexOfScalar(u8, word, '_') != null) {
        if (std.ascii.isLower(word[0])) {
            return .SnakeCase;
        } else {
            return .ConstCase;
        }
    } else if (indexOfScalar(u8, word, '-') != null) {
        return .KebabCase;
    } else {
        // TitleCase
        // camelCase
        if (std.ascii.isLower(word[0])) {
            return .CamelCase;
        } else {
            return .TitleCase;
        }
    }
    std.debug.panic("reached end of identify case without result for {any}", .{word});
}

test "identifyCase recognises kebab-case" {
    const result = identifyCase("kebab-case");
    try testing.expectEqual(CaseMode.KebabCase, result);
}

test "identifyCase recognises snake_case" {
    const result = identifyCase("snake_case");
    try testing.expectEqual(CaseMode.SnakeCase, result);
}

test "identifyCase recognises CONST_CASE" {
    const result = identifyCase("CONST_CASE");
    try testing.expectEqual(CaseMode.ConstCase, result);
}
test "identifyCase recognises camelCase" {
    const result = identifyCase("camelCase");
    try testing.expectEqual(CaseMode.CamelCase, result);
}

test "identifyCase recognises TitleCase" {
    const result = identifyCase("TitleCase");
    try testing.expectEqual(CaseMode.TitleCase, result);
}

test "identifyCase recognises single lowercase word as camelCase" {
    const result = identifyCase("word");
    try testing.expectEqual(CaseMode.CamelCase, result);
}

test "identifyCase recognises single titlecase word as TitleCase" {
    const result = identifyCase("Word");
    try testing.expectEqual(CaseMode.TitleCase, result);
}

const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("case_switcher_lib");

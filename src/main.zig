const CaseMode = enum {
    TitleCase,
    CamelCase,
    SnakeCase,
    KebabCase,
    ConstCase,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdin_reader = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;
    const line = try stdin_reader.readUntilDelimiter(&buffer, '\n');

    const result = try switcher(allocator, line);
    print("{s}\n", .{result});
}

fn switcher(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const mode = identifyCase(line);
    var words = try splitLine(allocator, mode, line);
    defer words.deinit();

    var lowercaseWords = std.ArrayList([]u8).init(allocator);
    defer {
        for (lowercaseWords.items) |word| {
            allocator.free(word);
        }
        lowercaseWords.deinit();
    }

    for (words.items) |word| {
        try lowercaseWords.append(try std.ascii.allocLowerString(allocator, word));
    }

    const targetMode = nextMode(mode);
    return try convertToCase(allocator, lowercaseWords.items, targetMode);
}

fn splitLine(allocator: std.mem.Allocator, mode: CaseMode, line: []const u8) !std.ArrayList([]const u8) {
    var result = std.ArrayList([]const u8).init(allocator);

    switch (mode) {
        .SnakeCase, .ConstCase => {
            var words = std.mem.splitAny(u8, line, "_");
            while (words.next()) |word| {
                try result.append(word);
            }
        },
        .KebabCase => {
            var words = std.mem.splitAny(u8, line, "-");
            while (words.next()) |word| {
                try result.append(word);
            }
        },
        .TitleCase, .CamelCase => {
            if (line.len == 0) {
                try result.append("");
                return result;
            }

            var start: usize = 0;
            for (line, 0..) |char, i| {
                if (i > 0 and std.ascii.isUpper(char)) {
                    try result.append(line[start..i]);
                    start = i;
                }
            }
            // Add the last word
            if (start < line.len) {
                try result.append(line[start..]);
            }
        },
    }
    return result;
}
test "splitLine function" {
    const allocator = std.testing.allocator;

    // Test SnakeCase
    var snake_words = try splitLine(allocator, .SnakeCase, "hello_world_zig");
    defer snake_words.deinit();
    try std.testing.expect(snake_words.items.len == 3);
    try std.testing.expectEqualStrings("hello", snake_words.items[0]);
    try std.testing.expectEqualStrings("world", snake_words.items[1]);
    try std.testing.expectEqualStrings("zig", snake_words.items[2]);

    // Test ConstCase
    var const_words = try splitLine(allocator, .ConstCase, "HELLO_WORLD_ZIG");
    defer const_words.deinit();
    try std.testing.expect(const_words.items.len == 3);
    try std.testing.expectEqualStrings("HELLO", const_words.items[0]);
    try std.testing.expectEqualStrings("WORLD", const_words.items[1]);
    try std.testing.expectEqualStrings("ZIG", const_words.items[2]);

    // Test KebabCase
    var kebab_words = try splitLine(allocator, .KebabCase, "hello-world-zig");
    defer kebab_words.deinit();
    try std.testing.expect(kebab_words.items.len == 3);
    try std.testing.expectEqualStrings("hello", kebab_words.items[0]);
    try std.testing.expectEqualStrings("world", kebab_words.items[1]);
    try std.testing.expectEqualStrings("zig", kebab_words.items[2]);

    // Test TitleCase
    var title_words = try splitLine(allocator, .TitleCase, "HelloWorldAgain");
    defer title_words.deinit();
    try std.testing.expect(title_words.items.len == 3);
    try std.testing.expectEqualStrings("Hello", title_words.items[0]);
    try std.testing.expectEqualStrings("World", title_words.items[1]);
    try std.testing.expectEqualStrings("Again", title_words.items[2]);

    // Test CamelCase
    var camel_words = try splitLine(allocator, .CamelCase, "helloWorldAgain");
    defer camel_words.deinit();
    try std.testing.expect(camel_words.items.len == 3);
    try std.testing.expectEqualStrings("hello", camel_words.items[0]);
    try std.testing.expectEqualStrings("World", camel_words.items[1]);
    try std.testing.expectEqualStrings("Again", camel_words.items[2]);

    // Test empty input
    var empty_words = try splitLine(allocator, .SnakeCase, "");
    defer empty_words.deinit();
    try std.testing.expect(empty_words.items.len == 1);
    try std.testing.expectEqualStrings("", empty_words.items[0]);

    // Test input with no delimiters
    var no_delim_words = try splitLine(allocator, .SnakeCase, "helloworld");
    defer no_delim_words.deinit();
    try std.testing.expect(no_delim_words.items.len == 1);
    try std.testing.expectEqualStrings("helloworld", no_delim_words.items[0]);

    // Test single word TitleCase
    var single_title = try splitLine(allocator, .TitleCase, "Hello");
    defer single_title.deinit();
    try std.testing.expect(single_title.items.len == 1);
    try std.testing.expectEqualStrings("Hello", single_title.items[0]);

    // Test single word camelCase
    var single_camel = try splitLine(allocator, .CamelCase, "hello");
    defer single_camel.deinit();
    try std.testing.expect(single_camel.items.len == 1);
    try std.testing.expectEqualStrings("hello", single_camel.items[0]);
}

fn nextMode(mode: CaseMode) CaseMode {
    return switch (mode) {
        .TitleCase => .CamelCase,
        .CamelCase => .SnakeCase,
        .SnakeCase => .KebabCase,
        .KebabCase => .ConstCase,
        .ConstCase => .TitleCase,
    };
}

fn convertToCase(allocator: std.mem.Allocator, words: [][]u8, targetMode: CaseMode) ![]u8 {
    if (words.len == 0) return try allocator.dupe(u8, "");

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    switch (targetMode) {
        .TitleCase => {
            for (words) |word| {
                if (word.len > 0) {
                    try result.append(std.ascii.toUpper(word[0]));
                    if (word.len > 1) {
                        try result.appendSlice(word[1..]);
                    }
                }
            }
        },
        .CamelCase => {
            for (words, 0..) |word, i| {
                if (word.len > 0) {
                    if (i == 0) {
                        // First word stays lowercase
                        try result.appendSlice(word);
                    } else {
                        // Subsequent words are title cased
                        try result.append(std.ascii.toUpper(word[0]));
                        if (word.len > 1) {
                            try result.appendSlice(word[1..]);
                        }
                    }
                }
            }
        },
        .SnakeCase => {
            for (words, 0..) |word, i| {
                if (i > 0) try result.append('_');
                try result.appendSlice(word);
            }
        },
        .KebabCase => {
            for (words, 0..) |word, i| {
                if (i > 0) try result.append('-');
                try result.appendSlice(word);
            }
        },
        .ConstCase => {
            for (words, 0..) |word, i| {
                if (i > 0) try result.append('_');
                for (word) |char| {
                    try result.append(std.ascii.toUpper(char));
                }
            }
        },
    }

    return try result.toOwnedSlice();
}

fn identifyCase(word: []const u8) CaseMode {
    if (word.len == 0) return .CamelCase; // Default for empty strings

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

test "switcher function converts between case formats" {
    const allocator = std.testing.allocator;

    // TitleCase -> CamelCase
    {
        const result = try switcher(allocator, "HelloWorld");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("helloWorld", result);
    }

    // CamelCase -> SnakeCase
    {
        const result = try switcher(allocator, "helloWorld");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello_world", result);
    }

    // SnakeCase -> KebabCase
    {
        const result = try switcher(allocator, "hello_world");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello-world", result);
    }

    // KebabCase -> ConstCase
    {
        const result = try switcher(allocator, "hello-world");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("HELLO_WORLD", result);
    }

    // ConstCase -> TitleCase
    {
        const result = try switcher(allocator, "HELLO_WORLD");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("HelloWorld", result);
    }

    // Single words
    {
        const result = try switcher(allocator, "hello");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("hello", result); // camelCase -> snake_case, but single word
    }

    // Empty string
    {
        const result = try switcher(allocator, "");
        defer allocator.free(result);
        try std.testing.expectEqualStrings("", result);
    }
}

const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("case_switcher_lib");

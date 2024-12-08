const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = gpa.allocator();
    const arena_alloc = arena.allocator();

    // Open file
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    // Read to buffer
    const stat = try file.stat(); // Get file stats (mostly size)
    const content = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(content);

    // Split lines
    var lines = std.mem.splitSequence(u8, content, "\n");
    var safeCount: i32 = 0; // Counter of safe lines
    var safeCountDamp: i32 = 0; // Counter of safe lines when applying damper
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parsedNum = std.mem.splitSequence(u8, line, " ");
        var numbers = std.ArrayList(i32).init(arena_alloc);
        while (parsedNum.next()) |num| {
            try numbers.append(try std.fmt.parseInt(i32, num, 10));
        }
        if (isSafe(numbers.items)) safeCount += 1;
        if (try isSafeDamped(std.heap.page_allocator, numbers.items)) safeCountDamp += 1;
    }
    std.debug.print("Safe count: {d}\n", .{safeCount});
    std.debug.print("Safe count damped: {d}\n", .{safeCountDamp});
}

fn isSafe(list: []const i32) bool {
    // Conditions for safe report:
    // All numbers increasing or all numbers decreasing
    // Distance between numbers between 1 and 3
    var increasing: bool = false;
    var decreasing: bool = false;
    var distNum: i32 = 0;
    var prevNum: i32 = 0;
    for (list, 0..) |num, i| {
        if (i == 0) {
            prevNum = num;
            continue;
        }
        distNum = num - prevNum;
        // Check distance between number is in range
        if ((@abs(distNum) >= 1) and (@abs(distNum) <= 3)) {
            if (distNum > 0 and !increasing) increasing = true;
            if (distNum < 0 and !decreasing) decreasing = true;
        } else {
            return false; // Distance out of bounds
        }
        prevNum = num;
    }
    if (increasing == decreasing) return false;
    return true;
}

// PART 2
fn isSafeDamped(allocator: std.mem.Allocator, list: []const i32) !bool {
    // Conditions for safe report:
    // All numbers increasing or all numbers decreasing
    // Distance between numbers between 1 and 3
    // Dampened version: 1 wrong level can be tolerated
    // Create new lists removing each element and test the solution, if any of them is valid, report as safe
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    for (list, 0..) |_, i| {
        var tempList = std.ArrayList(i32).init(arena_alloc);
        if (i == 0) {
            try tempList.appendSlice(list[1..]);
        } else if (i == list.len - 1) {
            try tempList.appendSlice(list[0 .. list.len - 1]);
        } else {
            try tempList.appendSlice(list[0..i]);
            try tempList.appendSlice(list[(i + 1)..]);
        }
        if (isSafe(tempList.items)) { // Report as safe when single safe combination is found
            return true;
        }
    }
    return false;
}

// Used for debug
fn printList(list: []const i32) void {
    for (list) |val| {
        std.debug.print("{d} ", .{val});
    }
    std.debug.print("\n", .{});
}

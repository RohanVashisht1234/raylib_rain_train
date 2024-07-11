const std = @import("std");
const rl = @import("raylib");

const screenWidth: u11 = 1080;
const screenHeight: u11 = 720;

// Define the rules of the game
const _rules = struct {
    stop_at_next_station: bool,
    iteration: u8,
    crossed_the_station: bool,
    failed: bool,
    score: i32,
    honked: bool,
    show_instructions: bool,
};

pub fn main() void {
    var rules = _rules{
        .stop_at_next_station = false,
        .iteration = 0,
        .failed = false,
        .crossed_the_station = false,
        .score = 0,
        .honked = false,
        .show_instructions = true,
    };
    // Initialize Audio
    rl.initAudioDevice();
    const bgMusic: rl.Music = rl.loadMusicStream("./music/rn.mp3");
    rl.playMusicStream(bgMusic);

    const trainMusic: rl.Music = rl.loadMusicStream("./music/train.mp3");
    rl.playMusicStream(trainMusic);
    rl.setMusicVolume(trainMusic, 2);

    const horn: rl.Music = rl.loadMusicStream("./music/horn.mp3");
    rl.playMusicStream(horn);

    // Initialize Window
    rl.initWindow(screenWidth, screenHeight, "3d camera first person rain");
    defer rl.closeWindow();

    // Create First person Camera
    var camera = rl.Camera3D{
        .position = rl.Vector3.init(-20, 3, 4),
        .target = rl.Vector3.init(-20, -1.8, -1000000),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 60.0,
        .projection = rl.CameraProjection.camera_perspective,
    };

    rl.disableCursor();
    rl.setTargetFPS(60);

    // The Average height of each raindrop
    const mine = rl.loadModel("./assets/train.glb");
    const terrain = rl.loadModel("./assets/terrain.glb");
    const tree = rl.loadModel("./assets/tree.glb");
    const track = rl.loadModel("./assets/track.glb");
    const train_station = rl.loadModel("./assets/train_station.glb");
    defer rl.unloadModel(mine);
    defer rl.unloadModel(tree);
    defer rl.unloadModel(track);
    defer rl.unloadModel(terrain);
    defer rl.unloadModel(train_station);
    var speed: f32 = 0;
    var raindropAvgHeight: i32 = 5;
    // Game main loop
    while (!rl.windowShouldClose()) {
        rl.updateMusicStream(bgMusic);

        // Update raindrop height
        {
            raindropAvgHeight -= 1;
            if (raindropAvgHeight < 0) {
                raindropAvgHeight = 5;
            }
        }

        camera.update(rl.CameraMode.camera_custom);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.gray);

        // Draw actual game
        {
            camera.begin();
            defer camera.end();
            rl.drawModel(
                mine,
                rl.Vector3.init(camera.position.x, 3.5, camera.position.z + 1),
                0.1,
                rl.Color.red,
            );
            // var x: f32 = -4;
            // while (x < 4) : (x += 1) {
            //     var z: f32 = -1;
            //     while (z < 100) : (z += 1) {
            //         rl.drawModel(tree, rl.Vector3.init(x * 40, 12, -z * 50), 0.3, rl.Color.dark_green);
            //         rl.drawModel(train_station, rl.Vector3.init(-30, 2, -z * 2000), 0.3, rl.Color.gray);
            //     }
            // }

            var x: f32 = -4;
            while (x < 4) : (x += 1) {
                var z: f32 = -1;
                while (z < 100) : (z += 1) {
                    rl.drawModel(tree, rl.Vector3.init(x * 40, 12, -z * 40), 0.3, rl.Color.dark_green);
                }
            }
            rl.drawModel(train_station, rl.Vector3.init(-30, 2, 0), 0.3, rl.Color.gray);
            rl.drawModel(train_station, rl.Vector3.init(-30, 2, -2000), 0.3, rl.Color.gray);

            var i: f32 = 0;
            while (i < 500) : (i += 1) {
                rl.drawModel(track, rl.Vector3.init(-20, 3.5, -i * 20), 0.2, rl.Color.gray);
            }

            camera.position.z -= speed;
            if (speed > 0) {
                speed -= 0.001;
                rl.updateMusicStream(trainMusic);
                if (speed < 1) {
                    rl.setMusicPitch(trainMusic, speed);
                }
                // trainMusic.looping = true;
            }

            if (rl.isKeyDown(rl.KeyboardKey.key_h)) {
                rl.updateMusicStream(horn);
            }
            if (rl.isKeyReleased(rl.KeyboardKey.key_h)) {
                rl.seekMusicStream(horn, 0);
            }

            if (rl.isKeyDown(rl.KeyboardKey.key_w) and speed < 5.1) {
                speed += 0.005;
            }

            if (rl.isKeyDown(rl.KeyboardKey.key_b)) {
                if (speed > 0) {
                    speed -= 0.04;
                }
            }

            if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
                speed -= 0.005;
            }
            // std.debug.print("{}\n", .{camera.position.z});

            //bring train back to 0
            if (camera.position.z < -2000) {
                camera.position.z = 0;
                rules.iteration += 1;
            }

            var f: i8 = -10;
            while (f < 10) : (f += 1) {
                var g: i8 = -10;
                while (g < 10) : (g += 1) {
                    rl.drawCube(
                        rl.Vector3.init(
                            camera.position.x + @as(f32, @floatFromInt(f + rl.getRandomValue(1, 2))),
                            @as(f16, @floatFromInt(raindropAvgHeight + rl.getRandomValue(0, 3))),
                            camera.position.z + @as(f16, @floatFromInt(g + rl.getRandomValue(0, 2))),
                        ),
                        0.01,
                        0.2,
                        0.01,
                        rl.Color.blue,
                    );
                }
            }

            // Draw ground
            rl.drawCube(rl.Vector3.init(0.0, 0, 0.0), 500, 0.01, 100000, rl.Color.dark_brown);

            // Draw a blue wall for understansing where you are going.
            rl.drawCube(rl.Vector3.init(16.0, -0.4, 0.0), 1.0, 10, 50.0, rl.Color.dark_blue);
        }
        // Text instructions screen
        {
            if (rules.show_instructions) {
                rl.drawRectangle(10, 10, 250, 110, rl.Color.sky_blue.fade(0.5));
                rl.drawRectangleLines(10, 10, 250, 110, rl.Color.blue);
                rl.drawText("Train controls:", 20, 20, 10, rl.Color.black);
                rl.drawText("- Go forward: W, Go back : S", 40, 40, 10, rl.Color.dark_gray);
                rl.drawText("- Press H to Honk, Press B for breaks", 40, 60, 10, rl.Color.dark_gray);
                rl.drawText("- Honk at stations to increase score", 40, 80, 10, rl.Color.dark_gray);
                rl.drawText("- Press I to hide these instructions", 40, 100, 10, rl.Color.dark_gray);
            }
            if (rl.isKeyPressed(rl.KeyboardKey.key_i)) {
                if (rules.show_instructions) {
                    rules.show_instructions = false;
                } else {
                    rules.show_instructions = true;
                }
            }
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and speed > 5) {
                rl.drawText("Max Speed", screenWidth / 2 - 100, screenHeight / 2 - 100, 20, rl.Color.red);
            }
            if (camera.position.z < -12 and camera.position.z > -20) {
                rules.crossed_the_station = true;
            } else {
                rules.crossed_the_station = false;
            }
            if (rules.iteration == 4) {
                rules.iteration = 0;
            }
            if (rules.iteration != 0 and @rem(rules.iteration, 2) == 0 and rules.crossed_the_station) {
                rules.stop_at_next_station = true; // after 1 station
                rules.crossed_the_station = false;
            }
            if (rules.stop_at_next_station and camera.position.z > -1980 and speed <= 0) {
                rules.stop_at_next_station = false; // after 1 station
                rules.iteration = 0;
                // WIN
            }
            if (rl.isKeyDown(rl.KeyboardKey.key_h) and camera.position.z > -1980 and !rules.honked) {
                rules.honked = true;
                rules.score += 100;
            }
            if (rules.stop_at_next_station and rules.crossed_the_station) {
                rules.failed = true;
            }
            if (rules.crossed_the_station) {
                rules.honked = false;
            }
            if (rules.failed) {
                rl.drawRectangle(0, 0, screenWidth, screenHeight, rl.Color.dark_gray.fade(0.5));
                rl.drawRectangleLines(10, 10, 250, 70, rl.Color.dark_gray);
                rl.drawText("Failed", screenWidth / 2 - 150, screenHeight / 2 - 100, 200, rl.Color.red);
            }
            if (rules.stop_at_next_station) {
                rl.drawText("Stop at next station", screenWidth / 2 - 50, screenHeight / 2 - 50, 50, rl.Color.red);
            }
            {
                const fmt = "Your score: {d}";
                const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
                var buf: [len:0]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, fmt, .{rules.score}) catch unreachable;
                rl.drawText(text, screenWidth - 220, 10, 20, rl.Color.black);
            }
            {
                const fmt = "Your speed: {d} M/h";
                const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
                var buf: [len:0]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, fmt, .{@as(i32, @intFromFloat(speed * 2 * 10))}) catch unreachable;
                rl.drawText(text, screenWidth - 220, 30, 20, rl.Color.black);
            }

            if (camera.position.z > 0) {
                camera.position.z = -0.1;
                speed = 0;
                rl.drawText("Wrong Direction", screenWidth / 2 - 100, screenHeight / 2 - 100, 20, rl.Color.red);
            }
        }
    }
}

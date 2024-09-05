const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");

pub fn main() void {
    // ----------- Set rules -------------
    var rules = constants._rules{
        .stop_at_next_station = false,
        .iteration = 0,
        .failed = false,
        .within_station_boundary = false,
        .score = 0,
        .honked = false,
        .show_instructions = true,
    };

    // ------------------ Initialize Audio ---------------------
    rl.initAudioDevice();

    const rainMusic = rl.loadMusicStream("./music/rn.mp3");
    rl.playMusicStream(rainMusic);
    defer rl.unloadMusicStream(rainMusic);

    const lightning = rl.loadSound("./music/lightning.mp3");
    defer rl.unloadSound(lightning);

    const trainMusic = rl.loadMusicStream("./music/train.mp3");
    rl.playMusicStream(trainMusic);
    rl.setMusicVolume(trainMusic, 2);
    defer rl.unloadMusicStream(trainMusic);

    const horn: rl.Music = rl.loadMusicStream("./music/horn.mp3");
    rl.playMusicStream(horn);
    defer rl.unloadMusicStream(horn);

    // ----------- Initialize Window -------------
    rl.initWindow(constants.screenWidth, constants.screenHeight, "3d camera first person rain");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // -------------------- Create First person Camera ------------------------
    var camera = rl.Camera3D{
        .position = rl.Vector3.init(20, 4, 4),
        .target = rl.Vector3.init(20, -1.8, 10000000),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 60.0,
        .projection = rl.CameraProjection.camera_perspective,
    };
    var camera2 = rl.Camera3D{
        .position = rl.Vector3.init(5, 20, camera.position.z),
        .target = rl.Vector3.init(camera.position.x, camera.position.y, camera.position.z + 10),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 60.0,
        .projection = rl.CameraProjection.camera_perspective,
    };

    // -------------- Load and Store 3D Models ------------------
    const red_signal = rl.loadModel("./assets/red_signal.glb");
    defer rl.unloadModel(red_signal);
    const green_signal = rl.loadModel("./assets/green_signal.glb");
    defer rl.unloadModel(green_signal);
    const terrain = rl.loadModel("./assets/terrain.glb");
    defer rl.unloadModel(terrain);
    const tree = rl.loadModel("./assets/tree.glb");
    defer rl.unloadModel(tree);
    const track = rl.loadModel("./assets/track.glb");
    defer rl.unloadModel(track);
    const train = rl.loadModel("./assets/train.glb");
    defer rl.unloadModel(train);
    const train_station = rl.loadModel("./assets/train_station.glb");
    defer rl.unloadModel(train_station);
    const sign = rl.loadModel("./assets/sign.glb");
    defer rl.unloadModel(train_station);
    const electricity = rl.loadModel("./assets/electricity.glb");
    defer rl.unloadModel(electricity);
    const electricity_r = rl.loadModel("./assets/electricity_r.glb");
    defer rl.unloadModel(electricity_r);
    const track_bent = rl.loadModel("./assets/track_bent.glb");
    defer rl.unloadModel(track_bent);
    const track_bent_r = rl.loadModel("./assets/track_bent_r.glb");
    defer rl.unloadModel(track_bent_r);
    const mountains = rl.loadModel("./assets/mountains.glb");
    defer rl.unloadModel(mountains);
    var dummy_train = rl.Vector3.init(9.7, 1.5, 200);
    var protagonist_train = rl.Vector3.init(20, 1.5, 10);

    // -------- Important mutable variables -------------
    var speed: f32 = 0;
    var which_camera:i32 = 0;
    var raindropAvgHeight: i32 = 5;

    // =-=-=-=-= Game Loop =-=-=-=-=-=
    while (!rl.windowShouldClose()) {
        // Normal updates
        {
            // camera.update(rl.CameraMode.camera_custom);
            camera2.update(rl.CameraMode.camera_custom);
            camera.update(rl.CameraMode.camera_custom);
            rl.beginDrawing();
            defer rl.endDrawing();
        }

        // Every time result is 30, do a lightning, with lightning effects.
        {
            if (rl.getRandomValue(0, 600) == 30) {
                rl.clearBackground(rl.Color.white);
                rl.playSound(lightning);
            } else {
                rl.clearBackground(rl.Color.gray);
            }
        }

        // Draw actual game
        {
            // Camera config
            camera2.begin();
            defer camera2.end();
            camera.begin();
            defer camera2.end();
            if(which_camera == 0){
                rl.beginMode3D(camera2);
            } else {
                rl.beginMode3D(camera);
            }
            defer rl.endMode3D();
            camera2.position.z = camera.position.z + 50;
            camera2.target = camera.position;

            // Camera's position should increase due to speed.

            camera.position.z += speed;

            if (speed > 0) {
                speed -= 0.001;
                rl.updateMusicStream(trainMusic);
                if (speed < 1) {
                    rl.setMusicPitch(trainMusic, speed);
                }
                // trainMusic.looping = true;
            }

            // Play horn
            if (rl.isKeyDown(rl.KeyboardKey.key_h)) {
                rl.updateMusicStream(horn);
            }
            if(rl.isKeyPressed(rl.KeyboardKey.key_c)){
                if(which_camera == 0){
                    which_camera = 1;
                } else {
                    which_camera = 0;
                }
            }

            // reset playing horn
            if (rl.isKeyReleased(rl.KeyboardKey.key_h)) {
                rl.seekMusicStream(horn, 0);
            }

            // Increase speed
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and speed < 5.1) {
                speed += 0.005;
            }

            // Breaks
            if (rl.isKeyDown(rl.KeyboardKey.key_b)) {
                if (speed > 0) {
                    speed -= 0.02;
                }
            }

            if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
                speed -= 0.005;
            }
            // std.debug.print("{}\n", .{camera.position.z});

            // bring train back to 0
            if (camera.position.z > 2000) {
                camera.position.z = 0;
                rules.iteration += 1;
            }

            // ------- Rain related updates --------
            {
                // Update Rain height
                raindropAvgHeight -= 1;
                if (raindropAvgHeight < 0) {
                    raindropAvgHeight = 5;
                }
                // Create rain
                var rain_x: i8 = -10;
                while (rain_x < 10) : (rain_x += 1) {
                    var rain_y: i8 = -10;
                    while (rain_y < 10) : (rain_y += 1) {
                        rl.drawCube(
                            rl.Vector3.init(
                                camera.position.x + 0.5 + @as(f16, @floatFromInt(rain_x + rl.getRandomValue(1, 2))),
                                @as(f16, @floatFromInt(raindropAvgHeight + rl.getRandomValue(0, 3))),
                                camera.position.z + @as(f16, @floatFromInt(rain_y + rl.getRandomValue(0, 2))),
                            ),
                            0.01,
                            0.2,
                            0.01,
                            rl.Color.blue,
                        );
                    }
                }
                // Update rain music
                rl.updateMusicStream(rainMusic);
            }
            var x: f32 = -5;
            while (x < 4) : (x += 1) {
                var z: f32 = -20;
                if(x == 0 or x == 1){
                    continue;
                }
                while (z < 100) : (z += 1) {
                    rl.drawModel(tree, rl.Vector3.init(x * 20, 12, z * 40), 0.3, rl.Color.brown);
                }
            }
            {
                var z: f32 = -30;
                while (z < 40) : (z += 1) {
                    rl.drawModel(mountains, rl.Vector3.init(-300, 30, z * 200), 2, rl.Color.light_gray);
                    rl.drawModel(mountains, rl.Vector3.init(150, 30, z * 200), 2, rl.Color.light_gray);
                }
            }

            var i: f32 = -50;
            while (i < 500) : (i += 1) {
                rl.drawModel(track, rl.Vector3.init(20, 1.5, i * 17), 0.15, rl.Color.dark_gray);
                rl.drawModel(track, rl.Vector3.init(10, 1.5, i * 17), 0.15, rl.Color.dark_gray);
            }
            protagonist_train.x = camera.position.x;
            protagonist_train.z = camera.position.z - 30;
            rl.drawModel(train, dummy_train, 0.052, rl.Color.gray);
            rl.drawModel(train, protagonist_train, 0.052, rl.Color.gray);
            if(dummy_train.z < 1) {
                dummy_train.z = 2000;
            }
            dummy_train.z -= 0.5;
            {
                var z: f32 = -20;
                // rl.drawModel(electricity, rl.Vector3.init(30, 2,  200), 0.1, rl.Color.gray);
                while (z < 50) : (z += 1) {
                    rl.drawModel(electricity, rl.Vector3.init(23.5, 6, z * 50), 0.1, rl.Color.gray);
                }
                z =  -20;

                while (z < 50) : (z += 1) {
                    rl.drawModel(electricity_r, rl.Vector3.init(8, 4.5, z * 54), 0.1, rl.Color.gray);
                }
            }
            {
                var z: f32 = 1;
                rl.drawModel(sign, rl.Vector3.init(30, 2, 200), 0.1, rl.Color.gray);
                while (z < 8) : (z += 1) {
                    rl.drawModel(sign, rl.Vector3.init(30, 2, z * 550), 0.1, rl.Color.gray);
                }
            }
            rl.drawModel(train_station, rl.Vector3.init(35, 3.4, -9), 0.3, rl.Color.gray);
            rl.drawModel(train_station, rl.Vector3.init(35, 3.4, 1990), 0.3, rl.Color.gray);
            if (rules.stop_at_next_station) {
                rl.drawModel(red_signal, rl.Vector3.init(28, 2.4, 2040), 0.1, rl.Color.gray);
                rl.drawModel(red_signal, rl.Vector3.init(28, 2.4, 40), 0.1, rl.Color.gray);
            } else {
                rl.drawModel(green_signal, rl.Vector3.init(28, 2.4, 2040), 0.1, rl.Color.gray);
                rl.drawModel(green_signal, rl.Vector3.init(28, 2.4, 40), 0.1, rl.Color.gray);
            }
            rl.drawCube(rl.Vector3.init(11, 0.1, 0.0), 6, 0.01, 7000, rl.Color.dark_gray);
            rl.drawModel(track_bent_r, rl.Vector3.init(15.7, 1.5, 50), 0.15, rl.Color.dark_gray);
            rl.drawModel(track_bent, rl.Vector3.init(15.7, 1.5, 1720), 0.15, rl.Color.dark_gray);
            rl.drawCube(rl.Vector3.init(20.8, 0.1, 0.0), 6, 0.01, 7000, rl.Color.dark_gray);
            rl.drawCube(rl.Vector3.init(21, 8, 0.0), 0.1, 0.1, 7000, rl.Color.black);
            rl.drawCube(rl.Vector3.init(10.5, 8, 0.0), 0.1, 0.1, 7000, rl.Color.black);
            rl.drawCube(rl.Vector3.init(0.0, 0, 0.0), 500, -1, 7000, rl.Color.dark_brown);
        }
        // Text instructions screen
        {
            if (rules.show_instructions) {
                rl.drawRectangle(10, 10, 250, 110, rl.Color.sky_blue.fade(0.5));
                rl.drawRectangleLines(10, 10, 250, 110, rl.Color.blue);
                rl.drawText("Train controls:", 20, 20, 10, rl.Color.black);
                rl.drawText("- Go forward: W, Go back : S", 40, 40, 10, rl.Color.dark_gray);
                rl.drawText("- Press H to Honk, Press B for breaks", 40, 60, 10, rl.Color.dark_gray);
                rl.drawText("- Press C to change camera View", 40, 80, 10, rl.Color.dark_gray);
                rl.drawText("- Honk at stations to increase score", 40, 100, 10, rl.Color.dark_gray);
                rl.drawText("- Press I to hide these instructions", 40, 120, 10, rl.Color.dark_gray);
            }
            if (rl.isKeyPressed(rl.KeyboardKey.key_i)) {
                if (rules.show_instructions) {
                    rules.show_instructions = false;
                } else {
                    rules.show_instructions = true;
                }
            }
            // std.debug.print("{}\n", .{@as(i32, @intFromFloat(camera.position.z))});
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and speed > 5.1) {
                rl.drawText("Max Speed", constants.screenWidth / 2 - 100, constants.screenHeight / 2 - 100, 20, rl.Color.red);
            }
            if (camera.position.z > 1967 or camera.position.z < 7) {
                rules.within_station_boundary = true;
            } else {
                rules.within_station_boundary = false;
            }
            if (rules.iteration != 0 and @rem(rules.iteration, 2) == 0) {
                rules.stop_at_next_station = true;
            }
            if (rules.stop_at_next_station and rules.within_station_boundary and speed <= 0) {
                rules.stop_at_next_station = false; // after 1 station
                rules.iteration = 0;
                // WIN
            }
            if (rules.stop_at_next_station and camera.position.z > 1990 and speed != 0) {
                rules.failed = true;
            }
            if (rl.isKeyDown(rl.KeyboardKey.key_h) and rules.within_station_boundary and !rules.honked) {
                rules.honked = true;
                rules.score += 100;
            }

            if (!rules.within_station_boundary) {
                rules.honked = false;
            }
            if (rules.failed) {
                rl.drawRectangle(0, 0, constants.screenWidth, constants.screenHeight, rl.Color.dark_gray.fade(0.5));
                rl.drawRectangleLines(10, 10, 250, 70, rl.Color.dark_gray);
                rl.drawText("Failed", constants.screenWidth / 2 - 150, constants.screenHeight / 2 - 100, 200, rl.Color.red);
            }
            {
                const fmt = "Score: {d}";
                const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
                var buf: [len:0]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, fmt, .{rules.score}) catch unreachable;
                rl.drawText(text, constants.screenWidth - 220, 10, 20, rl.Color.black);
            }
            {
                const fmt = "Speed: {d} M/h";
                const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
                var buf: [len:0]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, fmt, .{@as(i32, @intFromFloat(speed * 2 * 10))}) catch unreachable;
                rl.drawText(text, constants.screenWidth - 220, 30, 20, rl.Color.black);
            }
            {
                const fmt = "Next station: {d} m";
                const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
                var buf: [len:0]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, fmt, .{@as(i32, @intFromFloat(2000 - camera.position.z))}) catch unreachable;
                rl.drawText(text, constants.screenWidth - 220, 50, 20, rl.Color.black);
            }
            {
                if (rules.stop_at_next_station) {
                    rl.drawText("Status: Stop at", constants.screenWidth - 220, 70, 20, rl.Color.red);
                    rl.drawText("          next station", constants.screenWidth - 220, 90, 20, rl.Color.red);
                    rl.drawText("Stop at Next station", constants.screenWidth - 500, 300, 25, rl.Color.red);
                } else {
                    rl.drawText("Status: Don't stop", constants.screenWidth - 220, 70, 20, rl.Color.green);
                }
            }

            if (camera.position.z < 0) {
                camera.position.z = 0.1;
                speed = 0;
                rl.drawText("Wrong Direction", constants.screenWidth / 2 - 100, constants.screenHeight / 2 - 100, 20, rl.Color.red);
            }
        }
    }
}

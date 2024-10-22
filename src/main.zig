const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");
const loaders = @import("loaders.zig");

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

    const audios = constants.audios_config{
        .rainMusic = rl.loadMusicStream("./music/rn.mp3"),
        .lightning = rl.loadSound("./music/lightning.mp3"),
        .trainMusic = rl.loadMusicStream("./music/train.mp3"),
        .horn = rl.loadMusicStream("./music/horn.mp3"),
    };
    rl.playMusicStream(audios.rainMusic);
    rl.playMusicStream(audios.trainMusic);
    rl.setMusicVolume(audios.trainMusic, 2);
    rl.playMusicStream(audios.horn);
    defer {
        rl.unloadMusicStream(audios.horn);
        rl.unloadMusicStream(audios.rainMusic);
        rl.unloadMusicStream(audios.trainMusic);
        rl.unloadSound(audios.lightning);
    }

    // ----------- Initialize Window -------------
    rl.initWindow(constants.screenWidth, constants.screenHeight, "3d camera first person rain");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // -------------------- Create First person Camera ------------------------

    var cameras = constants.cameras_config{
        .current_camera = 0,
        .front_camera = rl.Camera3D{
            .position = rl.Vector3.init(20, 4, 4),
            .target = rl.Vector3.init(20, -1.8, 10000000),
            .up = rl.Vector3.init(0, 1, 0),
            .fovy = 60.0,
            .projection = rl.CameraProjection.camera_perspective,
        },
        .top_view_camera = rl.Camera3D{
            .position = rl.Vector3.init(5, 20, 4),
            .target = rl.Vector3.init(20, 4, 14),
            .up = rl.Vector3.init(0, 1, 0),
            .fovy = 60.0,
            .projection = rl.CameraProjection.camera_perspective,
        },
    };

    // -------------- Load and Store 3D Models ------------------
    const models = loaders.load3DModels();
    defer loaders.unload3DModels(models);

    var dummy_train = rl.Vector3.init(9.7, 1.5, 200);
    var protagonist_train = rl.Vector3.init(20, 1.5, 10);

    // -------- Important mutable variables -------------
    var train_speed: f32 = 0;
    var rain_position = constants.rain_config{
        .raindropAvgHeight = 5,
    };

    // =-=-=-=-= Game Loop =-=-=-=-=-=
    while (!rl.windowShouldClose()) {
        // Normal updates
        {
            // camera.update(rl.CameraMode.camera_custom);
            cameras.top_view_camera.update(rl.CameraMode.camera_custom);
            cameras.front_camera.update(rl.CameraMode.camera_custom);
            rl.beginDrawing();
            defer rl.endDrawing();
        }

        // Every time result is 30, do a lightning, with lightning effects.
        {
            if (rl.getRandomValue(0, 600) == 30) {
                rl.clearBackground(rl.Color.white);
                rl.playSound(audios.lightning);
            } else {
                rl.clearBackground(rl.Color.gray);
            }
        }

        // Draw actual game
        {
            // Camera config
            cameras.top_view_camera.begin();
            cameras.front_camera.begin();

            defer {
                cameras.top_view_camera.end();
                cameras.top_view_camera.end();
                rl.endMode3D();
            }
            if (cameras.current_camera == cameras.top_view_camera_value) {
                rl.beginMode3D(cameras.top_view_camera);
            } else {
                rl.beginMode3D(cameras.front_camera);
            }
            cameras.top_view_camera.position.z = cameras.front_camera.position.z + 50;
            cameras.top_view_camera.target = cameras.front_camera.position;
            cameras.front_camera.position.z += train_speed;

            if (train_speed > 0) {
                train_speed -= 0.001;
                rl.updateMusicStream(audios.trainMusic);
                if (train_speed < 1) {
                    rl.setMusicPitch(audios.trainMusic, train_speed);
                }
            }

            // Play horn

            if (rl.isKeyPressed(rl.KeyboardKey.key_c)) {
                if (cameras.current_camera == cameras.top_view_camera_value) {
                    cameras.current_camera = cameras.front_camera_value;
                } else {
                    cameras.current_camera = cameras.top_view_camera_value;
                }
            }

            // reset playing horn
            if (rl.isKeyDown(rl.KeyboardKey.key_h)) {
                rl.updateMusicStream(audios.horn);
            } else if (rl.isKeyReleased(rl.KeyboardKey.key_h)) {
                rl.seekMusicStream(audios.horn, 0);
            }

            // Increase speed
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and train_speed < 5.1) {
                train_speed += 0.005;
            }

            // Breaks
            if (rl.isKeyDown(rl.KeyboardKey.key_b) and train_speed > 0) {
                train_speed -= 0.02;
            }

            if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
                train_speed -= 0.005;
            }
            // std.debug.print("{}\n", .{camera.position.z});

            // bring train back to 0
            if (cameras.front_camera.position.z > 2000) {
                cameras.front_camera.position.z = 0;
                rules.iteration += 1;
            }

            // ------- Rain related updates --------
            {
                rain_position.x = -10;
                rain_position.y = 10;
                // Update Rain height
                rain_position.raindropAvgHeight -= 1;
                if (rain_position.raindropAvgHeight < 0) {
                    rain_position.raindropAvgHeight = 5;
                }
                // Create rain
                while (rain_position.x < 10) : (rain_position.x += 1) {
                    rain_position.y = -10;
                    while (rain_position.y < 10) : (rain_position.y += 1) {
                        rl.drawCube(
                            rl.Vector3.init(
                                cameras.front_camera.position.x + 0.5 + @as(f16, @floatFromInt(rain_position.x + rl.getRandomValue(1, 2))),
                                @as(f16, @floatFromInt(rain_position.raindropAvgHeight + rl.getRandomValue(0, 3))),
                                cameras.front_camera.position.z + @as(f16, @floatFromInt(rain_position.y + rl.getRandomValue(0, 2))),
                            ),
                            0.01,
                            0.2,
                            0.01,
                            rl.Color.blue.fade(0.6),
                        );
                    }
                }
                // Update rain music
                rl.updateMusicStream(audios.rainMusic);
            }
            var x: f32 = -5;
            while (x < 4) : (x += 1) {
                var z: f32 = -20;
                if (x == 0 or x == 1) {
                    continue;
                }
                while (z < 100) : (z += 1) {
                    rl.drawModel(models.tree, rl.Vector3.init(x * 20, 12, z * 40), 0.3, rl.Color.brown);
                }
            }
            {
                var z: f32 = -30;
                while (z < 40) : (z += 1) {
                    rl.drawModel(models.mountains, rl.Vector3.init(-300, 30, z * 200), 2, rl.Color.brown);
                    rl.drawModel(models.mountains, rl.Vector3.init(150, 30, z * 200), 2, rl.Color.brown);
                }
            }

            var i: f32 = -50;
            while (i < 500) : (i += 1) {
                rl.drawModel(models.track, rl.Vector3.init(20, 1.5, i * 17), 0.15, rl.Color.dark_gray);
                rl.drawModel(models.track, rl.Vector3.init(10, 1.5, i * 17), 0.15, rl.Color.dark_gray);
            }
            protagonist_train.x = cameras.front_camera.position.x;
            protagonist_train.z = cameras.front_camera.position.z - 30;
            rl.drawModel(models.train, dummy_train, 0.052, rl.Color.gray);
            rl.drawModel(models.train, protagonist_train, 0.052, rl.Color.gray);
            if (dummy_train.z < 1) {
                dummy_train.z = 2000;
            }
            dummy_train.z -= 0.5;
            {
                var z: f32 = -20;
                // rl.drawModel(electricity, rl.Vector3.init(30, 2,  200), 0.1, rl.Color.gray);
                while (z < 50) : (z += 1) {
                    rl.drawModel(models.electricity, rl.Vector3.init(23.5, 6, z * 50), 0.1, rl.Color.gray);
                }
                z = -20;

                while (z < 50) : (z += 1) {
                    rl.drawModel(models.electricity_r, rl.Vector3.init(8, 4.5, z * 54), 0.1, rl.Color.gray);
                }
            }
            {
                rl.drawModel(models.sign, rl.Vector3.init(30, 2, 200), 0.1, rl.Color.gray);
                for (1..8) |z| {
                    rl.drawModel(models.sign, rl.Vector3.init(30, 2, @as(f32, @floatFromInt(z)) * 550), 0.1, rl.Color.gray);
                }
            }
            rl.drawModel(models.train_station, rl.Vector3.init(35, 3.4, -9), 0.3, rl.Color.gray);
            rl.drawModel(models.train_station, rl.Vector3.init(35, 3.4, 1990), 0.3, rl.Color.gray);
            if (rules.stop_at_next_station) {
                rl.drawModel(models.red_signal, rl.Vector3.init(28, 2.4, 2040), 0.1, rl.Color.gray);
                rl.drawModel(models.red_signal, rl.Vector3.init(28, 2.4, 40), 0.1, rl.Color.gray);
            } else {
                rl.drawModel(models.green_signal, rl.Vector3.init(28, 2.4, 2040), 0.1, rl.Color.gray);
                rl.drawModel(models.green_signal, rl.Vector3.init(28, 2.4, 40), 0.1, rl.Color.gray);
            }
            // rl.drawCube(rl.Vector3.init(11, 0.1, 0.0), 6, 0.01, 7000, rl.Color.dark_gray);
            {
                var fortrack: f32 = -20;
                while (fortrack < 500) : (fortrack += 1) {
                    rl.drawModel(models.track_bottom, rl.Vector3.init(20.7, 0.4, fortrack * 5), 0.3, rl.Color.dark_gray);
                }
            }
            {
                var fortrack: f32 = -20;
                while (fortrack < 500) : (fortrack += 1) {
                    rl.drawModel(models.track_bottom, rl.Vector3.init(10.7, 0.4, fortrack * 5), 0.3, rl.Color.dark_gray);
                }
            }
            rl.drawModel(models.track_bent_r, rl.Vector3.init(15.7, 1.5, 50), 0.15, rl.Color.dark_gray);
            rl.drawModel(models.track_bent, rl.Vector3.init(15.7, 1.5, 1720), 0.15, rl.Color.dark_gray);
            // rl.drawCube(rl.Vector3.init(20.8, 0.1, 0.0), 6, 0.01, 7000, rl.Color.dark_gray);
            rl.drawCube(rl.Vector3.init(21, 8, 0.0), 0.1, 0.1, 7000, rl.Color.black);
            rl.drawCube(rl.Vector3.init(10.5, 8, 0.0), 0.1, 0.1, 7000, rl.Color.black);
            {
                var forScene: f32 = -20;
                while (forScene < 500) : (forScene += 1) {
                    var forScenex: f32 = -40;
                    while (forScenex < 100) : (forScenex += 20) {
                        rl.drawModel(models.scene, rl.Vector3.init(forScenex, 0.1, @as(f32, @floatCast(forScene * 20))), 1, rl.Color.gray);
                        // rl.drawModel(scene, rl.Vector3.init(20, -0.5, @as(f32, @floatCast(forScene * 20))), 1, rl.Color.light_gray);
                    }
                }
            }
        }
        // Text instructions screen
        {
            if (rules.show_instructions) {
                rl.drawRectangle(10, 10, 250, 130, rl.Color.sky_blue.fade(0.5));
                rl.drawRectangleLines(10, 10, 250, 130, rl.Color.blue);
                rl.drawText("Train controls:", 20, 20, 10, rl.Color.black);
                rl.drawText("- Go forward: W, Go back : S", 40, 40, 10, rl.Color.dark_gray);
                rl.drawText("- Press H to Honk, Press B for breaks", 40, 60, 10, rl.Color.dark_gray);
                rl.drawText("- Press C to change camera View", 40, 80, 10, rl.Color.dark_gray);
                rl.drawText("- Honk at stations to increase score", 40, 100, 10, rl.Color.dark_gray);
                rl.drawText("- Press I to hide these instructions", 40, 120, 10, rl.Color.dark_gray);
            }
            if (rl.isKeyPressed(rl.KeyboardKey.key_i)) {
                rules.show_instructions = !rules.show_instructions;
            }
            // std.debug.print("{}\n", .{@as(i32, @intFromFloat(camera.position.z))});
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and train_speed > 5.1) {
                rl.drawText("Max Speed", constants.screenWidth / 2 - 100, constants.screenHeight / 2 - 100, 20, rl.Color.red);
            }
            if (cameras.front_camera.position.z > 1967 or cameras.front_camera.position.z < 7) {
                rules.within_station_boundary = true;
            } else {
                rules.within_station_boundary = false;
            }
            if (rules.iteration != 0 and @rem(rules.iteration, 2) == 0) {
                rules.stop_at_next_station = true;
            }
            if (rules.stop_at_next_station and rules.within_station_boundary and train_speed <= 0) {
                rules.stop_at_next_station = false; // after 1 station
                rules.iteration = 0;
                // WIN
            }
            if (rules.stop_at_next_station and cameras.front_camera.position.z > 1990 and train_speed != 0) {
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
                const text = std.fmt.bufPrintZ(&buf, fmt, .{@as(i32, @intFromFloat(train_speed * 2 * 10))}) catch unreachable;
                rl.drawText(text, constants.screenWidth - 220, 30, 20, rl.Color.black);
            }
            {
                const fmt = "Next station: {d} m";
                const len = comptime std.fmt.count(fmt, .{std.math.maxInt(i32)});
                var buf: [len:0]u8 = undefined;
                const text = std.fmt.bufPrintZ(&buf, fmt, .{@as(i32, @intFromFloat(2000 - cameras.front_camera.position.z))}) catch unreachable;
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

            if (cameras.front_camera.position.z < 0) {
                cameras.front_camera.position.z = 0.1;
                train_speed = 0;
                rl.drawText("Wrong Direction", constants.screenWidth / 2 - 100, constants.screenHeight / 2 - 100, 20, rl.Color.red);
            }
        }
    }
}

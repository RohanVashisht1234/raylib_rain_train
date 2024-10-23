const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");
const loaders = @import("loaders.zig");
const functions = @import("functions.zig");

pub fn game_loop(cameras: *constants.cameras_config, audios: constants.audios_config, dummy_train: *rl.Vector3, protagonist_train: *rl.Vector3, train_speed: *f32, rain_position: *constants.rain_config, rules: *constants._rules, models: constants.models_config) void {
    // camera.update(rl.CameraMode.camera_custom);
    const active_camera = if (cameras.*.current_camera == cameras.*.top_view_camera_value)
        cameras.*.top_view_camera
    else
        cameras.*.front_camera;
    rl.beginDrawing();
    defer rl.endDrawing();

    // Every time result is 30, do a lightning, with lightning effects.
    if (rl.getRandomValue(0, 600) == 30) {
        rl.clearBackground(rl.Color.white);
        rl.playSound(audios.lightning);
    } else {
        rl.clearBackground(rl.Color.gray);
    }

    // Draw actual game
    {
        // Camera config
        active_camera.begin();

        defer {
            active_camera.end();
            rl.endMode3D();
        }
        rl.beginMode3D(active_camera);
        cameras.*.top_view_camera.position.z = cameras.*.front_camera.position.z + 50;
        cameras.*.top_view_camera.target = cameras.*.front_camera.position;
        cameras.*.front_camera.position.z += train_speed.*;

        if (train_speed.* > 0) {
            train_speed.* -= 0.001;
            rl.updateMusicStream(audios.trainMusic);
            if (train_speed.* < 1) {
                rl.setMusicPitch(audios.trainMusic, train_speed.*);
            }
        }

        // Play horn

        if (rl.isKeyPressed(rl.KeyboardKey.key_c)) {
            if (cameras.*.current_camera == cameras.*.top_view_camera_value) {
                cameras.*.current_camera = cameras.*.front_camera_value;
            } else {
                cameras.*.current_camera = cameras.*.top_view_camera_value;
            }
        }

        // reset playing horn
        if (rl.isKeyDown(rl.KeyboardKey.key_h)) {
            rl.updateMusicStream(audios.horn);
        } else if (rl.isKeyReleased(rl.KeyboardKey.key_h)) {
            rl.seekMusicStream(audios.horn, 0);
        }

        // Increase speed
        if (rl.isKeyDown(rl.KeyboardKey.key_w) and train_speed.* < 5.1) {
            train_speed.* += 0.005;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_b) and train_speed.* > 0) {
            train_speed.* -= 0.02;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            train_speed.* -= 0.005;
        }
        // std.debug.print("{}\n", .{camera.position.z});

        // bring train back to 0
        if (cameras.*.front_camera.position.z > 2000) {
            cameras.*.front_camera.position.z = 0;
            rules.*.iteration += 1;
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
                rain_position.y = 0;
                while (rain_position.y < 10) : (rain_position.y += 1) {
                    const rand_value: f32 = @floatFromInt(rl.getRandomValue(1, 2));
                    rl.drawCube(
                        rl.Vector3.init(
                            cameras.*.front_camera.position.x + 0.5 + rain_position.x + rand_value,
                            rain_position.raindropAvgHeight + rand_value,
                            cameras.*.front_camera.position.z + rain_position.y + rand_value,
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
            if (x == 0 or x == 1) continue;
            const mul1 = x * 20;
            while (z < 100) : (z += 1) {
                rl.drawModel(models.tree, rl.Vector3.init(mul1, 12, z * 40), 0.3, rl.Color.brown);
            }
        }
        var forMountains: f32 = -5;
        while (forMountains < 15) : (forMountains += 1) {
            rl.drawModel(models.mountains, rl.Vector3.init(-300, 30, forMountains * 200), 2, rl.Color.brown);
            rl.drawModel(models.mountains, rl.Vector3.init(150, 30, forMountains * 200), 2, rl.Color.brown);
        }

        var i: f32 = -30;
        while (i < 150) : (i += 1) {
            const mul = i * 17;
            rl.drawModel(models.track, rl.Vector3.init(20, 1.5, mul), 0.15, rl.Color.dark_gray);
            rl.drawModel(models.track, rl.Vector3.init(10, 1.5, mul), 0.15, rl.Color.dark_gray);
        }
        protagonist_train.*.x = cameras.*.front_camera.position.x;
        protagonist_train.*.z = cameras.*.front_camera.position.z - 30;
        rl.drawModel(models.train, dummy_train.*, 0.052, rl.Color.gray);
        rl.drawModel(models.train, protagonist_train.*, 0.052, rl.Color.gray);
        if (dummy_train.*.z < 1) dummy_train.*.z = 2000;

        dummy_train.*.z -= 0.5;

        var forElectricity: f32 = -20;

        while (forElectricity < 50) : (forElectricity += 1) {
            rl.drawModel(models.electricity, rl.Vector3.init(23.5, 6, forElectricity * 50), 0.1, rl.Color.gray);
            rl.drawModel(models.electricity_r, rl.Vector3.init(8, 4.5, forElectricity * 54), 0.1, rl.Color.gray);
        }

        {
            rl.drawModel(models.sign, rl.Vector3.init(30, 2, 200), 0.1, rl.Color.gray);
            for (1..8) |z| {
                rl.drawModel(models.sign, rl.Vector3.init(30, 2, @as(f32, @floatFromInt(z * 550))), 0.1, rl.Color.gray);
            }
        }
        rl.drawModel(models.train_station, rl.Vector3.init(35, 3.4, -9), 0.3, rl.Color.gray);
        rl.drawModel(models.train_station, rl.Vector3.init(35, 3.4, 1990), 0.3, rl.Color.gray);
        if (rules.*.stop_at_next_station) {
            rl.drawModel(models.red_signal, rl.Vector3.init(28, 2.4, 2040), 0.1, rl.Color.gray);
            rl.drawModel(models.red_signal, rl.Vector3.init(28, 2.4, 40), 0.1, rl.Color.gray);
        } else {
            rl.drawModel(models.green_signal, rl.Vector3.init(28, 2.4, 2040), 0.1, rl.Color.gray);
            rl.drawModel(models.green_signal, rl.Vector3.init(28, 2.4, 40), 0.1, rl.Color.gray);
        }
        var fortrack: f32 = -20;
        while (fortrack < 450) : (fortrack += 1) {
            rl.drawModel(models.track_bottom, rl.Vector3.init(20.7, 0.4, fortrack * 6), 0.3, rl.Color.dark_gray);
            rl.drawModel(models.track_bottom, rl.Vector3.init(10.7, 0.4, fortrack * 6), 0.3, rl.Color.dark_gray);
        }
        rl.drawModel(models.track_bent_r, rl.Vector3.init(15.7, 1.7, 50), 0.15, rl.Color.dark_gray);
        rl.drawModel(models.track_bent, rl.Vector3.init(15.7, 1.7, 1720), 0.15, rl.Color.dark_gray);
        // rl.drawCube(rl.Vector3.init(20.8, 0.1, 0.0), 6, 0.01, 7000, rl.Color.dark_gray);
        rl.drawCube(rl.Vector3.init(21, 8, 1000), 0.1, 0.1, 2500, rl.Color.black);
        rl.drawCube(rl.Vector3.init(10.5, 8, 1000), 0.1, 0.1, 2500, rl.Color.black);
        var forGrass: f32 = -30;
        while (forGrass < 130) : (forGrass += 1) {
            var forGrassx: f32 = -40;
            const forGrassZ: f32 = forGrass * 20; // compute this once use multiple times.
            while (forGrassx < 100) : (forGrassx += 20) {
                rl.drawModel(models.grass, rl.Vector3.init(forGrassx, 0.1, forGrassZ), 1, rl.Color.gray);
            }
        }
    }
    // Text instructions screen
    if (rules.*.show_instructions) {
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
        rules.*.show_instructions = !rules.*.show_instructions;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_w) and train_speed.* > 5.1) {
        rl.drawText("Max Speed", constants.screenWidth / 2 - 100, constants.screenHeight / 2 - 100, 20, rl.Color.red);
    }
    if (cameras.*.front_camera.position.z > 1967 or cameras.*.front_camera.position.z < 7) {
        rules.*.within_station_boundary = !rules.*.within_station_boundary;
    }

    rules.*.stop_at_next_station = rules.*.iteration != 0 and @rem(rules.*.iteration, 2) == 0;

    if (rules.*.stop_at_next_station and rules.*.within_station_boundary and train_speed.* <= 0) {
        rules.*.stop_at_next_station = false; // after 1 station
        rules.*.iteration = 0;
        // WIN
    }
    if (rules.*.stop_at_next_station and cameras.*.front_camera.position.z > 1990 and train_speed.* != 0) {
        rules.*.failed = true;
    }
    if (rules.*.failed) {
        rl.drawRectangle(0, 0, constants.screenWidth, constants.screenHeight, rl.Color.dark_gray.fade(0.5));
        rl.drawRectangleLines(10, 10, 250, 70, rl.Color.dark_gray);
        rl.drawText("Failed", constants.screenWidth / 2 - 150, constants.screenHeight / 2 - 100, 200, rl.Color.red);
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_h) and rules.*.within_station_boundary and !rules.*.honked) {
        rules.*.honked = true;
        rules.*.score += 100;
    }

    if (!rules.*.within_station_boundary) {
        rules.*.honked = false;
    }

    rl.drawText(functions.concatenate("Score: {d}", @as(f32, @floatFromInt(rules.*.score))), constants.screenWidth - 220, 10, 20, rl.Color.black);
    rl.drawText(functions.concatenate("Speed: {d} M/h", train_speed.* * 2 * 10), constants.screenWidth - 220, 30, 20, rl.Color.black);
    rl.drawText(functions.concatenate("Next station: {d} m", 2000 - cameras.*.front_camera.position.z), constants.screenWidth - 220, 50, 20, rl.Color.black);

    if (rules.*.stop_at_next_station) {
        rl.drawText("Status: Stop at", constants.screenWidth - 220, 70, 20, rl.Color.red);
        rl.drawText("          next station", constants.screenWidth - 220, 90, 20, rl.Color.red);
        rl.drawText("Stop at Next station", constants.screenWidth - 500, 300, 25, rl.Color.red);
    } else {
        rl.drawText("Status: Don't stop", constants.screenWidth - 220, 70, 20, rl.Color.green);
    }

    if (cameras.*.front_camera.position.z < 0) {
        cameras.*.front_camera.position.z = 0.1;
        train_speed.* = 0;
        rl.drawText("Wrong Direction", constants.screenWidth / 2 - 100, constants.screenHeight / 2 - 100, 20, rl.Color.red);
    }
}

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

    const audios = loaders.loadAudio();
    rl.playMusicStream(audios.rainMusic);
    rl.playMusicStream(audios.trainMusic);
    rl.setMusicVolume(audios.trainMusic, 2);
    rl.playMusicStream(audios.horn);
    defer loaders.unloadAudio(audios);

    // ----------- Initialize Window -------------
    rl.initWindow(constants.screenWidth, constants.screenHeight, "3d camera first person rain");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    // -------------------- Create First person Camera ------------------------

    var cameras = loaders.loadCameras();

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
    while (!rl.windowShouldClose()) {
        game_loop(&cameras, audios, &dummy_train, &protagonist_train, &train_speed, &rain_position, &rules, models);
    }
}

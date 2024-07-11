const std = @import("std");
const rl = @import("raylib");

const screenWidth: u11 = 1080;
const screenHeight: u11 = 720;

pub fn main() void {
    // Initialize Audio
    rl.initAudioDevice();
    const bgMusic: rl.Music = rl.loadMusicStream("./music/rn.mp3");
    rl.playMusicStream(bgMusic);

    const trainMusic: rl.Music = rl.loadMusicStream("./music/train.mp3");
    rl.playMusicStream(trainMusic);

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
            var x: f32 = -4;
            while (x < 4) : (x += 1) {
                var z: f32 = -1;
                while (z < 100) : (z += 1) {
                    rl.drawModel(tree, rl.Vector3.init(x * 40, 12, -z * 50), 0.3, rl.Color.dark_green);
                    rl.drawModel(train_station, rl.Vector3.init(-30, 2, -z * 2000), 0.3, rl.Color.gray);
                }
            }

            var i: f32 = 0;
            while (i < 500) : (i += 1) {
                rl.drawModel(track, rl.Vector3.init(-20, 3.5, -i * 20), 0.2, rl.Color.gray);
            }

            
            camera.position.z -= speed;
            if (speed > 0) {
                speed -= 0.001;
                rl.updateMusicStream(trainMusic);
                if (speed > 0.09 and speed < 1) {
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
                speed -= 0.01;
            }
            std.debug.print("{}\n", .{camera.position.z});
            if(camera.position.z < -2000){
                camera.position.z = 0;
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
            rl.drawRectangle(10, 10, 250, 70, rl.Color.sky_blue.fade(0.5));
            rl.drawRectangleLines(10, 10, 250, 70, rl.Color.blue);
            rl.drawText("Train controls:", 20, 20, 10, rl.Color.black);
            rl.drawText("- Go forward: W, Go back : S", 40, 40, 10, rl.Color.dark_gray);
            rl.drawText("- Press H to Honk, Press B for breaks", 40, 60, 10, rl.Color.dark_gray);
            if (rl.isKeyDown(rl.KeyboardKey.key_w) and speed > 5) {
                rl.drawText("Max Speed", screenWidth/2-100, screenHeight/2-100, 20, rl.Color.red);
            }
            if(camera.position.z > 0){
                camera.position.z = -0.1;
                speed = 0;
                rl.drawText("Wrong Direction", screenWidth/2-100, screenHeight/2-100, 20, rl.Color.red);
            }
        }
    }
}

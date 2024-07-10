const std = @import("std");
const rl = @import("raylib");

const screenWidth: u11 = 1080;
const screenHeight: u11 = 720;

pub fn main() void {
    // Initialize Audio
    rl.initAudioDevice();
    const bgMusic: rl.Music = rl.loadMusicStream("./music/rn.mp3");
    rl.playMusicStream(bgMusic);

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
    defer rl.unloadModel(mine);
    defer rl.unloadModel(tree);
    defer rl.unloadModel(track);
    defer rl.unloadModel(terrain);
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
                rl.Vector3.init(camera.position.x , 3.5, camera.position.z+1),
                0.1,
                rl.Color.red,
            );
            var x: f32 = -20;
            while (x < 20) : (x += 1) {
                var z: f32 = -20;
                while (z < 20) : (z += 1) {
                    rl.drawModel(tree, rl.Vector3.init(x * 40, 12, z * 40), 0.3, rl.Color.dark_green);
                    
                }
            }

            var i:f32 = 0;
            while(i < 500):(i+=1){
                rl.drawModel(track, rl.Vector3.init(-20, 3, -i*20), 0.2, rl.Color.gray);
            }
            if(rl.isKeyDown(rl.KeyboardKey.key_w)){
                camera.position.z -= 1.0;
            }
            // Draw rain grid
            if(rl.isKeyDown(rl.KeyboardKey.key_s)){
                camera.position.z += 1.0;
            }
            
            var f: i8 = -10;
            while (f < 10) : (f += 1) {
                var g: i8 = -10;
                while (g < 10) : (g += 1) {
                    rl.drawCube(
                        rl.Vector3.init(
                            camera.position.x + @as(f32, @floatFromInt(f + rl.getRandomValue(0, 2))),
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
            rl.drawCube(rl.Vector3.init(0.0, 0, 0.0), 5000, 0.01, 5000,rl.Color.dark_brown);

            // Draw a blue wall for understansing where you are going.
            rl.drawCube(rl.Vector3.init(16.0, -0.4, 0.0), 1.0, 10, 50.0, rl.Color.dark_blue);
        }

        // Text instructions screen
        {
            rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
            rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);
            rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
            rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
            rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);
        }
    }
}

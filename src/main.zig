const rl = @import("raylib");

const screenWidth = 1920;
const screenHeight = 1080;

pub fn main() void {
    // Initialize Audio
    rl.initAudioDevice();
    const bgMusic: rl.Music = rl.loadMusicStream("./music/rn.mp3");
    rl.playMusicStream(bgMusic);

    // Initialize Window
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - 3d camera first person");
    defer rl.closeWindow();

    // Create First person Camera
    var camera = rl.Camera3D{
        .position = rl.Vector3.init(4, 2, 4),
        .target = rl.Vector3.init(0, 1.8, 0),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 60,
        .projection = rl.CameraProjection.camera_perspective,
    };

    rl.disableCursor();
    rl.setTargetFPS(60);

    // The Average height of each raindrop
    var raindropAvgHeight: f32 = 5.0;

    // Game main loop
    while (!rl.windowShouldClose()) {
        rl.updateMusicStream(bgMusic);

        // Update raindrop height
        {
            raindropAvgHeight -= 1.0;
            if (raindropAvgHeight < 0.0) {
                raindropAvgHeight = 5.0;
            }
        }

        camera.update(rl.CameraMode.camera_first_person);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.gray);

        // Draw actual game
        {
            camera.begin();
            defer camera.end();

            // Draw rain grid
            var f: f32 = -50.0;
            while (f < 50.0) : (f += 1.0) {
                var g: f32 = -50.0;
                while (g < 50.0) : (g += 1.0) {
                    rl.drawCube(
                        rl.Vector3.init(f, raindropAvgHeight + @as(f32, @floatFromInt(rl.getRandomValue(0, 3))), g),
                        0.01,
                        0.2,
                        0.01,
                        rl.Color.blue,
                    );
                }
            }

            // Draw ground
            rl.drawCube(rl.Vector3.init(16.0, -0.4, 0.0), 500.0, 0.01, 500.0, rl.Color.dark_green);

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

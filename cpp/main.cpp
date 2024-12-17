#include <raylib.h>
#define SCREEN_WIDTH 1920
#define SCREEN_HEIGHT 1080

#define RENDER_DISTANCE_BACK 550
#define RENDER_DISTANCE_FRONT 250

#define RENDER_DISTANCE_BACK_FOR_TREES 600
#define RENDER_DISTANCE_FRONT_FOR_TREES RENDER_DISTANCE_BACK_FOR_TREES

class Models
{
public:
    Model red_signal,
        green_signal,
        terrain,
        tree,
        track,
        train,
        train_station,
        sign,
        electricity,
        electricity_r,
        track_bent,
        track_bottom,
        track_bent_r,
        mountains,
        grass;
    Models()
    {
        red_signal = LoadModel("./assets/red_signal.glb"),
        green_signal = LoadModel("./assets/green_signal.glb"),
        terrain = LoadModel("./assets/terrain.glb"),
        tree = LoadModel("./assets/tree.glb"),
        track = LoadModel("./assets/track.glb"),
        train = LoadModel("./assets/train.glb"),
        train_station = LoadModel("./assets/train_station.glb"),
        sign = LoadModel("./assets/sign.glb"),
        electricity = LoadModel("./assets/electricity.glb"),
        electricity_r = LoadModel("./assets/electricity_r.glb"),
        track_bent = LoadModel("./assets/track_bent.glb"),
        track_bottom = LoadModel("./assets/track_bottom.glb"),
        track_bent_r = LoadModel("./assets/track_bent_r.glb"),
        mountains = LoadModel("./assets/mountains.glb"),
        grass = LoadModel("./assets/scene.glb");
    }
    ~Models()
    {
        UnloadModel(red_signal);
        UnloadModel(green_signal);
        UnloadModel(terrain);
        UnloadModel(tree);
        UnloadModel(track);
        UnloadModel(train);
        UnloadModel(train_station);
        UnloadModel(sign);
        UnloadModel(electricity);
        UnloadModel(electricity_r);
        UnloadModel(track_bent);
        UnloadModel(track_bottom);
        UnloadModel(track_bent_r);
        UnloadModel(mountains);
        UnloadModel(grass);
    }
};

class Musics
{
public:
    Music train_background, horn;
    Musics()
    {
        train_background = LoadMusicStream("./music/train.mp3");
        horn = LoadMusicStream("./music/horn.mp3");
    }
    ~Musics()
    {
        UnloadMusicStream(train_background);
        UnloadMusicStream(horn);
    }
};

class BasicInitializers
{
public:
    BasicInitializers()
    {
        InitAudioDevice();
        InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raylib Model Loader");
        SetTargetFPS(60);
    }
    ~BasicInitializers()
    {
        CloseWindow();
        CloseAudioDevice();
    }
};

class Rules
{
public:
    bool stop_at_next_station;
    unsigned short iteration; // How many stations have been crossed
    bool within_station_boundary;
    bool failed;
    unsigned short score;
    bool honked;
    bool show_instructions;
    Rules()
    {
        stop_at_next_station = false;
        iteration = 0,
        within_station_boundary = false;
        failed = false;
        score = 0,
        honked = false;
        show_instructions = true;
    }
};

class Cameras
{
    int which_active_camera;

public:
    Camera3D active_camera;
    Camera3D front_camera;
    Camera3D top_view_camera;
    Cameras()
    {
        front_camera = (Camera3D){
            (Vector3){20, 4, 4},
            (Vector3){20, -1.8, 10000},
            (Vector3){0, 1, 0},
            60.0f,
            CAMERA_PERSPECTIVE,
        };

        top_view_camera = (Camera3D){
            (Vector3){5, 20, 4},
            (Vector3){20, 4, 14},
            (Vector3){0, 1, 0},
            60.0,
            CAMERA_PERSPECTIVE,
        };

        which_active_camera = 0;
        active_camera = front_camera;
    }
    void switch_camera()
    {
        active_camera = (which_active_camera == 0) ? top_view_camera : front_camera;
        which_active_camera = 1 - which_active_camera;
    }
    void update_active_camera(float protagonist_train_speed)
    {
        front_camera.position.z += protagonist_train_speed;
        top_view_camera.position.z = front_camera.position.z + 50;
        top_view_camera.target = front_camera.position;
        if (which_active_camera == 0)
            active_camera = front_camera;
        else
            active_camera = top_view_camera;
    }
};

class TrainConfig
{
public:
    Vector3 protagonist_train_position, dummy_train_position;
    float protagonist_train_speed;
    TrainConfig()
    {
        protagonist_train_position = (Vector3){20, 1.5, 10};
        dummy_train_position = (Vector3){11.2, 1.5, 200};
        protagonist_train_speed = 0;
    }
};

class InitRaylib
{
    const BasicInitializers _;

public:
    const Models models;
    const Musics musics;
    Rules rules;
    Cameras cameras;
    TrainConfig train_config;
};

int main()
{
    InitRaylib rl;
    PlayMusicStream(rl.musics.train_background);
    PlayMusicStream(rl.musics.horn);

    while (!WindowShouldClose())
    {
        UpdateCamera(&rl.cameras.active_camera, CAMERA_PERSPECTIVE);
        BeginDrawing();
        {
            ClearBackground(SKYBLUE);
            BeginMode3D(rl.cameras.active_camera);
            {
                {
                    rl.cameras.update_active_camera(rl.train_config.protagonist_train_speed);

                    if (rl.train_config.protagonist_train_speed > 0)
                    {
                        rl.train_config.protagonist_train_speed -= 0.001f;
                    }

                    if (IsKeyPressed(KEY_C))
                    {
                        rl.cameras.switch_camera();
                    }
                    if (IsKeyPressed(KEY_H))
                    {
                        UpdateMusicStream(rl.musics.horn);
                    }
                    else if (IsKeyReleased(KEY_H))
                    {
                        SeekMusicStream(rl.musics.horn, 0);
                    }

                    if (IsKeyDown(KEY_W) && rl.train_config.protagonist_train_speed < 5.1f)
                    {
                        rl.train_config.protagonist_train_speed += 0.005f;
                    }
                    else if (rl.train_config.protagonist_train_speed > 0)
                    {
                        if (IsKeyDown(KEY_B))
                        {
                            rl.train_config.protagonist_train_speed -= 0.02f;
                        }
                        else if (IsKeyDown(KEY_S))
                        {
                            rl.train_config.protagonist_train_speed -= 0.005f;
                        }
                    }

                    if (rl.cameras.front_camera.position.z > 2000.0f)
                    {
                        rl.cameras.front_camera.position.z = 0.0f;
                        rl.rules.iteration += 1.0f;
                    }
                }
                {
                    for (float z = -20; z < 100; z += 1) // 'z' loop moved outside
                    {
                        for (float x = -5; x < 4; x += 1) // 'x' loop inside
                        {
                            if (x == 0 || x == 1)
                                continue;

                            const float mul = z * 40;
                            // Save Memory!!
                            if (mul < rl.cameras.active_camera.position.z - RENDER_DISTANCE_BACK_FOR_TREES || mul > rl.cameras.active_camera.position.z + RENDER_DISTANCE_FRONT_FOR_TREES)
                                continue;
                            DrawModel(rl.models.tree, (Vector3){x*20, 12, mul}, 0.3f, BROWN);
                        }
                    }

                    for (float forMountains = -5; forMountains < 15; forMountains += 1)
                    {
                        const float mul = forMountains * 200;
                        DrawModel(rl.models.mountains, (Vector3){-300, 30, mul}, 2.0f, GRAY);
                        DrawModel(rl.models.mountains, (Vector3){150, 30, mul}, 2.0f, GRAY);
                    }

                    for (float i = -30; i < 290; i += 1)
                    {
                        const float mul = i * 8;
                        // Save Memory!!!
                        if (mul < rl.cameras.active_camera.position.z - RENDER_DISTANCE_BACK || mul > rl.cameras.active_camera.position.z + RENDER_DISTANCE_FRONT)
                            continue;
                        DrawModel(rl.models.track, (Vector3){20.7, 0.62, mul}, 0.01f, GRAY);
                        DrawModel(rl.models.track, (Vector3){10.7, 0.62, mul}, 0.01f, GRAY);
                    }

                    // rl.drawModel(models.sky, rl.Vector3.init(protagonist_train_position.x, protagonist_train_position.y + 60.0, protagonist_train_position.z + 100.0), 500, rl.Color.light_gray);

                    DrawModel(rl.models.train, rl.train_config.dummy_train_position, 1.7f, YELLOW);
                    DrawModel(rl.models.train, rl.train_config.protagonist_train_position, 1.7f, LIGHTGRAY);
                    rl.train_config.protagonist_train_position.x = rl.cameras.front_camera.position.x + 1.55;
                    rl.train_config.protagonist_train_position.z = rl.cameras.front_camera.position.z - 100;
                    if (rl.train_config.dummy_train_position.z < -50)
                        rl.train_config.dummy_train_position.z = 2050;

                    rl.train_config.dummy_train_position.z -= 0.5;

                    for (float forElectricity = -20; forElectricity < 50; forElectricity += 1)
                    {
                        const float mul = forElectricity * 50;
                        // Save Memory!!!
                        if (mul < rl.cameras.active_camera.position.z - 700 || mul > rl.cameras.active_camera.position.z + 350)
                            continue;
                        DrawModel(rl.models.electricity, (Vector3){26, 4, mul + 10.0f}, 0.5f, GRAY);
                        DrawModel(rl.models.electricity_r, (Vector3){5.3, 4, mul}, 0.5f, GRAY);
                    }

                    {
                        DrawModel(rl.models.sign, (Vector3){30, 2, 200}, 0.1f, GRAY);
                        for (int z = 1; z < 4; ++z)
                        {
                            DrawModel(rl.models.sign, (Vector3){30, 2, z * 550.0f}, 0.1f, GRAY);
                        }
                    }

                    DrawModel(rl.models.train_station, (Vector3){35, 3.4, -9}, 0.3f, GRAY);
                    DrawModel(rl.models.train_station, (Vector3){35, 3.4, 1990}, 0.3f, GRAY);

                    if (rl.rules.stop_at_next_station)
                    {
                        DrawModel(rl.models.red_signal, (Vector3){28, 2.4, 2040}, 0.1f, GRAY);
                        DrawModel(rl.models.red_signal, (Vector3){28, 2.4, 40}, 0.1f, GRAY);
                    }
                    else
                    {
                        DrawModel(rl.models.green_signal, (Vector3){28, 2.4, 2040}, 0.1f, GRAY);
                        DrawModel(rl.models.green_signal, (Vector3){28, 2.4, 40}, 0.1f, GRAY);
                    }

                    DrawModel(rl.models.track_bent_r, (Vector3){15.7, 1.7, 50}, 0.15f, DARKGRAY);
                    DrawModel(rl.models.track_bent, (Vector3){15.7, 1.7, 1720}, 0.15f, DARKGRAY);

                    // rl.drawCube(rl.Vector3.init(20.8, 0.1, 0.0), 6, 0.01, 7000, rl.Color.dark_gray);
                    DrawCube((Vector3){21, 9, 1000}, 0.1f, 0.1f, 2500, BLACK);
                    DrawCube((Vector3){21, 11.3, 1000}, 0.1f, 0.1f, 2500, BLACK);
                    DrawCube((Vector3){10.5, 9, 1000}, 0.1f, 0.1f, 2500, BLACK);
                    DrawCube((Vector3){10.5, 11.3, 1000}, 0.1f, 0.1f, 2500, BLACK);

                    for (float forGrass = -30; forGrass < 130; forGrass += 1)
                    {
                        float forGrassx = -40;
                        const float forGrassZ = forGrass * 20; // compute this once, use multiple times.
                        for (forGrassx = -40; forGrassx < 100; forGrassx += 20)
                        {
                            DrawModel(rl.models.grass, (Vector3){forGrassx, 0.1, forGrassZ}, 1.0f, GRAY);
                        }
                    }
                }
            }
            EndMode3D();
        }
        EndDrawing();
    }
    return 0;
}
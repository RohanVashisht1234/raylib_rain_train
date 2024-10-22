pub const screenWidth: u11 = 1920;
pub const screenHeight: u11 = 1080;
const rl = @import("raylib");

// Define the rules of the game
pub const _rules = struct {
    stop_at_next_station: bool,
    iteration: u8, // How many stations have been crossed
    within_station_boundary: bool,
    failed: bool,
    score: i32,
    honked: bool,
    show_instructions: bool,
};

pub const models_config = struct {
    red_signal: rl.Model,
    green_signal: rl.Model,
    terrain: rl.Model,
    tree: rl.Model,
    track: rl.Model,
    train: rl.Model,
    train_station: rl.Model,
    sign: rl.Model,
    electricity: rl.Model,
    electricity_r: rl.Model,
    track_bent: rl.Model,
    track_bottom: rl.Model,
    track_bent_r: rl.Model,
    mountains: rl.Model,
    scene: rl.Model,
};
pub const cameras_config = struct {
    current_camera: u7,
    front_camera: rl.Camera3D,
    top_view_camera: rl.Camera3D,
};
pub const audios_config = struct {
    rainMusic: rl.Music,
    lightning: rl.Sound,
    trainMusic: rl.Music,
    horn: rl.Music,
};

pub const rain_config = struct {
    x: i8 = -10,
    y: i8 = 10,
};

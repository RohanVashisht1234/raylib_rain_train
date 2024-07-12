pub const screenWidth: u11 = 1080;
pub const screenHeight: u11 = 720;

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

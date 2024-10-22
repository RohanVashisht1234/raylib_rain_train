const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");

pub fn load3DModels() constants.models_config {
    return constants.models_config{
        .red_signal = rl.loadModel("./assets/red_signal.glb"),
        .green_signal = rl.loadModel("./assets/green_signal.glb"),
        .terrain = rl.loadModel("./assets/terrain.glb"),
        .tree = rl.loadModel("./assets/tree.glb"),
        .track = rl.loadModel("./assets/track.glb"),
        .train = rl.loadModel("./assets/train.glb"),
        .train_station = rl.loadModel("./assets/train_station.glb"),
        .sign = rl.loadModel("./assets/sign.glb"),
        .electricity = rl.loadModel("./assets/electricity.glb"),
        .electricity_r = rl.loadModel("./assets/electricity_r.glb"),
        .track_bent = rl.loadModel("./assets/track_bent.glb"),
        .track_bottom = rl.loadModel("./assets/track_bottom.glb"),
        .track_bent_r = rl.loadModel("./assets/track_bent_r.glb"),
        .mountains = rl.loadModel("./assets/mountains.glb"),
        .scene = rl.loadModel("./assets/scene.glb"),
    };
}

pub fn unload3DModels(models: constants.models_config) void {
    rl.unloadModel(models.red_signal);
    rl.unloadModel(models.green_signal);
    rl.unloadModel(models.terrain);
    rl.unloadModel(models.tree);
    rl.unloadModel(models.track);
    rl.unloadModel(models.train);
    rl.unloadModel(models.train_station);
    rl.unloadModel(models.sign);
    rl.unloadModel(models.electricity);
    rl.unloadModel(models.electricity_r);
    rl.unloadModel(models.track_bent);
    rl.unloadModel(models.track_bottom);
    rl.unloadModel(models.track_bent_r);
    rl.unloadModel(models.mountains);
    rl.unloadModel(models.scene);
}

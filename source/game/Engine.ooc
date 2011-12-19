
// game deps
import ui/MainUI
import game/[Level, LevelLoader]

// libs deps
import gtk/Gtk // for timeouts
use zombieconfig
import zombieconfig

Engine: class {

    ui: MainUI
    level: Level

    FPS := 30.0 // let's target 30FPS

    init: func(config: ZombieConfig) {
        ui = MainUI new(config)
        load(config["startLevel"])

        // doing a fixed delta for now
        delta := 1000.0 / FPS
        Gtk addTimeout(delta, ||
            level update(1.0)
            true // so the callback gets ran again
        )

        ui run()
    }

    load: func (levelName: String) {
        if (level) {
            ui reset()
        }

        loader := LevelLoader new(this)
        level = loader load(levelName)
        ui level = level
    }

}



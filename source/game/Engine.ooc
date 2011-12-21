
// game deps
import ui/MainUI
import game/[Level, LevelLoader]

// libs deps
import sdl/Sdl // for timeouts
use zombieconfig
import zombieconfig

Engine: class {

    ui: MainUI
    level: Level

    FPS := 30.0 // let's target 30FPS

    init: func(config: ZombieConfig) {
        ui = MainUI new(config)
        load(config["startLevel"])

        // main loop
        ticks: Int
        delta := 1000.0 / 30.0 // try 30FPS

        while (true) {
            ticks = SDL getTicks()

            level update(1.0)
            ui redraw()

            // teleport ourselves in
            // the future when the next frame is due
            roadToFuture := ticks + delta - SDL getTicks()
            if(roadToFuture > 0) {
                SDL delay(roadToFuture)
            }
        }
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



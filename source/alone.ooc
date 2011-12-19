
// libs deps
use zombieconfig, deadlogger
import zombieconfig
import deadlogger/[Log, Handler, Formatter, Filter]

// game deps
import ui/[MainUI]
import game/[Engine, Level, LevelLoader]

main: func {
    // setup logging
    console := StdoutHandler new()
    console setFormatter(ColoredFormatter new(NiceFormatter new()))
    Log root attachHandler(console)
   
    // load config
    config := ZombieConfig new("alone.config", |base|
        base("screenWidth", "1024")
        base("screenHeight", "768")
        base("startLevel", "level1")
    )

    // create main ui, initialize engine
    ui := MainUI new(config)
    engine := Engine new(ui)

    loader := LevelLoader new(engine)


    level: Level
    level = loader load("assets/levels/%s.json" format(config["startLevel"]))
    ui level = level

    level start()
}


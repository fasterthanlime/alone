
// libs deps
use zombieconfig, deadlogger
import zombieconfig
import deadlogger/[Log, Handler, Level, Formatter, Filter]

// game deps
import ui/MainUI
import game/[Engine, Level]

main: func {
    // setup logging
    console := StdoutHandler new()
    console setFormatter(ColoredFormatter new(NiceFormatter new()))
    Log root attachHandler(console)
   
    // load config
    config := ZombieConfig new("alone.config", |base|
        base("screenWidth", "1024")
        base("screenHeight", "768")
    )

    // create main ui, initialize engine
    ui := MainUI new(config)
    engine := Engine new(ui)
    level := Level new(engine)

    level start()
}



// libs deps
use zombieconfig, deadlogger
import zombieconfig
import deadlogger/[Log, Handler, Formatter, Filter]

// game deps
import ui/[MainUI]
import game/[Engine, Level, LevelLoader]

main: func (argc: Int, argv: CString*) {
    // setup logging
    console := StdoutHandler new()
    console setFormatter(ColoredFormatter new(NiceFormatter new()))
    Log root attachHandler(console)
   
    // load config
    config := ZombieConfig new("alone.config", |base|
        base("fullScreen", "false")
        base("screenWidth", "1024")
        base("screenHeight", "768")
        base("startLevel", "level1")
    )

    Engine new(config)
}


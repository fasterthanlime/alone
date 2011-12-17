
// libs deps
use zombieconfig
import zombieconfig

// game deps
import ui/MainUI
import game/[Engine, Level]

main: func {
    config := ZombieConfig new("alone.config", |base|
        base("screenWidth", "1024")
        base("screenHeight", "768")
    )

    ui := MainUI new(config)

    engine := Engine new(ui)
    level := Level new(engine)

    level start()
}


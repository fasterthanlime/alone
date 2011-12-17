use zombieconfig
import zombieconfig

import ui/MainUI

main: func {
    config := ZombieConfig new("alone.config", |base|
        base("screenWidth", "1024")
        base("screenHeight", "768")
    )

    ui := MainUI new(config)
    ui run()
}



// game deps
import ui/[MainUI, Input, Sprite]
import game/[Level, Platform, Hero, Camera]
import Editor
import math/[Vec2]

// libs deps
import deadlogger/Log
import cairo/[Cairo, GdkCairo] 
import structs/[HashMap, ArrayList]

EditMode: class {

    editor: Editor
    enabled := false

    init: func (=editor) {}

    update: func (delta: Float) {
        // update stuff there
    }

    enter: func {
        // set up stuff when we enter this mode
    }

    leave: func {
        // clean up stuff to leave this mode
    }

    name: String {
        get {
            getName()
        }
    }

    paint: func (cr: Context) {
        // paint custom ui here
    }

    getName: func -> String {
        "<edit mode name>"
    }

}

IdleMode: class extends EditMode {

    init: super func

    // nothing to do man. It's idle time!
    getName: func -> String { "Idle" }

    paint: func (cr: Context) {
        cr moveTo(200, 500)
        cr setFontSize(20.0)
        cr showText("Welcome to the editor")
        cr moveTo(200, 540)
        cr showText("Press 'e' to enter drop mode where you can create objects")
    }

}

Droppable: class {

    INF := -10000000000.0 // probably not in the level ;)
    mode: DropMode

    init: func (=mode) { }

    enter: func { }
    leave: func { }
    update: func { }
    drop: func { }

    getName: func -> String { "<droppable>" }

}

PlatformDroppable: class extends Droppable {

    plat: Platform
    kind: String

    init: func (=mode, =kind) {
        plat = Platform new(mode level, vec2(INF), kind)
        plat mainSprite alpha = 0.0
        mode level actors add(plat)
    }

    update: func {
        plat pos set!(mode snap(mode level camera mouseworldpos, 50, 40))
    }

    enter: func {
        plat mainSprite alpha = 0.5
    }

    leave: func {
        plat pos set!(INF, INF)
        plat mainSprite alpha = 0.0
    }

    drop: func {
        platform := Platform new(mode level, vec2(plat pos), plat kind)
        mode level actors add(platform)
    }

    getName: func -> String { kind + " platform" }

}

StartPoint: class extends Droppable {

    label: LabelSprite

    init: func (=mode) {
        label = LabelSprite new(getName()) 
    }

    drop: func {
        // TODO
    }

    enter: func {
        // TODO
    }

    leave: func {
        // TODO
    }

    getName: func -> String { "start point" }

}

DropMode: class extends EditMode {

    snappy := true
    enabled := false

    level: Level

    droppables := ArrayList<Droppable> new()
    droppable: Droppable
    index := 0

    init: func (=editor) {
        level = editor level

        editor input onMousePress(Buttons LEFT, || 
            if (!enabled) return

            droppable drop()
        )

        editor input onKeyPress(Keys ESC, ||
            if (!enabled) return

            editor change(editor IDLE)
        )

        editor input onKeyPress(Keys RIGHT, ||
            if (!enabled) return

            index = (index + 1) % droppables size
            droppable leave()
            droppable = droppables[index]
            droppable enter()
        )

        initDroppables()
    }

    initDroppables: func {
        // TODO: read this from files instead
        droppables add(PlatformDroppable new(this, "metal"))
        droppables add(PlatformDroppable new(this, "wood"))
        droppables add(PlatformDroppable new(this, "glass"))
        droppables add(StartPoint new(this))

        droppable = droppables[0]
        droppable enter()
    }

    update: func (delta: Float) {
        droppable update()
    }

    paint: func (cr: Context) {
        cr moveTo(200, 500)
        cr setFontSize(20.0)
        cr showText("Left click to drop a '%s'" format(droppable getName()))
        cr moveTo(200, 540)
        cr showText("Keyboard arrows to cycle between object kinds")
    }

    snap: func (v: Vec2, snapX, snapY: Int) -> Vec2 {
        if(!snappy) {
            v
        } else {
            vec2(
                v x - (v x as Int % snapX),
                v y - (v y as Int % snapY)
            )
        }
    }

    enter: func {
        droppable enter()
        enabled = true
    }

    leave: func {
        droppable leave()
        enabled = false
    }

    getName: func -> String { "Drop" }
}





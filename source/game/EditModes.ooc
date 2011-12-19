
// game deps
import ui/[MainUI, Input, Sprite]
import game/[Level, Platform, Hero, Camera]
import Editor
import math/[Vec2, Vec3]

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

    globalEnter: func { }
    globalLeave: func { }
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
        plat mainSprite visible = false
        plat mainSprite alpha = 0.5
        // don't add ghost platforms to the level! We don't
        // want them saved :)
    }

    update: func {
        plat pos set!(mode snap(mode level camera mouseworldpos, 50, 40))
    }

    enter: func {
        plat mainSprite visible = true
    }

    leave: func {
        plat pos set!(INF, INF)
        plat mainSprite visible = false
    }

    drop: func {
        platform := Platform new(mode level, vec2(plat pos), plat kind)
        mode level platforms add(platform)
    }

    getName: func -> String { kind + " platform" }

}

StartPoint: class extends Droppable {

    label: LabelSprite
    pointer: EllipseSprite

    init: func (=mode) {
        pointer = EllipseSprite new(vec2(mode level startPos))
        pointer color = vec3(0.3, 0.3, 1.0)
        pointer radius = 40
        pointer filled = false
        pointer thickness = 10.0
        pointer visible = false
        mode level fgSprites add(pointer)

        label = LabelSprite new(vec2(mode level startPos), "start") 
        label fontSize = 38
        label centered = true
        label visible = false
        mode level fgSprites add(label)
    }

    update: func {
        pointer pos set!(mode level camera mouseworldpos)
    }

    drop: func {
        label pos set!(pointer pos)
        mode level startPos set!(pointer pos)
    }

    globalEnter: func {
        label visible = true
    }

    globalLeave: func {
        label visible = false
    }

    enter: func {
        pointer visible = true
    }

    leave: func {
        pointer visible = false
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

        editor input onMousePress(Buttons RIGHT, ||
            if (!enabled) return
            change(index + 1)
        )

        editor input onKeyPress(Keys ESC, ||
            if (!enabled) return
            editor change(editor IDLE)
        )

        editor input onKeyPress(Keys RIGHT, ||
            if (!enabled) return
            change(index + 1)
        )

        editor input onKeyPress(Keys LEFT, ||
            if (!enabled) return
            change(index - 1)
        )

        initDroppables()
    }

    change: func (pIndex: Int) {
        numDroppables := droppables size
        if (pIndex < 0)                pIndex += numDroppables
        if (pIndex >= droppables size) pIndex -= numDroppables
        index = pIndex

        droppable leave()
        droppable = droppables[index]
        droppable enter()
    }

    initDroppables: func {
        // TODO: read this from files instead
        droppables add(StartPoint new(this))
        droppables add(PlatformDroppable new(this, "metal"))
        droppables add(PlatformDroppable new(this, "wood"))
        droppables add(PlatformDroppable new(this, "glass"))

        droppable = droppables[0]
        droppable enter()
    }

    update: func (delta: Float) {
        if (!enabled) return

        snappy = !editor input isPressed(Keys ALT)
        droppable update()
    }

    paint: func (cr: Context) {
        cr moveTo(200, 500)
        cr setFontSize(20.0)
        cr showText("Left click = place an element")
        cr moveTo(200, 540)
        cr showText("Right click = cycle between droppables")
        cr moveTo(200, 580)
        cr showText("Alt = unsnap from the grid")

        cr moveTo(400, 100)
        cr setSourceRGB(0.3, 1.0, 0.3)
        cr setFontSize(40.0)
        cr showText("[%s]" format(droppable getName()))
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
        droppables each(|drop| drop globalEnter())

        enabled = true
    }

    leave: func {
        droppable leave()
        droppables each(|drop| drop globalLeave())

        enabled = false
    }

    getName: func -> String { "Drop" }
}






// game deps
import ui/[MainUI, Input, Sprite]
import game/[Level, Platform, Hero, Camera, Vacuum]
import Editor, LevelSaver, LevelLoader
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/[Cairo, GdkCairo] 
import structs/[HashMap, ArrayList]

EditMode: class {

    editor: Editor

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

// text box for input
textInput: func (editor: Editor, titleText, initial: String, cb: Func (String)) {

    ui := editor ui
    level := editor level

    marginX := 60.0
    outlineHeight := 200.0
    height := 50

    controls := GroupSprite new()
    editor sprites add(controls)

    outline := RectSprite new(vec2(ui width / 2, ui height / 2))
    outline size = vec2(ui width - marginX, outlineHeight)
    outline alpha = 0.8
    outline color = vec3(0, 0, 0)
    controls add(outline)

    title := LabelSprite new(vec2(marginX + 5, ui height / 2 - height / 2 - 22), titleText)
    title fontSize = 44.0
    title color = vec3(0.8, 0.8, 0.8)
    controls add(title)

    box := RectSprite new(vec2(ui width / 2, ui height / 2))
    box filled = false
    box thickness = 1.0
    box size = vec2(ui width - 2 * marginX, height)
    box color = vec3(0.1, 0.1, 0.1)
    controls add(box)

    boxbg := RectSprite new(vec2(ui width / 2, ui height / 2))
    boxbg size = vec2(ui width - 2 * marginX, height)
    boxbg color = vec3(1.0, 1.0, 1.0)
    boxbg alpha = 0.8
    controls add(boxbg)

    value := initial _buffer clone(1024)

    text := LabelSprite new(vec2(marginX + 5, ui height / 2 - height / 2 + 42), value toString())
    text fontSize = 44.0
    text color = vec3(0.1, 0.1, 0.1)
    controls add(text)

    input := editor input sub()
    input grab(input onEvent(|ev|
        match (ev) {
            case kp: KeyPress =>
                if (kp code == Keys ESC || kp code == Keys ENTER) {
                    input ungrab(). nuke()
                    editor sprites remove(controls)
                    if(kp code == Keys ENTER) {
                        cb(value toString())
                    }
                } else if (kp code >= 32 && kp code <= 126) {
                    value append(kp code as Char)
                    text text = value toString()
                } else if(kp code == Keys BACKSPACE) {
                    if (value size > 0) {
                        value setLength(value size - 1)
                    }
                }
        }
    ))
}

IdleMode: class extends EditMode {

    input: Proxy

    init: func (=editor) {
        input = editor input sub()

        input onKeyPress(Keys F1, ||
            // F1 = load
            textInput(editor, "Load level", editor levelName, |response|
                "Trigger reload of %s" printfln(response)
                editor level engine load(response)
            )
        )

        input onKeyPress(Keys F2, ||
            // F2 = save
            textInput(editor, "Save level", editor levelName, |response|
                editor levelName = response
                saver := LevelSaver new()
                saver save(editor level, editor levelName)
            )
        )

        input onKeyPress(Keys E, ||
            editor change(editor DROP)
        )
    }

    enter: func {
        input enabled = true
    }

    leave: func {
        input enabled = false
    }

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

VacuumDroppable: class extends Droppable {

    vacuum: Vacuum

    init: func (=mode) {
        vacuum = Vacuum new(mode level, vec2(INF), 2.12)
    }

    enter: func {
        vacuum mainSprite visible = true
    }

    leave: func {
        vacuum mainSprite visible = false
    }

    getName: func -> String { "vacuum" }

}

StartPoint: class extends Droppable {

    label: LabelSprite
    pointer: EllipseSprite

    input: Proxy

    init: func (=mode) {
        input = mode input sub()

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

        input onMouseDrag(Buttons LEFT, ||
            drop()
        )
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
        input enabled = true
        pointer visible = true
    }

    leave: func {
        input enabled = false
        pointer visible = false
    }

    getName: func -> String { "start point" }

}

DropMode: class extends EditMode {

    snappy := true

    level: Level

    droppables := ArrayList<Droppable> new()
    droppable: Droppable
    index := 0

    input: Proxy

    init: func (=editor) {
        input = editor input sub()
        level = editor level

        input onMousePress(Buttons LEFT, || 
            droppable drop()
        )

        input onMousePress(Buttons RIGHT, ||
            change(index + 1)
        )

        input onKeyPress(Keys ESC, ||
            editor change(editor IDLE)
        )

        input onKeyPress(Keys RIGHT, ||
            change(index + 1)
        )

        input onKeyPress(Keys LEFT, ||
            change(index - 1)
        )

        input enabled = false

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
        droppables add(VacuumDroppable new(this))
        droppables add(PlatformDroppable new(this, "metal"))
        droppables add(PlatformDroppable new(this, "wood"))
        droppables add(PlatformDroppable new(this, "glass"))

        droppable = droppables[0]
    }

    update: func (delta: Float) {
        snappy = !input isPressed(Keys ALT)
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

        input enabled = true
    }

    leave: func {
        droppable leave()
        droppables each(|drop| drop globalLeave())

        input enabled = false
    }

    getName: func -> String { "Drop" }
}





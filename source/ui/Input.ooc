
/*
 * Input system.
 * 
 * We don't rely too much on GDK stuff, we have our
 * own event classes, so it might be kinda not suicidal-hard
 * to port it to another windowing/event system.
 */

// libs deps
import deadlogger/Log
import structs/[ArrayList]
import gtk/[Widget, Window]
import gdk/[Event]

// game deps
import ui/[MainUI]
import math/[Vec2]

/*
 * Key codes
 */
Keys: enum from UInt {
    LEFT  = 65361
    RIGHT = 65363
    SPACE = 32
}

/*
 * Mouse button codes
 */
Buttons: enum from UInt {
    LEFT   = 1
    MIDDLE = 2
    RIGHT  = 3
}

Event: class {

}

MouseEvent: class extends Event {

    pos: Vec2
    
    init: func (=pos)

}

/*
 * Mouse button pressed (!= mouse click)
 */
MousePress: class extends MouseEvent {

    button: Int

    init: func (=pos, =button)

}

/*
 * Mouse button released. Note: release events
 * are not guaranteed to happen, e.g. if the
 * window loses focus before the user releases
 * the mouse button you're out of luck. You might
 * want to have a backup strategy
 */
MouseRelease: class extends MouseEvent {

    button: Int

    init: func (=pos, =button)

}

KeyboardEvent: class extends Event {

    code: UInt
    init: func (=code) {}

}

KeyPress: class extends KeyboardEvent {

    init: super func

}

KeyRelease: class extends KeyboardEvent {
   
    init: super func

}

Listener: class {

    onEvent: Func(Event)

    init: func (=onEvent) {}

}

Input: class {

    logger := static Log getLogger(This name)
    listeners := ArrayList<Listener> new()

    MAX_KEY := static 65536
    keyState: Bool*

    debug := false

    ui: MainUI
    win: Window

    mousepos := vec2(0.0, 0.0)

    init: func (=ui) {
        win = ui win
        keyState = gc_malloc(Bool size * MAX_KEY)

        // make sure gdk sends us all the right events
        win addEvents(GdkEventMask POINTER_MOTION_MASK)
        win addEvents(GdkEventMask BUTTON_PRESS_MASK)

        // register all event listeners
        win connectKeyEvent("key-press-event",     |ev| keyPressed (ev))
        win connectKeyEvent("key-release-event",   |ev| keyReleased(ev))
        win connectKeyEvent("motion-notify-event", |ev| mouseMoved(ev))
        win connectKeyEvent("button-press-event",  |ev| mousePressed(ev))

        logger info("Input system initialized")
    }

    keyPressed: func (ev: EventKey*) {
        if(debug) {
            logger debug("Key pressed! it's state %d, key %u" format(ev@ state, ev@ keyval))
        }
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = true
            notifyListeners(KeyPress new(ev@ keyval))
        }
    }

    keyReleased: func (ev: EventKey*) {
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = false
            notifyListeners(KeyRelease new(ev@ keyval))
        }
    }

    mouseMoved: func (ev: EventMotion*) {
        (mousepos x, mousepos y) = (ev@ x, ev@ y)
    }

    mousePressed: func (ev: EventButton*) {
        logger debug("Mouse pressed at %s" format(mousepos _))
        notifyListeners(MousePress new(mousepos, ev@ button))
    }

    isPressed: func (keyval: Int) -> Bool {
        if (keyval >= MAX_KEY) {
            return false
        }
        keyState[keyval]
    }

    notifyListeners: func (ev: Event) {
        listeners each(|l| l onEvent(ev))
    }

}


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


/*
 * Func is a weird type, better wrap it in a class
 */
Listener: class {

    cb: Func(Event)
    init: func (=cb) {}

}

Input: class {

    logger := static Log getLogger(This name)
    listeners := ArrayList<Listener> new()

    MAX_KEY := static 65536
    keyState: Bool*

    debug := true

    ui: MainUI
    win: Window

    mousepos := vec2(0.0, 0.0)

    init: func (=ui) {
        win = ui win
        keyState = gc_malloc(Bool size * MAX_KEY)
        _connectEvents()

        logger info("Input system initialized")
    }

    /**
     * Register for an event listener. You can
     * then match on its type to see which event
     * it is.
     */
    onEvent: func (cb: Func(Event)) {
        listeners add(Listener new(cb))
    }

    onKeyPress: func (which: UInt, cb: Func) {
        onEvent(|ev|
            match (ev) {
                case kp: KeyPress => 
                    if(kp code == which) cb()
            }
        )
    }

    /**
     * Return the state of a key (true = pressed,
     * false = released) at any time.
     */
    isPressed: func (keyval: Int) -> Bool {
        if (keyval >= MAX_KEY) {
            return false
        }
        keyState[keyval]
    }

    // --------------------------------
    // private functions below
    // --------------------------------

    _connectEvents: func {
        // make sure gdk sends us all the right events
        win addEvents(GdkEventMask POINTER_MOTION_MASK)
        win addEvents(GdkEventMask BUTTON_PRESS_MASK)

        // register all event listeners
        win connectKeyEvent("key-press-event",     |ev| _keyPressed (ev))
        win connectKeyEvent("key-release-event",   |ev| _keyReleased(ev))
        win connectKeyEvent("motion-notify-event", |ev| _mouseMoved(ev))
        win connectKeyEvent("button-press-event",  |ev| _mousePressed(ev))
    }

    _keyPressed: func (ev: EventKey*) {
        if(debug) {
            logger debug("Key pressed! it's state %d, key %u" format(ev@ state, ev@ keyval))
        }
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = true
            _notifyListeners(KeyPress new(ev@ keyval))
        }
    }

    _keyReleased: func (ev: EventKey*) {
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = false
            _notifyListeners(KeyRelease new(ev@ keyval))
        }
    }

    _mouseMoved: func (ev: EventMotion*) {
        (mousepos x, mousepos y) = (ev@ x, ev@ y)
    }

    _mousePressed: func (ev: EventButton*) {
        logger debug("Mouse pressed at %s" format(mousepos _))
        _notifyListeners(MousePress new(mousepos, ev@ button))
    }

    _notifyListeners: func (ev: Event) {
        listeners each(|l| l cb(ev))
    }

}


/*
 * Key codes
 * TODO: have them all?
 */
Keys: enum from UInt {
    LEFT  = 65361
    RIGHT = 65363
    SPACE = 32
    F1    = 65470
    F2    = 65471
    F3    = 65472
    F4    = 65473
    F5    = 65474
    F6    = 65475
    F7    = 65476
    F8    = 65477
    F9    = 65478
    F10   = 65479
    F11   = 65480
    F12   = 65481
    W     = 119
    A     = 97
    S     = 115
    D     = 100
}

/*
 * Mouse button codes
 */
Buttons: enum from UInt {
    LEFT   = 1
    MIDDLE = 2
    RIGHT  = 3
}


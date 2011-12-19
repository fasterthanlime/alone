
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

MouseMotion: class extends MouseEvent {

    init: super func

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

Proxy: abstract class {

    logger := static Log getLogger(This name)

    listeners := ArrayList<Listener> new()
    _grab: Listener

    mousepos: Vec2 {
        get { getMousePos() }
    }

    getMousePos: abstract func -> Vec2

    enabled := true

    /**
     * Register for an event listener. You can
     * then match on its type to see which event
     * it is.
     */
    onEvent: func (cb: Func(Event)) -> Listener {
        listener := Listener new(cb)
        listeners add(listener)
        listener
    }

    onKeyPress: func (which: UInt, cb: Func) {
        onEvent(|ev|
            match (ev) {
                case kp: KeyPress => 
                    if(kp code == which) cb()
            }
        )
    }

    onMousePress: func (which: UInt, cb: Func) {
        onEvent(|ev|
            match (ev) {
                case mp: MousePress =>
                    if(mp button == which) cb()
            }
        )
    }

    onMouseDrag: func (which: UInt, cb: Func) {
        onEvent(|ev|
            match (ev) {
                case mm: MouseMotion =>
                    if(isButtonPressed(which)) {
                        // it's a drag!
                        cb()
                    }
            }
        )
    }

    /**
     * Return the state of a key (true = pressed,
     * false = released) at any time.
     */
    isPressed: abstract func (keyval: Int) -> Bool

    isButtonPressed: abstract func (button: Int) -> Bool

    grab: func (l: Listener) {
        listeners remove(l)
        _grab = l
    }

    ungrab: func {
        _grab = null
    }

    sub: func -> SubProxy {
        SubProxy new(this)
    }

    nuke: func {
        // not much to do here
    }

    //---------------
    // private stuff
    //---------------

    _notifyListeners: func (ev: Event) {
        if (!enabled) return

        if (_grab) {
            _grab cb(ev)
        } else {
            listeners each(|l| l cb(ev))
        }
    }

}

SubProxy: class extends Proxy {

    own: Listener
    parent: Proxy

    init: func (=parent) {
        own = parent onEvent(|ev|
            _notifyListeners(ev)
        )
    }

    isPressed: func (keyval: Int) -> Bool {
        parent isPressed(keyval)
    }

    isButtonPressed: func (button: Int) -> Bool {
        parent isButtonPressed(button)
    }

    grab: func (l: Listener) {
        listeners remove(l)
        _grab = l
        parent grab(l)
    }

    ungrab: func {
        _grab = null
        parent ungrab()
    }

    getMousePos: func -> Vec2 {
        parent mousepos
    }

    nuke: func {
        parent listeners remove(own)
    }

}

Input: class extends Proxy {

    logger := static Log getLogger(This name)

    MAX_KEY := static 65536
    keyState: Bool*

    MAX_BUTTON := static 6
    buttonState: Bool*

    debug := true

    ui: MainUI
    win: Window

    _mousepos := vec2(0.0, 0.0)

    init: func (=ui) {
        win = ui win
        keyState = gc_malloc(Bool size * MAX_KEY)
        buttonState = gc_malloc(Bool size * MAX_BUTTON)

        _connectEvents()

        logger info("Input system initialized")
    }

    isPressed: func (keyval: Int) -> Bool {
        if (keyval >= MAX_KEY) {
            return false
        }
        // TODO: this is problematic - what if the
        // grabbed listener wants to know?
        if (_grab) {
            return false
        }
        keyState[keyval]
    }

    isButtonPressed: func (button: Int) -> Bool {
        if (button >= MAX_BUTTON) {
            return false
        }
        if (_grab) {
            return false
        }
        buttonState[button]
    }

    // --------------------------------
    // private functions below
    // --------------------------------

    _connectEvents: func {
        // make sure gdk sends us all the right events
        win addEvents(GdkEventMask POINTER_MOTION_MASK)
        win addEvents(GdkEventMask BUTTON_PRESS_MASK)
        win addEvents(GdkEventMask BUTTON_RELEASE_MASK)

        // register all event listeners
        win connectKeyEvent("key-press-event",       |ev| _keyPressed (ev))
        win connectKeyEvent("key-release-event",     |ev| _keyReleased(ev))
        win connectKeyEvent("motion-notify-event",   |ev| _mouseMoved(ev))
        win connectKeyEvent("button-press-event",    |ev| _mousePressed(ev))
        win connectKeyEvent("button-release-event",  |ev| _mouseReleased(ev))
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
        (_mousepos x, _mousepos y) = (ev@ x, ev@ y)
        _notifyListeners(MouseMotion new(_mousepos))
    }

    _mousePressed: func (ev: EventButton*) {
        logger debug("Mouse pressed at %s" format(_mousepos _))
        buttonState[ev@ button] = true
        _notifyListeners(MousePress new(_mousepos, ev@ button))
    }

    _mouseReleased: func (ev: EventButton*) {
        logger debug("Mouse released at %s" format(_mousepos _))
        buttonState[ev@ button] = false
        _notifyListeners(MouseRelease new(_mousepos, ev@ button))
    }

    getMousePos: func -> Vec2 {
        _mousepos
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
    ENTER = 65293
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
    A     = 97
    B     = 98
    C     = 99
    D     = 100
    E     = 101
    F     = 102
    G     = 103
    H     = 104
    I     = 105
    J     = 106
    K     = 107
    L     = 108
    M     = 109
    N     = 110
    O     = 111
    P     = 112
    Q     = 113
    R     = 114
    S     = 115
    T     = 116
    U     = 117
    V     = 118
    W     = 119
    X     = 120
    Y     = 121
    Z     = 122
    ESC   = 65307
    ALT   = 65513
    CTRL  = 65505
    BACKSPACE = 65288
}

/*
 * Mouse button codes
 */
Buttons: enum from UInt {
    LEFT   = 1
    MIDDLE = 2
    RIGHT  = 3
}


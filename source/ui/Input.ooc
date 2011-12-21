
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
import sdl/[Sdl, Event]

// game deps
import ui/[MainUI]
import math/[Vec2]

LEvent: class {

}

MouseEvent: class extends LEvent {

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

KeyboardEvent: class extends LEvent {

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

    cb: Func(LEvent)
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
    onEvent: func (cb: Func(LEvent)) -> Listener {
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

    onKeyRelease: func (which: UInt, cb: Func) {
        onEvent(|ev|
            match (ev) {
                case kr: KeyRelease => 
                    if(kr code == which) cb()
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

    onMouseRelease: func (which: UInt, cb: Func) {
        onEvent(|ev|
            match (ev) {
                case mp: MouseRelease =>
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

    _notifyListeners: func (ev: LEvent) {
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

    debug := false

    ui: MainUI

    _mousepos := vec2(0.0, 0.0)

    init: func (=ui) {
        keyState = gc_malloc(Bool size * MAX_KEY)
        buttonState = gc_malloc(Bool size * MAX_BUTTON)

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

    _poll: func {
        event: Event

        while(SDLEvent poll(event&)) {
            match (event type) {
                case SDL_KEYDOWN => _keyPressed (event key keysym sym)
                case SDL_KEYUP   => _keyReleased(event key keysym sym)
                case SDL_MOUSEBUTTONUP   => _mouseReleased(event button button)
                case SDL_MOUSEBUTTONDOWN => _mousePressed (event button button)
                case SDL_MOUSEMOTION => _mouseMoved (event motion x, event motion y)
                case SDL_QUIT => ui quit()
            }
        }
    }

    disconnect: func {
        // useless, we'll just stop polling.
    }

    _keyPressed: func (keyval: Int) {
        if(debug) {
            logger debug("Key pressed! it's state %d, key %u" format(keyval))
        }
        if (keyval < MAX_KEY) {
            keyState[keyval] = true
            _notifyListeners(KeyPress new(keyval))
        }
    }

    _keyReleased: func (keyval: Int) {
        if (keyval < MAX_KEY) {
            keyState[keyval] = false
            _notifyListeners(KeyRelease new(keyval))
        }
    }

    _mouseMoved: func (x, y: Int) {
        (_mousepos x, _mousepos y) = (x as Float, y as Float)
        _notifyListeners(MouseMotion new(_mousepos))
    }

    _mousePressed: func (button: Int) {
        logger debug("Mouse pressed at %s" format(_mousepos _))
        buttonState[button] = true
        _notifyListeners(MousePress new(_mousepos, button))
    }

    _mouseReleased: func (button: Int) {
        logger debug("Mouse released at %s" format(_mousepos _))
        buttonState[button] = false
        _notifyListeners(MouseRelease new(_mousepos, button))
    }

    getMousePos: func -> Vec2 {
        _mousepos
    }

}


/*
 * Key codes
 * TODO: have them all?
 */
Keys: enum from Int {
    LEFT  = SDLK_LEFT
    RIGHT = SDLK_RIGHT
    SPACE = SDLK_SPACE
    ENTER = SDLK_RETURN
    F1    = SDLK_F1
    F2    = SDLK_F2
    F3    = SDLK_F3
    F4    = SDLK_F4
    F5    = SDLK_F5
    F6    = SDLK_F6
    F7    = SDLK_F7
    F8    = SDLK_F8
    F9    = SDLK_F9
    F10   = SDLK_F10
    F11   = SDLK_F11
    F12   = SDLK_F12
    A     = SDLK_a
    B     = SDLK_b
    C     = SDLK_c
    D     = SDLK_d
    E     = SDLK_e
    F     = SDLK_f
    G     = SDLK_g
    H     = SDLK_h
    I     = SDLK_i
    J     = SDLK_j
    K     = SDLK_k
    L     = SDLK_l
    M     = SDLK_m
    N     = SDLK_n
    O     = SDLK_o
    P     = SDLK_p
    Q     = SDLK_q
    R     = SDLK_r
    S     = SDLK_s
    T     = SDLK_t
    U     = SDLK_u
    V     = SDLK_v
    W     = SDLK_w
    X     = SDLK_x
    Y     = SDLK_y
    Z     = SDLK_z
    ESC   = SDLK_ESCAPE
    ALT   = SDLK_LALT // opinionated, but meh.
    CTRL  = SDLK_LCTRL
    BACKSPACE = SDLK_BACKSPACE
}

/*
 * Mouse button codes
 */
Buttons: enum from Int {
    LEFT   = SDL_BUTTON_LEFT
    MIDDLE = SDL_BUTTON_MIDDLE
    RIGHT  = SDL_BUTTON_RIGHT
}


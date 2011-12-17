use cairo, gtk

// game deps
import Sprite

// libs deps
import cairo/[Cairo, GdkCairo] 
import gtk/[Gtk, Widget, Window]
import gdk/[Event]
import structs/[ArrayList]
import zombieconfig

Keys: enum from UInt {
    LEFT  = 65361
    RIGHT = 65363
}

MainUI: class {
    win: Window

    width, height: Int

    sprites := ArrayList<Sprite> new()

    MAX_KEY := static 65536
    keyState: Bool*

    init: func (config: ZombieConfig) {
        keyState = gc_malloc(Bool size * MAX_KEY)
        win = Window new(config["title"])

        width  = config["screenWidth"] toInt()
        height = config["screenHeight"] toInt()
        win setUSize(width as GInt, height as GInt)
        win setPosition(Window POS_CENTER)

        win connect("delete-event", exit) // exit on window close

        // redraw on each window move, possibly before!
        win connect("expose-event", || draw())
        win connectKeyEvent("key-press-event",   |ev| keyPressed (ev))
        win connectKeyEvent("key-release-event", |ev| keyReleased(ev))

        win showAll()
    }

    run: func {
        Gtk main()
    }

    keyPressed: func (ev: EventKey*) {
        "Key pressed! it's state %d, key %u" printfln(ev@ state, ev@ keyval)
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = true
        }
    }

    keyReleased: func (ev: EventKey*) {
        "Key released! it's state %d, key %u" printfln(ev@ state, ev@ keyval)
        if (ev@ keyval < MAX_KEY) {
            keyState[ev@ keyval] = false
        }
    }

    isPressed: func (keyval: Int) -> Bool {
        if (keyval >= MAX_KEY) {
            return false
        }
        keyState[keyval]
    }

    redraw: func {
        gdkWin := win getWindow()
        gdkWin invalidateRegion(gdkWin getClipRegion(), false)
    }

    draw: func {
        gdkWin := win getWindow()
        cr := GdkContext new(gdkWin)
        paint(cr)
        cr destroy()
    }

    paint: func (cr: Context) {
        background(cr)
        sprites each(|sprite|
            sprite draw(cr)
        )
    }

    background: func (cr: Context) {
        cr setSourceRGB(0, 0, 0)
        cr paint()
    }

    triangle: func (cr: Context) {
        cr setLineWidth(15)
        cr setSourceRGB(255, 0, 0)
        cr moveTo(0, 0)
        cr lineTo(width / 2, height)
        cr relLineTo(width / 2, -height)
        cr closePath()
        cr stroke()
    }

}

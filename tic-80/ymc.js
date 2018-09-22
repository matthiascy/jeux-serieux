// script: js

/**
 * Vector
 */
function Vec2(x, y) {
    if (y == undefined) {
        this.x = x;
        this.y = x;
    } else {
        this.x = x;
        this.y = y;
    }
}

Object.defineProperties(Vec2.prototype, {
    "w": {

        get: function() {
            return this.x;
        },

        set: function(val) {
            this.x = val;
        }
    },

    "h": {

        get: function() {
            return this.y;
        },

        set: function(val) {
            this.y = val;
        }
    }
});

Object.assign(Vec2.prototype, {
    set: function(x, y) {
        if (y == undefined) {
            this.x = x;
            this.y = x;
        } else {
            this.x = x;
            this.y = y;
        }

        return this;
    },

    clone: function() {
        return new this.constructor(this.x, this.y);
    },

    copy: function(vec) {
        this.x = vec.x;
        this.y = vec.y;

        return this;
    },

    add: function(v) {
        return new Vec2(this.x + v.x, this.y + v.y);
    },

    addScalar: function(s) {
        return new Vec2(this.x + s, this.y + s);
    },

    sub: function(v) {
        return new Vec2(this.x - v.x, this.y - v.y);
    },

    subScalar: function(s) {
        return new Vec2(this.x - s, this.y - s);
    },

    mul: function(v) {
        return new Vec2(this.x * v.x, this.y * v.y);
    },

    mulScalar: function(s) {
        return new Vec2(this.x * s, this.y * s);
    },

    div: function(v) {
        return new Vec2(this.x / v.x, this.y / v.y);
    },

    divScalar: function(s) {
        return new Vec2(this.x / s, this.y / s);
    },

    neg: function() {
        return new Vec2(-this.x, -this.y);
    },

    dot: function(v) {
        return this.x * v.x + this.y * v.y;
    },

    cross: function(v) {
        return this.x * v.y - this.y * v.x;
    },

    lenSq: function() {
        return this.x * this.x + this.y * this.y;
    },

    len: function() {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    },

    normalize: function() {
        return this.divScalar(this.len() || 1);
    },

    equals: function(v) {
        return ((v.x === this.x) && (v.y === this.y));
    },

    rotate: function(angle) {
        var rad = angle * Math.PI / 180;
        var c = Math.cos(angle);
        var s = Math.sin(angle);

        return new Vec2(c * this.x - s * this.y, s * this.x + s * this.y);
    },

    rotateAround: function(center, angle) {
        var rad = angle * Math.PI / 180;
        var c = Math.cos(angle);
        var s = Math.sin(angle);

        var x = this.x - center.x;
        var y = this.y - center.y;

        return new Vec2(x * c - y * s + center.x, this.y = x * s + y * c + center.y);
    },

    // in rad
    angle: function() {
        return Math.atan2(this.y, this.x);
    }
});

/**
 * Utils
 */
function Utils() { }

Utils.clamp = function(val, a, b) {
    // val < a ? a : (val > b ? b : val);
    return Math.min(Math.max(val, a), b);
};

Utils.lerp = function(val, target, t) {
    t = Utils.clamp(t, 0, 1);
    return (val + t * (target - val));
};

Utils.mod = function(a, b) {
    var r = a % b;
    return r < 0 ? r + b : r;
};

Utils.distance = function(a, b) {
    var x = a.x - b.x;
    var y = a.y - b.y;
    return Math.sqrt(x * x + y * y);
};

Utils.sphereMass = function(radius, density) {
    return 4.0 / 3.0 * Math.PI * Math.pow(radius, 3) * density;
};

Utils.listRemove = function(lst, val) {
    var index = lst.indexOf(val);
    if (index > -1) {
        lst.splice(index, 1);
    }
};

Utils.listHas = function(lst, key, val) {
    for (var i = 0; i < lst.length; ++i) {
        if (lst[i][key] == val) {
            return true;
        }
    }

    return false;
};

Utils.listFind = function(lst, key, val) {
    for (var i = 0; i < lst.length; ++i) {
        if (lst[i][key] == val) {
            return lst[i];
        }
    }

    return null;
};

/**
 * Game settings: music, visibility, difficulty
 */
function Settings() { }
Settings.cameraLimit = 40;
Settings.propulseForce = 4;
Settings.speedx = 0.24;
Settings.speedy = 0.16;
Settings.volume = 3;
Settings.difficulty = 1;
Settings.dt = 1 / 60;
Settings.G = 0.3;

/*
 * Text
 */
function Text(text, pos, scale, color) {
    this.text = text;
    this.pos = pos;
    this.scale = scale;
    this.color = color;
}

Text.prototype.draw = function(color) {
    if (color == null)
        print(this.text, this.pos.x, this.pos.y, this.color, false, this.scale);
    else
        print(this.text, this.pos.x, this.pos.y, color, false, this.scale);
};

/*
 * Star
 */
function Star(pos, o, visible, layer, depth, density, radius, gravRadius, defaultColor) {
    Drawable.call(this, pos, o, visible, layer, depth);
    this.density = density;
    this.radius = radius;
    this.gravRadius = gravRadius;
    this.mass = Utils.sphereMass(radius, density);
    this.gravColor = 1;
    this.color = defaultColor;
    this.defaultColor = defaultColor;
}

Star.prototype.draw = function() {
    circb(this.pos.x, this.pos.y, this.gravRadius, this.gravColor);
    circ(this.pos.x, this.pos.y, this.radius, this.color);
};

/*
 * Enums
 */
var Dir = {"Up": 0, "Down": 1, "Left": 2, "Right": 3, "CW": 4, "CCW": 5};
Object.freeze(Dir);

var Key = {"Up": 58, "Down": 59, "Left": 60, "Right": 61, "A": 1, "Z": 26, "Enter": 50};
Object.freeze(Key);

var ScrSz = {"w": 240, "h": 136};
Object.freeze(ScrSz);

/**
 * Finite-State-Machine
 */
function State(name) {
    this.name = name;
}

Object.assign(State.prototype, {
    init: function() { },
    onEnter: function() { },
    onExit: function() { },
    update: function(dt) { },
    render: function() { }
});

function MenuState() {
    State.call(this, "menu");
}

MenuState.prototype = Object.create(State.prototype);
MenuState.prototype.constructor = MenuState;

Object.assign(MenuState.prototype, {
    init: function() {
        this.selection = 0;
        this.menuListX = 120;
        this.title = new Text("SATELLITE", new Vec2(20, 30), 4, 2);
        this.playTxt = new Text("Play", new Vec2(this.menuListX, 60), 1, 1);
        this.difficultyTxt = new Text("Difficulty", new Vec2(this.menuListX, 70), 1, 1);
        this.visibilityTxt = new Text("Visibility", new Vec2(this.menuListX, 80), 1, 1);
        this.musicTxt = new Text("Music", new Vec2(this.menuListX, 90), 1, 1);
        this.exitTxt = new Text("Exit", new Vec2(this.menuListX, 100), 1, 1);
        this.satellite = new Satellite(0, 0, new Vec2(50, 50), 0, 5.0);
        this.enterPressedP = false;
        trace("Init [S]MenuState", 5);
    },

    onEnter: function() {
        trace("Enter->[S]MenuState");
    },

    onExit: function() {
        trace("Exit<-[S]MenuState");
    },

    render: function() {
        this.update(Settings.dt);

        this.title.draw();

        if (this.selection == 0) {

            this.playTxt.draw(8);

        } else {

            this.playTxt.draw();

        }

        if (this.selection == 1) {

            this.difficultyTxt.draw(8);

        } else {

            this.difficultyTxt.draw();
        }

        if (this.selection == 2) {

            this.visibilityTxt.draw(8);

        } else {

            this.visibilityTxt.draw();

        }

        if (this.selection == 3) {

            this.musicTxt.draw(8);

        } else {

            this.musicTxt.draw();
        }

        if (this.selection == 4) {

            this.exitTxt.draw(8);

        } else {

            this.exitTxt.draw();

        }

        this.satellite.draw(this.enterPressedP);
    },

    update: function(dt) {
        switch (this.selection) {
        case 0:
            this.satellite.pos = new Vec2(this.playTxt.pos.x - 24, this.playTxt.pos.y - 1);
            break;
        case 1:
            this.satellite.pos = new Vec2(this.difficultyTxt.pos.x - 24, this.difficultyTxt.pos.y - 1);
            break;
        case 2:
            this.satellite.pos = new Vec2(this.visibilityTxt.pos.x - 24, this.visibilityTxt.pos.y - 1);
            break;
        case 3:
            this.satellite.pos = new Vec2(this.musicTxt.pos.x - 24, this.musicTxt.pos.y - 1);
            break;
        case 4:
            this.satellite.pos = new Vec2(this.exitTxt.pos.x - 24, this.exitTxt.pos.y - 1);
            break;
        default:
            break;
        }
    }
});

function GameOverState() {
    State.call(this, "gameover");
}

GameOverState.prototype = Object.create(State.prototype);
GameOverState.prototype.constructor = GameOverState;

Object.assign(GameOverState.prototype, {
    init: function() {
        this.txt = new Text("Game Over", new Vec2(40, 50), 3, 2);
        this.note = new Text("ENTER - back to menu", new Vec2(64, 80), 1, 4);
        trace("Init [S]GameOverState", 5);
    },

    onEnter: function() {
        trace("Enter->[S]GameOverState");
    },

    onExit: function() {
        trace("Exit<-[S]GameOverState");
    },

    update: function(dt) { },

    render: function() {
        if (time() % 800 > 400)
            this.txt.draw();
        this.note.draw();
    }
});

function PlayState() {
    State.call(this, "play");
}

PlayState.prototype = Object.create(State.prototype);
PlayState.prototype.constructor = PlayState;

Object.assign(PlayState.prototype, {
    init: function() {
        this.bt = [
            // sprite-id-unpressed name position sprite-id-pressed keymapid not-available
            [0,  "U", [ 8,  0], 16,  0, 32],
            [1,  "D", [ 8, 16], 17,  1, 33],
            [2,  "L", [ 1,  8], 18,  2, 34],
            [3,  "R", [15,  8], 19,  3, 35],
            [4,  "A", [ 0,  0], 20,  1, 36],
            [5,  "Z", [ 0, 14], 21, 26, 37],
        ];
        this.score = 0;
        this.satellite = new Satellite(4, 1, new Vec2(0, 127),
                                       new Vec2(Settings.speedx, -Settings.speedy),
                                       0, 500.0);
        this.star1 = new Star(new Vec2(0, 0), new Vec2(0, 0), true, 0, 0, 1, 60, 100, 2);
        this.star2 = new Star(new Vec2(100, 50), new Vec2(0, 0), true, 0, 0, 1, 10, 30, 2);
        this.star3 = new Star(new Vec2(200, 140), new Vec2(0, 0), true, 0, 0, 1, 40, 70, 2);

        this.stars = new Group("stars");
        this.stars.push(this.star1, this.star2, this.star3);
        this.gravity = Settings.gravity;

        trace("Init [S]PlayState", 5);
    },

    onEnter: function() {
        trace("Enter->[S]PlayState");
    },

    onExit: function() {
        trave("Exit<-[S]PlayState");
    },

    update: function(dt) {
        this.satellite.update(dt);
        this.gravityInfluence();
    },

    render: function(dt) {
        //trace("PlayState drawing");
        this.update(dt);
        //trace(this.satellite.pos.x + " " + this.satellite.pos.y);
        this.satellite.draw();
        this.star1.draw();
        this.star2.draw();
        this.star3.draw();
    },

    showDirBtns: function(x, y) {
        var battery_weak = this.satellite.weakBttP();
        for (var i = 0; i < 4; ++i) {
            if (!battery_weak) {
                spr(this.bt[i][0], this.bt[i][2][0] + x, this.bt[i][2][1] + y);
                if (btn(this.bt[i][4])) {
                    spr(this.bt[i][3], this.bt[i][2][0] + x, this.bt[i][2][1] + y);
                }
            } else {
                spr(this.bt[i][5], this.bt[i][2][0] + x, this.bt[i][2][1] + y);
            }
        }
    },

    showFnBtns: function(x, y) {
        var battery_weak = this.satellite.weakBttP();
        for (var i = 4; i < 6; ++i) {
            if (!battery_weak) {
                spr(this.bt[i][0], this.bt[i][2][0] + x, this.bt[i][2][1] + y);

                if (key(this.bt[i][4])) {
                    spr(this.bt[i][3], this.bt[i][2][0] + x, this.bt[i][2][1] + y);
                }
            } else {
                spr(this.bt[i][5], this.bt[i][2][0] + x, this.bt[i][2][1] + y);
            }
        }
    },

    showTime: function(x, y) {
        print("Time: " + (time() / 1000).toFixed(2), x, y, 15, scale=0.5, smallfont=true);
    },

    showScore: function(score, x, y) {
        print("Score: " + score, x, y, 15, scale=0.5, smallfont=true);
    },

    showHud: function() {
        this.showDirBtns(216, 112);
        this.showFnBtns(0, 112);
        this.showTime(0, 0);
        this.showScore(this.score, 180, 0);
    },

    incScore: function(val) {
        this.score += v;
    },

    decScore: function(val) {
        this.score -= v;
    },

    gravityInfluence: function() {
        trace("In gravityInfluence");
        var acc = new Vec2(0, 0);
        for (var i = 0; i < this.stars.length; ++i) {
            if (Utils.distance(this.satellite.pos, this.stars[i].pos) - this.satellite.radius <= this.stars[i].gravRadius) {
                print("In gravity field!!", 100, 120, 4);
                this.stars[i].color = 9;
                trace("Going to calculate");
                acc = this.satellite.calcGravAcc(this.stars[i], Settings.G);
                trace("Finish calculate");
                trace("ACC " + acc.x + " " + acc.y);
            } else {
                this.stars[i].color = this.stars[i].defaultColor;
            }
        }

        this.satellite.acc.x = acc.x;
        this.satellite.acc.y = acc.y;
        trace("Satellite [ACC] " + this.satellite.acc.x + " " + this.satellite.acc.y);
    }
});


function FSM() { 
    this.current = null;
    this.states = [];
}

Object.assign(FSM.prototype, {
    add: function(state) {
        trace("Adding [S]" + state.name);
        if (Utils.listHas(this.states, 'name', state.name)) {

            trace("State with name: " + state.name + " already exists!");

        } else {

            state.init();
            this.states.push(state);

        }
    },

    remove: function(name) {
        var s = this.states[name];
        if (s != null) {
            if (this.current === s) {
                this.current.onExit(null);
                this.current = null;
            }
            this.states.delete(name);
        }
    },

    switchTo: function(name) {
        var s = Utils.listFind(this.states, "name", name);
        if (s !== null) {
            if (this.current !== null) {
                this.current.onExit();
            }
            s.onEnter();
            this.current = s;
            trace("Switch to [S]" + this.current.name);
        }
    },

    update: function(dt) {
        if (this.current !== null) {
            this.current.update(dt);
        }
    },

    render: function(dt) {
        //trace("FSM drawing [S] " + this.current.name);
        if (this.current !== null) {
            this.current.render(dt);
        }
    }
});

/*
 * Timer
 */
function Timer() {
    // TODO: complete
}

function Game() {
    // TODO: delete
    this.enterReleased = false;
    //this.dt;
    this.volume = 2;
    this.score = 0;

    this.fsm = new FSM();
    //this.timer = new Timer();
    //this.timer.init();

    //this.camera = new Camera();
    //this.camera.init();

    //this.renderer = new Renderer();
    //this.renderer.init();
    //this.renderer.createLayer(0); // background
    //this.renderer.createLayer(1); // stars
    //this.renderer.createLayer(2); // planets
    //this.renderer.createLayer(3); // satellite
    //this.renderer.createLayer(4); // foreground

    //this.world = new World();
    //this.world.groups.create("planets");
    //this.world.groups.create("satellite");
    //this.world.groups.create("bbox");
    //this.world.groups.create("stars");
}

Object.assign(Game.prototype, {
    init: function() {
        trace("Going to add");
        this.fsm.add(new GameOverState());
        this.fsm.add(new MenuState());
        this.fsm.add(new PlayState());
        this.fsm.switchTo("menu");
    },

    keyinput: function() {
        if (keyp(Key.Enter)) {

            trace("Enter pressed");
            trace("Current [S]" + this.fsm.current.name);

            if (this.fsm.current.name == "gameover") {

                this.fsm.switchTo("menu");

            } else if (this.fsm.current.name == "menu") {

                // TODO: change selection color
                //this.fsm.current.enterPressedP = true;
                switch (this.fsm.current.selection) {
                case 0:
                    this.fsm.switchTo("play");
                    break;
                case 1:
                    // difficulty
                    break;
                case 2:
                    // visibility
                    break;
                case 3:
                    // music
                    break;
                case 4:
                    //this.fsm.switchTo("gameover"); // TODO: remove, this is just for test
                    exit();
                    break;
                default:
                    break;
                }
            }
        }

        if (keyp(Key.Up)) {
            if (this.fsm.current.name == "menu")
                this.fsm.current.selection = Utils.mod(this.fsm.current.selection - 1, 5);

            if (this.fsm.current.name == "play") {
                this.fsm.current.satellite.propulse(Dir.Up, 5.0);
            }
        }

        if (keyp(Key.Down)) {
            if (this.fsm.current.name == "menu")
                this.fsm.current.selection = Utils.mod(this.fsm.current.selection + 1, 5);

            if (this.fsm.current.name == "play")
                this.fsm.current.satellite.propulse(Dir.Down, 5.0);
        }

        if (key(Key.Left)) {
            if (this.fsm.current.name == "play")
                this.fsm.current.satellite.propulse(Dir.Left, 1.0);
        }

        if (key(Key.Right)) {
            if (this.fsm.current.name == "play")
                this.fsm.current.satellite.propulse(Dir.Right, 1.0);
        }

        if (keyp(Key.A)) {
            if (this.fsm.current.name == "play")
                this.fsm.current.satellite.spin(Dir.CW);
        }

        if (keyp(Key.Z)) {
            if (this.fsm.current.name == "play")
                this.fsm.current.atellite.spin(Dir.CCW);
        }
    },

    update: function(dt) {
        this.keyinput();
        //this.timer.update();
        this.fsm.render(dt);
        //this.space.draw();
        //this.satellite.draw();
    }
});

/*
 * Satellite
 */

function Satellite(radius, mass, pos, velocity, rotation, battery) {
    this.radius = radius;
    this.mass = mass;
    this.pos = pos;
    this.acc = new Vec2(0, 0);
    this.rotation = rotation;
    this.battery = battery;
    this.sprite = [6, 7, 8, 9, 10, 11];
    this.velocity = velocity;
}

Object.assign(Satellite.prototype, {
    draw: function(dark) {
        //trace("[Satellite] x: " + this.pos.x + " y: " + this.pos.y);
        //trace("[Satellite] rotation: " + this.rotation);
        if (!dark) {

            spr(this.sprite[0], this.pos.x - 8, this.pos.y, rotate=this.rotation);
            spr(this.sprite[1], this.pos.x, this.pos.y, rotate=this.rotation);
            spr(this.sprite[2], this.pos.x + 8, this.pos.y, rotate=this.rotation);

        } else {

            spr(this.sprite[3], this.pos.x - 8, this.pos.y, rotate=this.rotation);
            spr(this.sprite[4], this.pos.x, this.pos.y, rotate=this.rotation);
            spr(this.sprite[5], this.pos.x + 8, this.pos.y, rotate=this.rotation);

        }

        if (this.battery <= 1.0) {
            if (time() % 360 > 180)
                print("WARNING: LOW ENERGY!", 64, 128, 6);
        }

        // TODO: only for debug
        circb(this.pos.x + 3, this.pos.y + 4, this.radius, 4);
    },

    spin: function(dir) {
        // TODO: complete
        if (this.battery > 0) {
            switch (dir) {
                case Dir.CW: {
                    this.battery -= 0.5;
                    this.rotation += 1;
                    this.rotation %= 4;
                } break;

            case Dir.CCW: {
                this.battery -= 0.5;
                this.rotation -= 1;
                this.rotation %= 4;
            } break;

            default:
                break;
            }
        }
    },

    propulse: function(dir, val) {
        // TODO: complete
        if (this.battery > 0) {
            switch (dir) {
                case Dir.Up: {
                    this.battery -= 0.5;
                    if (this.pos.y < 128)
                        this.pos.y += val;
                } break;

                case Dir.Down: {
                    this.battery -= 0.5;
                    if (this.pos.y > 0)
                        this.pos.y -= val;
                } break;

                case Dir.Left: {
                    this.battery -= 0.5;
                    if (this.pos.x < 224)
                        this.pos.x += val;
                } break;

                case Dir.Right: {
                    this.battery -= 0.5;
                    if (this.pos.x > 6)
                        this.pos.x -= val;
                } break;

                default:
                break;
            }
        }
    },

    calcGravAcc: function(star, g) {
        var r = Utils.distance(star.pos, this.pos);
        var a = (g * star.mass) / (r * r);
        var angle = star.pos.sub(this.pos).normalize().angle();
        trace("Angle " + angle);
        return new Vec2(a * Math.cos(angle), a * Math.sin(angle));
    },

    weakBttP: function() {
        if (this.battery <= 0.0)
            return true;
        else
            return false;
    },

    update: function(dt) {
        this.velocity = this.velocity.add(this.acc.mulScalar(dt));
        trace("Satellite [V]: " + this.velocity.x + " " + this.velocity.y);
        this.pos.x += this.velocity.x;
        this.pos.y += this.velocity.y;
        trace("finish Satellite update");
    }
});

/*
 * Line
 */
function Line() {
    Drawable.call(this);
}

Line.prototype.draw = function() {
    // TODO
};

/*
 * Circle
 */
function Circle(r, p) {
    Drawable(this);
    this.radius = r;
    this.pos    = p;
    this.color = 2;
}

Circle.prototype.draw = function() {
    circ(this.pos.x - this.o.x, this.pos.y - this.o.y, this.radius, this.color);
};

function Drawable(pos, o, visible, layer, depth) {
    this.pos = pos ;  // current position
    this.o = o;      // origin
    this.visible = visible;
    this.layer = layer;
    this.depth = depth;
}

Object.assign(Drawable.prototype, {
    init: function() {
        // TODO: implemetation
    },

    draw: function() {
        // TODO: implemetation
    },

    destroy: function() {
        // TODO: implementation
    }
});

/*
 * Renderer
 */
function Renderer(color, layers) {
    this.color = color;
    this.layers = layers || {};
    this.layersList = [];
}

Object.assign(Renderer.prototype, {
    createLayer: function(idx) {
        // TODO
    },

    destroyLayer: function(idx) {
        // TODO
    },

    add: function(entity) {
        // TODO
    },

    remove: function(entity) {
        // TODO
    },
});

/*
 * Group
 */
function Group(name, world) {
    Array.call(this, name);
    this.name = name;
    this.world = world;
}

Group.prototype = Object.create(Array.prototype);
Group.prototype.constructor = Group;

Object.assign(Group.prototype, {
    has: function(entity) {
        // TODO
    }
});

/*
 * CircleBoundingBox
 */
function CircBBox(entity, pos, radius) {
    this.entity = entity;
    this.pos = entity.pos;
    this.radius = radius;
}

/*
 * Rectangle
 */
function Rect(w, h, p) {
    this.w = w;
    this.h = h;
    this.pos  = p;
}

/*
 * Collision
 */
function Collision() {}

Collision.circleCollision = function(c1, c2) {
    var diff = c1.sub(c2);
    if (diff.len() < c1.radius + c2.radius) {
        // TODO: return collision status and collision point
        return true;

    } else {
        return false;
    }
};

Collision.aabb = function(r1, r2) {
    if (r1.pos.x < r2.pos.x + r2.w && r1.pos.x + r1.w > r2.x &&
        r1.pos.y < r2.pos.y + r2.h && r1.h + r1.pos.y > r2.y) {
        // TODO: return collision status and collision point
        return true;

    } else {
        return false;
    }
};

/*
 * Camera
 */

function Camera(pos, shaking, shake_amount) {
    this.pos = pos || new Vec2(0);
    this.shaking = shaking || false;
    this.shake_amount = shake_amount || 0;
}

Object.assign(Camera.prototype, {
    shake: function(amount) {
        this.shaking = true;
        this.shake_amount = amount;
    }
});

/*
 * ParticleSystem
 */

/*
 * ParticleEmmiter
 */

/*
 * Entity-Components-System
 */
function World(n) {
    this.initP = false;

    this.capacity = n || 0;
    this.eidPool = new Array(n || 0);
    this.entities = new Array(n || 0);
    this.aliveTag = new Array(n || 0);
    this.changeTag = new Array(n || 0);

    this.componentTypes = {};
    this.components = [];

    this.groups = {};

    this.systems = {};
    this.activeSystems = [];
    this.changed = [];
    this.destroyed = [];
}

Object.assign(World.prototype, {
    init: function(n) {
        // TODO
        // init systems
        for (var s in this.systems) {
            s.init();
        }
        this.initP = true;
    },

    destroy: function() {
        for (var i = 0; i < this.capacity; ++i) {
            if (!this.aliveTag[i]) {
                this.entityDestroy(i);
            }
        }
    },

    update: function(dt) {
        // TODO
    },

    // entity
    entityCreate: function() {
        var id;
        // TODO
    },

    entityDestroy: function() {
        // TODO
    },

    entityAliveP: function() {
        // TODO
    },

    entityChangedP: function() {
        // TODO
    },

    // component
    componentSet: function(entity, comp, compType) {
        // TODO
    },

    onComponentAdded: function(entity, ct, ev) {
        // TODO
    },

    onComponentRemoved: function(entity, ct) {
        // TODO
    },

    componentType: function(compCls) {
        // TODO
    },

    componentsGet: function(compCls) {
        // TODO
    },

    // Group
    groupCreate: function(name, incl, excl) {
        // TODO
    },

    groupRemove: function(fam) {
        // TODO
    },

    groupGet: function(fam) {
        // TODO
    },

    // Systems
    systemAdd: function(sys, priority, enabled) {
        // TODO
    },

    systemGet: function(sysCls) {
        // TODO
    },

    systemRemove: function(sysCls) {
        // TODO
    },

    systemEnable: function(sysCls) {
        // TODO
    },

    systemDisable: function(sysCls) {
        // TODO
    },
});

// TODO
function Entity() { }
Entity.create = function() { };

function System(active, priority) {
    this.active = active || false;
    this.priority = priority || 0;
}

Object.assign(System.prototype, {
    add: function() {
        // TODO:
    },
});

/*
 * Main loops
 */
var world = new World();

var game = new Game();
game.init();

function TIC() {
    cls(0);
    game.update(Settings.dt);
}

function OVR() {
    if (game.fsm.current.name == "play")
        game.fsm.current.showHud();
    /*
      circb(50 + 40 * Math.sin(time()/1000), 50 + 40 * Math.cos(time()/1000), 20, 4);
      spr(22, 47 + 40 * Math.sin(time()/1000), 48 + 40 * Math.cos(time()/1000));
    */
}

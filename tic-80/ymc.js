// script: js

var world = new World();

var game = new Game();

function TIC() {
    cls(0);
    game.run();
}

var title = new Text("SATELLITE", new Vec2(20, 30), 4, 2);
var play = new Text("Play", new Vec2(120, 60), 1, 1);
var difficulty = new Text("Difficulty", new Vec2(120, 70), 1, 1);
var visibility = new Text("Visibility", new Vec2(120, 80), 1, 1);
var music = new Text("Music", new Vec2(120, 90), 1, 1);

function OVR() {
    /*
    game.showHud();

    circb(50 + 40 * Math.sin(time()/1000), 50 + 40 * Math.cos(time()/1000), 20, 4);
    spr(22, 47 + 40 * Math.sin(time()/1000), 48 + 40 * Math.cos(time()/1000));
    */
    title.draw();
    play.draw();
    difficulty.draw();
    visibility.draw();
    music.draw();
}


/*
 * Enums
 */
var Dir = {"Up": 0, "Down": 1, "Left": 2, "Right": 3, "CW": 4, "CCW": 5};
Object.freeze(Dir);

var Btn = {"Up": 58, "Down": 59, "Left": 60, "Right": 61, "A": 1, "Z": 26};
Object.freeze(Btn);

var ScrSz = {"w": 240, "h": 136};
Object.freeze(ScrSz);

/*
 * Timer
 */
function Timer() {
    // TODO: complete
}

function Game() {
    this.score = 0;
    this.bt = [
        // sprite-id-unpressed name position sprite-id-pressed keymapid not-available
        [0,  "U", [ 8,  0], 16,  0, 32],
        [1,  "D", [ 8, 16], 17,  1, 33],
        [2,  "L", [ 1,  8], 18,  2, 34],
        [3,  "R", [15,  8], 19,  3, 35],
        [4,  "A", [ 0,  0], 20,  1, 36],
        [5,  "Z", [ 0, 14], 21, 26, 37],
    ];
    this.satellite = new Satellite(0, 0, new Vec2(50, 50), 0, 5.0);
}

Object.assign(Game.prototype, {
    showHud: function(score) {
        this.showDirBtns(216, 112);
        this.showFnBtns(0, 112);
        this.showTime(0, 0);
        this.showScore(score, 180, 0);
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

    run: function() {
        if (key(Btn.Up)) {
            this.satellite.propulse(Dir.Up);
        }

        if (key(Btn.Down)) {
            this.satellite.propulse(Dir.Down);
        }

        if (key(Btn.Left)) {
            this.satellite.propulse(Dir.Left);
        }

        if (key(Btn.Right)) {
            this.satellite.propulse(Dir.Right);
        }

        if (keyp(Btn.A)) {
            this.satellite.spin(Dir.CW);
        }

        if (keyp(Btn.Z)) {
            this.satellite.spin(Dir.CCW);
        }

        this.satellite.draw();
    }
});

/*
 * Star
 */
function Star(paralax) {
    this.paralax = paralax;
}

/*
 * Planet
 */
function Planet(pos, o, visible, layer, depth, density, radius, gravRadius) {
    Drawable.call(this, pos, o, visible, layer, depth);
    this.density = density;
    this.radius = radius;
    this.gravRadius = gravRadius;
    this.mass = Utils.sphereMass(radius, density);
    this.gravColor = 1;
    this.color = 2;
}

Planet.prototype.draw = function() {
    circb(this.pos.x, this.pos.y, this.gravRadius, this.gravColor);
    circ(this.pos.x, this.pos.y, this.radius, this.color);
}

/*
 * Satellite
 */

function Satellite(radius, mass, pos, rotation, battery) {
    this.radius = radius;
    this.mass = mass;
    this.pos = pos;
    this.rotation = rotation;
    this.battery = battery;
    this.sprite = [6, 7, 8];
}

Object.assign(Satellite.prototype, {
    draw: function() {
        trace("[Satellite] x: " + this.pos.x + " y: " + this.pos.y);
        trace("[Satellite] rotation: " + this.rotation);
        spr(this.sprite[0], this.pos.x - 8, this.pos.y, rotate=this.rotation);
        spr(this.sprite[1], this.pos.x, this.pos.y, rotate=this.rotation);
        spr(this.sprite[2], this.pos.x + 8, this.pos.y, rotate=this.rotation);
        if (this.battery <= 1.0) {
            if (time() % 360 > 180)
                print("WARNING: LOW ENERGY!", 64, 128, 6);
        }
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
                        this.pos.y += 1;
                } break;

                case Dir.Down: {
                    this.battery -= 0.5;
                    if (this.pos.y > 0)
                        this.pos.y -= 1;
                } break;

                case Dir.Left: {
                    this.battery -= 0.5;
                    if (this.pos.x < 224)
                        this.pos.x += 1;
                } break;

                case Dir.Right: {
                    this.battery -= 0.5;
                    if (this.pos.x > 6)
                        this.pos.x -= 1;
                } break;

                default:
                break;
            }
        }
    },

    weakBttP: function() {
        if (this.battery <= 0.0)
            return true;
        else
            return false;
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
}

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
    }
});

/*
 * Circle
 */
function Circle(r, p) {
    this.radius = r;
    this.pos    = p;
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
 * Text
 */
function Text(text, pos, scale, color) {
    this.text = text;
    this.pos = pos;
    this.scale = scale;
    this.color = color;
}

Text.prototype.draw = function() {
    print(this.text, this.pos.x, this.pos.y, this.color, false, this.scale);
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
 * State Machine
 */
function State(name) {
    this.name = name;
}

Object.assign(State.prototype, {
    init: function() { },
    onEnter: function(d) { },
    onLeave: function(d) { },
    update: function(dt) { },
    draw: function() { }
});

function MenuState() {
    State.call(this, "menu");
    this.x = 120;
}

MenuState.prototype = Object.create(State.prototype);
MenuState.prototype.constructor = MenuState;
MenuState.prototype.onEnter = function(d) {
    this.selection = 0;
    this.title = new Text("SATELLITE", new Vec2(20, 30), 4, 2);
    this.playTxt = new Text("Play", new Vec2(this.x, 60), 1, 1);
    this.difficultyTxt = new Text("Difficulty", new Vec2(this.x, 70), 1, 1);
    this.visibilityTxt = new Text("Visibility", new Vec2(this.x, 80), 1, 1);
    this.musicTxt = new Text("Music", new Vec2(this.x, 90), 1, 1);
    this.exitTxt = new Text("Exit", new Vec2(this.x, 100), 1, 1);
};

// TODO: onEnter, onLeave, update

function GameOverState() {
    State.call(this, "gameover");
}

GameOverState.prototype = Object.create(State.prototype);
GameOverState.prototype.constructor = GameOverState;

// TODO: onEnter, onLeave, update

function PlayState() {
    State.call(this, "play");
}

PlayState.prototype = Object.create(State.prototype);
PlayState.prototype.constructor = PlayState;
// TODO: onEnter, onLeave, update

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
 * Utils
 */
function Utils() { }

Utils.clamp = function(val, a, b) {
    // val < a ? a : (val > b ? b : val);
    return Math.min(Math.max(val, a), b);
}

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
}

Utils.sphereMass = function(radius, density) {
    return 4.0 / 3.0 * Math.PI * Math.pow(radius, 3) * density;
}

Utils.listRemove = function(lst, val) {
    var index = lst.indexOf(val);
    if (index > -1) {
        lst.splice(index, 1);
    }
}

class Screen {

	static width { 240 }
	static height { 136 }
}


class State {

	name { _name }

	construct new(n) {
		_name = n
	}

	init() { }
	onenter(d) { }
	onleave(d) { }
	update(dt) { }
	draw() { }

}

class MenuState is State {


	construct new() {
		super("menu")
	}

	init(){

	}

	onenter(d){
		_sel = 0
		_title = Text.new("KOMET",84,40,5,2)
		_s = Circle.new(2,11,3)
		_s.ox = -2
		_s.oy = -2
		_s.x = 78
		_s.y = 80
		_p1 = Text.new("play",88,80,11,1)
		_diff = Text.new("difficulty 0",88,90,11,1)
		_vis = Text.new("visibility 0",88,100,11,1)
		_mustxt = Text.new("music %(Game.music ? "on" : "off")",88,110,11,1)

		_ps = ParticleSystem.new()
		var em = ParticleEmitter.new(
			512,
			[
				RadialSpawnModule.new(3),
				ScaleLifeModule.new(2,4),
				ColorLifeModule.new([11,10,10,9,9]),
				VelocityModule.new(-100,-12,0,12),
			],
			CircleDrawModule.new()

		)
		em.cache_wrap = true
		em.rate = 200
		em.life = 0.2
		em.life_max = 1
		_ps.add(em)

		_ps.x = _s.x+2
		_ps.y = _s.y+2

		upd()
	}

	upd() { 
		_diff.text = "difficulty %(Game.diff)"
		_vis.text = "visibility %(Game.vis)"
		_mustxt.text = "music %(Game.music ? "on" : "off")"
	}


	update(dt) { 
		if(TIC.keyp(50) || TIC.btnp(4)) { // z
			Game.fsm.set("play")
		}

		if(TIC.btnp(0)) { 
			_sel = Maths.mod(_sel-1, 4)
			_s.y = 80 + _sel*10
		} else if(TIC.btnp(1)) { 
			_sel = (_sel+1)%4
			_s.y = 80 + _sel*10
		} else if(TIC.btnp(2)) {
			if (_sel == 1) {
				Game.diff = Game.diff - 1
				if (Game.diff < 0) {
					Game.diff = 0
				}
				upd()
			} else if (_sel == 2) {
				Game.vis = Game.vis - 1
				if (Game.vis < 0) {
					Game.vis = 0
				}
				upd()
			} else if (_sel == 3) {
				Game.music = false
				upd()
			}

		} else if(TIC.btnp(3)) {
			
			if (_sel == 1) {
				Game.diff = Game.diff + 1
				if (Game.diff > 3) {
					Game.diff = 3
				}
				upd()
			} else if (_sel == 2) {
				Game.vis = Game.vis + 1
				if (Game.vis > 3) {
					Game.vis = 3
				}
				upd()
			} else if (_sel == 3) {
				Game.music = true
				upd()
			}
		}
	}

	draw() { 

		_title.color = 11
		_title.y = 41
		_title.draw()
		_title.color = 10
		_title.y = 40
		_title.draw()
		_title.color = 9
		_title.y = 39
		_title.draw()

		_s.draw()

		_p1.draw()
		_diff.draw()
		_vis.draw()
		_mustxt.draw()

		_ps.x = _s.x+2
		_ps.y = _s.y+2
		_ps.update(1/60)
		_ps.draw()
	}


}

class GameOverState is State {
	
	construct new() {
		super("gameover")
	}

	onenter(d){

		_texts = []
		_main = Text.new("GAME OVER",64,28,2,2)
		_score = Text.new("score: %(Game.score.floor)",90,50,11,1)

		_playtext = Text.new("press z to play again",62,100,11,1)
		_menutext = Text.new("press s to menu",62,110,11,1)

		_texts.add(_main)
		_texts.add(_score)
		_texts.add(_playtext)
		_texts.add(_menutext)

	}

	update(dt) { 
		if(TIC.btnp(4)) {
			Game.fsm.set("play")
		} else if(TIC.btnp(7)) { 
			Game.fsm.set("menu")
		}
	}

	draw() { 
		for (t in _texts) {
			t.draw()
		}
	}

}


class World {

	static current { __cw }
	static init(n) { __cw = World.new_(n) }
	static empty() { __cw.empty() }
	static update(dt) { __cw.update(dt) }

	capacity { _capacity }
	comp_flags { _comp_flags }
	comp_types { _comp_types }

	construct new_(n) {
		_inited = false
		_capacity = n
		_eid_pool = IdBuffer.new(n)
		_entities = IntVector.new(n)
		_alive_mask = BitVector.new(n)
		_changed_mask = BitVector.new(n)
		_comp_flags = List.filled(n, null)
		_comp_types = {}
		_comps = []
		_families = {}
		_processors = {}
		_active_processors = []
		_changed = []
		_destroyed = []

		// private functions
		_destroy_entity = Fn.new{|e|
			_entities.remove(e)
			_eid_pool.push(e)
			_comp_flags[e] = null
		}

		init() // todo

	}

	init() { 
		_inited = true
		for (p in _processors.values) {
			p.init()
		}
	}

	empty() {
		for (e in 0..._capacity) {
			if (_alive_mask[e]) {
				entity_destroy(e)
			}
		}
		upd_()
	}

	// entity
	entity_create() { 
		var id = _eid_pool.pop()
		_alive_mask[id] = true
		_entities.add(id)
		_comp_flags[id] = BitFlag.new()
		return id
	}

	entity_destroy(e) { 
		if (!entity_alive(e)) Fiber.abort("entity %(e) destroying repeatedly")
		_alive_mask[e] = false
		_comps.each {|c| c.remove(e)}
		_destroyed.add(e)
	}

	entity_alive(e) { _alive_mask[e] }

	entity_changed(e){
		if (!_changed_mask[e]) {
			_changed_mask[e] = true
			_changed.add(e)
		}
	}

	// component
	component_set(e,comp, ctype){ 
		if (comp is List) {
			for (c in comps) {
				ctype = c is Class ? ctype = c : ctype = c.type
				_comps[comp_get_type(ctype)].set_(e,c, false) 
			}
			entity_changed(e)
		} else {
			if (ctype == null) ctype = comp is Class ? ctype = comp : ctype = comp.type
			_comps[comp_get_type(ctype)].set_(e,comp,true) 
		}
	}

	oncompadded(e, ct, ev) { 
		_comp_flags[e].set_true(ct + 1)
		if (ev) entity_changed(e)
	}

	oncompremoved(e, ct) { 
		_comp_flags[e].set_false(ct + 1)
		entity_changed(e)
	}

	comp_get_type(comp_class){
		var ct = -1
		var cname = comp_class.name
		if(_comp_types.containsKey(cname)) {
			ct = _comp_types[cname]
		} else {
			ct = _comps.count
			if (ct > 64) Fiber.abort("Cant't have more than 64 type of components")
			_comp_types[cname] = ct
			_comps.add(Components.new(this, ct))
		}
		return ct
	}

	comps_get(comp_class){ _comps[comp_get_type(comp_class)] }

	// family
	family_create(name, incl, excl) { 
		if (_families.containsKey(name)) Fiber.abort("Family named: %(name) already exists")
		var f = Family.new_(this, name, incl, excl)
		_families[f.name] = f
		return f
	}

	family_remove(f){ // does i need this?
		_families.remove(f.name)
	}

	family_get(fname){ _families[fname] }

	// processors
	
	processor_add(p, prior, enabled){
		var pc = p.type
		p.priority = prior
		_processors[pc.name] = p
		p.setup_(this)
		p.onadded()
		if(_inited) p.init()
		if(enabled) processor_enable(pc)
		return p
	}

	processor_get(pc){ _processors[pc.name] }

	processor_remove(pc){
		var p = _processors[pc.name]
		if (p != null) {
			if(p.active) processor_disable(pc)
			p.onremoved()
			p.setup_(null)
			_processors.remove(pc.name)
			return p
		}
		return null
	}

	processor_enable(pc){
		var p = processor_get(pc)
		if (p != null && !p.active) {
			p.onenabled()
			p.active = true
			if (_active_processors.isEmpty) {
				_active_processors.add(p)
			} else {
				var added = false
				for (i in 0..._active_processors.count) {
					if (p.priority <= _active_processors[i].priority) {
						_active_processors.insert(i,p)
						added = true
						break
					}
				}
				if (!added) _active_processors.add(p)
			}
		}
	}

	processor_disable(pc){
		var p = processor_get(pc)
		if (p != null && p.active) {
			p.ondisabled()
			p.active = false
			for (i in 0..._active_processors.count) {
				if (_active_processors[i] == p) {
					_active_processors.removeAt(i)
					break
				} 
			}
		}
	}

	upd_() { 
		
		if (_changed.count > 0) {
			_changed.each {|e| 
				for (f in _families.values) {
					f.check(e)
				}
			} 
			_changed_mask.clear()
			_changed.clear()
		}

		for (c in _comps) {
			c.update()
		}

		if (_destroyed.count > 0) {
			_destroyed.each {|e| _destroy_entity.call(e)}
			_destroyed.clear()
		}

	}

	update(dt) { 
		upd_()
		_active_processors.each {|p| p.update(dt)}
		upd_()

	}


}

class Vector {

	construct new() {
		_x = 0
		_y = 0
	}

	construct new(x,y) {
		_x = x
		_y = y
	}

	x=(v) { _x = v } 
	y=(v) { _y = v }

	length=(v) { normalize().multiply(v) }

	x { _x } 
	y { _y }
	
	length { ( x * x + y * y ).sqrt }

	lengthsq { x * x + y * y }

	copy(o) { 
		_x = o.x
		_y = o.y 
		return this
	}

	set(x, y) { 
		_x = x
		_y = y 
		return this
	}

	normalize() { divide( length ) }

	dot(o) { x * o.x + y * o.y }
	
	add(o) { 
		if (o is Num) {
			_x = _x + o
			_y = _y + o
		} else{
			_x = _x + o.x
			_y = _y + o.y 
		}
		return this
	}

	add(x, y) { 
		_x = _x + x
		_y = _y + y 
		return this
	}

	subtract(o) { 
		if (o is Num) {
			_x = _x - o
			_y = _y - o
		} else{
			_x = _x - o.x
			_y = _y - o.y 
		}
		return this
	}

	subtract(x, y) { 
		_x = _x - x
		_y = _y - y 
		return this
	}

	multiply(o) { 
		if (o is Num) {
			_x = _x * o
			_y = _y * o
		} else{
			_x = _x * o.x
			_y = _y * o.y 
		}
		return this
	}

	multiply(x, y) { 
		_x = _x * x
		_y = _y * y 
		return this
	}

	divide(o) { 
		if (o is Num) {
			_x = _x / o
			_y = _y / o
		} else{
			_x = _x / o.x
			_y = _y / o.y 
		}
		return this
	}

	divide(x, y) { 
		_x = _x / x
		_y = _y / y 
		return this
	}

	toString { "{ x:%(x), y:%(y) }" }
}

//////////////////////////////////////////////////////////////
class Maths {

	static get_sphere_mass(r,d){ (4/3 * Num.pi * r.pow(3)) * d }

	static distance(x1,y1,x2,y2) { 
		var x = x2-x1
		var y = y2-y1
		return ( x * x + y * y ).sqrt
	}

	static clamp(value, a, b) { 
		return ( value < a ) ? a : ( ( value > b ) ? b : value )
	}

	static mod(a,b) {
		var r = a % b
		return r < 0 ? r + b : r
	}

	static lerp(value, target, t) {
		t = Maths.clamp(t, 0, 1)
		return (value + t * (target - value))
	}

}


class Pow {

	static require(x) {
		if(x == 0) return 1

		x = x - 1
		x = x | x >> 1
		x = x | x >> 2
		x = x | x >> 4
		x = x | x >> 8
		x = x | x >> 16

		return x + 1
	}

	static to_pow(num) { ((num.log)/(2).log).round }
}

// particles
class ParticleList is Sequence {

	length { _len }
	capacity { _cp }

	construct new(n) {
		_idxs = []
		_buff = []
		for (i in 0...n) {
			_idxs.add(i)
			_buff.add(Particle.new(i))
		}
		_cp = n
		_len = 0
		_wridx = 0
	}

	[i]{_buff[i]}

	ensure() {
		var p = _buff[_len]
		_len = _len+1
		return p
	}

	wrap() {
		var lidx = _len-1
		swap(_wridx, lidx)
		_wridx = (_wridx+1)%(_cp-1)
		return _buff[lidx]
	}

	remove(p) {
		var idx = _idxs[p.id]
		var lidx = _len-1
		if(idx != lidx) swap(idx, lidx)
		_len = _len-1
	}

	swap(a, b) {
		var ia = _buff[a]
		var ib = _buff[b]
		_idxs[ia.id] = b
		_idxs[ib.id] = a
		_buff[a] = ib
		_buff[b] = ia

	}

	clear () { 
		for (i in 0..._cp) {
			_idxs[i] = i
			_buff[i] = Particle.new(i)
		}
		_len = 0
	}

	iterate(i) {
		
		if (i == null) i = 0 else i = i + 1
		return i >= _len ? null : i
	}

	iteratorValue(i) { _buff[i] }

	toString {
		var lst = []
		for (i in 0..._len) {
			lst.add(_buff[i].id)
		}
		return lst.toString
	}

}

class Particle {

	id { _id }
	x { _x }
	y { _y }
	vx { _vx }
	vy { _vy }
	w { _w }
	h { _h }
	color { _clr }
	life { _lf }
	stlife { _slf }
	phase { _ph }

	x=(v) { _x=v }
	y=(v) { _y=v }
	vx=(v) { _vx=v }
	vy=(v) { _vy=v }
	w=(v) { _w=v }
	h=(v) { _h=v }
	color=(v) { _clr=v }
	life=(v) { _lf=v }
	stlife=(v) { _slf=v }
	phase=(v) { _ph=v }

	construct new(id) {
		_id = id
		_x = 0
		_y = 0
		_vx = 0
		_vy = 0
		_w = 2
		_h = 2
		_clr = 11
		_lf = 1
		_ph = 0
		_slf = 1
	}

}

class ParticleSystem is Drawable {

	active { _active }
	active=(v) { _active=v }
	emitters { _ems }

	construct new() {
		super()
		_active = true
		_ems = []
	}

	add(em) {
		_ems.add(em)
		em.init(this)
		return this
	}

	update(dt) {
		if (_active) _ems.each{|e|e.update(dt)} 
	}

	start() { _ems.each{|e|e.start()} }

	stop() {stop(false)}
	stop(kill) { _ems.each{|e|e.stop(kill)} }
	draw() { _ems.each{|e|e.draw()} }

}

class ParticleEmitter {

	x { _x }
	y { _y }
	enabled { _en }
	particles { _prts }
	modules { _mds }
	rendrer { _rend }
	system { _ps }
	duration { _dr }
	duration_max { _drm }
	cache_size { _cs }
	cache_wrap { _cwr }
	rate { _rate }
	rate_max { _ratemx }
	life { _life }
	life_max { _lifemx }
	count { _count }
	count_max { _countmx }
	random { _rnd }

	x=(v) { _x=v }
	y=(v) { _y=v }
	enabled=(v) { _en=v }
	duration=(v) { 
		_dr=v 
		calc_dur()
	}
	duration_max=(v) { 
		_drm=v 
		calc_dur()
	}
	cache_wrap=(v) { _cwr=v }
	rate=(v) { 
		_rate=v 
		_invrt = v>0 ? 1/v : 0
	}
	rate_max=(v) { 
		_ratemx=v 
		_invrtmx = v>0 ? 1/v : 0
	}
	life=(v) { _life=v }
	life_max=(v) { _lifemx=v }
	count=(v) { _count=v }
	count_max=(v) { _countmx=v }

	construct new(cs,mds,rend) {
		_cs = cs
		_en = true
		_cwr = false
		_x = 0
		_y = 0
		rate = 10
		rate_max = 0
		_life = 1
		_lifemx = 0
		_count = 1
		_countmx = 0
		_dr = -1
		_drm = 0
		_cdr = -1
		_mds = mds
		_rend = rend
		_prts = ParticleList.new(_cs)
		_rnd = Random.new()
		_frt = 0
		_invrt = 0
		_invrtmx = 0
		_time = 0
	}

	init(ps) {
		_ps = ps
		for (m in _mds) {
			m.setup(this)
			m.init()
		}
		_rend.setup(this)
	}

	start() {start(null)}
	start(d) {
		_en = true
		_time = 0
		_frt = 0
		if(d == null) {
			calc_dur()
		} else {
			_cdr = d
		}
	}

	stop() {stop(false)}
	stop(k) {
		_en = false
		_time = 0
		_frt = 0
		if(k) unspawn_all()
	}

	emit() {
		var cnt = 0
		if(_countmx > 0) {
			cnt = random.int(_count, _countmx)
		} else {
			cnt = _count
		}
		cnt = cnt > _cs ? _cs : cnt
		for (i in 0...cnt) {
			spawn()
		}
	}

	spawn() {
		if(_prts.length < _prts.capacity) {
			spawn_p_(_prts.ensure())
		} else if(cache_wrap) {
			var p = _prts.wrap()
			unspawn_p_(p)
			spawn_p_(p)
		}
	}

	unspawn(p) {
		_prts.remove(p)
		unspawn_p_(p)
	}

	unspawn_all() {
		for (p in _prts) {
			for (m in _mds) {
				m.onunspawn(p)
			}
		}
		_prts.clear()
	}

	spawn_p_(p) { 
		for (m in _mds) {
			p.stlife = _lifemx > 0 ? random.float(_life, _lifemx) : _life
			p.life = 0
			p.phase = 0
			m.onspawn(p)
		}
	}

	unspawn_p_(p) { _mds.each{|m|m.onunspawn(p)} }

	update(dt) {
		var p = null
		var i = 0
		var len = _prts.length
		while(i < len) {
			p = _prts[i]
			p.life = p.life + dt
			p.phase = p.life / p.stlife
			if(p.life >= p.stlife) {
				unspawn(p)
				len = _prts.length
			} else {
				i = i+1
			}

		}
		if(_en && _rate > 0) {
			_frt = _frt + dt
			var ir = 0
			while(_frt > 0) {
				emit()
				ir = _ratemx > 0 ? random.float(_invrt, _invrtmx) : _invrt
				if(ir == 0) {
					_frt = 0
					break
				}
				_frt = _frt-ir
			}
			_time = _time + dt
			if(_cdr >= 0 && _time >= _cdr) stop()
		}

		for (m in _mds) {
			m.update(dt)
		}

		for (p in _prts) {
			p.x = p.x+p.vx*dt
			p.y = p.y+p.vy*dt
		}

	}

	draw() { 
		_rend.draw()
	}

	calc_dur() { 
		if(_dr >= 0 && _drm > _dr) {
			_cdr = random.float(_dr, _drm)
		} else {
			_cdr = _dr
		}
	}

	random_1_to_1() { random.float() * 2 - 1 }

}

class ParticleModule {

	enabled { _enabled }
	emitter { _emtr_ }
	particles { _prts_ }

	construct new() {
		_enabled = true
	}

	init() {}
	setup(e) {
		_emtr_= e
		_prts_= _emtr_.particles
	}

	ondestroy() {}

	onspawn(p) {}
	onunspawn(p) {}

	update(dt) {}

}

class FSM {

	current { _current }
	states { _states }
	
	construct new() {
		_states = {}
	}

	add(s) { 
		if (_states.containsKey(s.name)) {
			Fiber.abort("state with name: %(s.name) already exists")
		}
		_states[s.name] = s
		s.init()
	}

	remove(n) { 
		var s = _states[n]
		if (s != null) {
			if (_current == s) {
				_current.onleave(null)
				_current = null
			}
			_states.remove(n)
		}
	}

	set(n) {set(n,null,null)}
	set(n,ed) {set(n,ed,null)}
	set(n,ed,ld) { 
		var s = _states[n]
		if (s != null) {
			if (_current != null) {
				_current.onleave(ld)
			}
			s.onenter(ed)
			_current = s
		}
	}

	update(dt){
		if (_current != null) {
			_current.update(dt)
		}
	}

	draw() { 
		if (_current != null) {
			_current.draw()
		}
	}

}

class Settings {

	static camera_limit { 40 }
	static comet_dist { 48 }
	static comet_rest { 0.5 }

	static ice_force { 8 }
	static sun_hittime { 3 }

	static pl_force { 4 }
	static pl_factor { 1.5 }

	static bh_force { 8 }
	static bh_revforce { 10 }
	
}

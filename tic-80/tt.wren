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
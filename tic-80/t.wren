import "random" for Random

// utils

class DynamicPool {

	construct new(size, create_cb) {
		_items = []
		_cf = create_cb
		_sz = size
		for (i in 0...size) {
			_items.add(_cf.call())
		}
	}

	get() { _items.count > 0 ? _items.removeAt(-1) : _cf.call() }

	put(item) { 
		if(_items.count < _sz) {
			_items.add(item) 
		}
	}

}

class Timer {

	static time(){ 0}

	static init(){
		__timers = []
	}

	static add(t){
		__timers.add(t)
		return t
	}

	static remove(t){
		var ot = null
		for (i in 0...__timers.count) {
			if (ot == __timers[i]) {
				__timers.removeAt(i)
				break
			}
		}
	}

	static schedule(tl){ schedule_from(0, tl, null) }
	static schedule(tl, cb){ schedule_from(0, tl, cb) }

	static schedule_from(ct, tl){ schedule_from(ct, tl, null) }
	static schedule_from(ct, tl, cb){
		var t = Timer.new()
		t.start_from(ct, tl, cb)
		return t
	}

	static update(dt){
		for (t in __timers) {
			if (t.active && !t.finished && t.time_limit >= 0){
				t.update(dt)
			}
		}
	}

	time_limit { _time_limit }
	time_limit=(v) { _time_limit = v }

	loops { _loops }
	loops=(v) { _loops = v }

	active { _active }
	active=(v) { _active = v }
	
	elapsed_time { _time }
	elapsed_time=(v) { _time = v }

	use_timescale { _use_ts }
	use_timescale=(v) { _use_ts = v }

	finished { _finished }
	elapsed_loops { _loops_counter }
	time_left { _time_limit - _time }
	loops_left { _loops - _loops_counter }
	progress { (_time_limit > 0) ? (_time / _time_limit) : 0 }

	construct new(){
		_time = 0
		_time_limit = 0
		_start_time = 0
		_loops = 0
		_loops_counter = 0
		_inarray = false
		_active = true
		_use_ts = true
		_finished = false
	}

	start(tl) { start_from(0, tl, null) }
	start(tl, cb) { start_from(0, tl, cb) }
	start_from(st, tl) { start_from(st, tl, null) }

	start_from(st, tl, cb) {

		stop(false)

		if (!_inarray) {
			Timer.add(this)
			_inarray = true
		}
		
		_active = true
		_finished = false

		if(cb != null){
			_oncomplete = cb
		}

		_time_limit = tl.abs
		_start_time = (_time_limit..st).min
		_time = _start_time

		_loops = 1
		_loops_counter = 0

		return this

	}

	stop() { stop(true) }

	stop(finish) {

		if(!_finished) {
			_finished = true
			_active = false
			
			if (_inarray){
				Timer.remove(this)
				_inarray = false
			}
			
			if (finish && _oncomplete != null) {
				_oncomplete.call()
			}

		}

	}

	oncomplete(cb){
		_oncomplete = cb
		return this
	}

	update(dt){
		if (_use_ts) dt = dt * Game.timescale
		_time = _time + dt
		while (!_finished && _time_limit < _time) {
			_loops_counter = _loops_counter + 1
			
			if (_loops > 0 && (_loops_counter >= _loops)) {
				stop()
				break
			}
			_time = _time - _time_limit
		}
	}
	
}

class Utils {

	static list_remove(l,v){ 
		for (i in 0...l.count) {
			if (l[i] == v) {
				l.removeAt(i)
				return true
			}
		}
		return false
	}
	
	static elegant_pair(x, y) {
		var z = (x >= y) ? (x * x + x + y) : (y * y + x)
		if(z < 0) {
			Fiber.abort("pairing error")
		}
		return z
	}

	static random_point_in_unit_circle(into) {

		var r = Game.random.float().sqrt
		var t = (-1 + (2 * Game.random.float())) * 6.283185307179586 // two PI

		into.x = r * t.cos
		into.y = r * t.sin

		return into
	}

	static rotate(cx,cy,angle,p) {

	    var rad = angle*Num.pi/180
		var s = rad.sin
		var c = rad.cos

		p.x = p.x - cx
		p.y = p.y - cy

		var xnew = p.x * c - p.y * s
		var ynew = p.x * s + p.y * c

		p.x = xnew + cx
		p.y = ynew + cy

		return p

	}


}



class Space {

	x { _x }
	y { _y }
	w { _w }
	h { _h }
	objects { _objs }
	count { _count }

	construct new(x,y,w,h) {

		_x = x
		_y = y
		_w = w
		_h = h
		_hw = w*0.5
		_hh = h*0.5
		_objs = {}
		_count = 0

	}

	check(b) { 
		if (!_objs.containsKey(b.entity)) {
			if (Collision.circle_rect_fast(b.x,b.y,b.r,_x,_y,_x+_w,_y+_h)) {
				_objs[b.entity] = b
				_count = _count + 1
			}
		} else if(!Collision.circle_rect_fast(b.x,b.y,b.r,_x,_y,_x+_w,_y+_h)) {
			_objs.remove(b.entity)
			_count = _count - 1
		}
	}	

	remove(b) { 
		if (_objs.remove(b.entity) != null) {
			_count = _count - 1
		}
	}

	draw() {
		var c = 11
		TIC.print("contacts:%(_count)", 0, 8, 11)
		TIC.rectb(x, y, w, h, c)
		for (o in _objs.values) {
			TIC.circb(o.x, o.y, o.r, 12)
		}
	}

}

class Collision {

	static circle_circle(c1x,c1y,c1r,c2x,c2y,c2r,ci) {

		ci.reset()

		var dx = c1x-c2x
		var dy = c1y-c2y

		var r = c1r + c2r
		var dist2 = dx*dx+dy*dy

		if(dist2 >= r*r) return false

		var dist = dist2.sqrt
		if(dist < 0.001) return false

		var mtd_x = dx * (r - dist) / dist
		var mtd_y = dy * (r - dist) / dist

		ci.separation = (mtd_x * mtd_x + mtd_y * mtd_y).sqrt
		ci.normal.set(mtd_x, mtd_y).divide(ci.separation)

		return true

	}

	static circle_circle_fast(c1x,c1y,c1r,c2x,c2y,c2r) {
		var dx = c1x - c2x
		var dy = c1y - c2y
		var r = c1r + c2r
		return (dx * dx + dy * dy) < (r * r)
	}

	static circle_rect_fast(cx,cy,cr,minx,miny,maxx,maxy) { 
		
		var cx_ = cx
		var cy_ = cy

		if (cx < minx) cx = minx
		if (cx > maxx) cx = maxx
		if (cy < miny) cy = miny
		if (cy > maxy) cy = maxy

	    var dx = cx_ - cx
	    var dy = cy_ - cy

	    return ( dx * dx + dy * dy < cr * cr )

	}

	static aabb_aabb_fast(b1x,b1y,b1w,b1h,b2x,b2y,b2w,b2h ){

		if((b1x - b2x).abs > (b1w + b2w)) return false
		if((b1y - b2y).abs > (b1h + b2h)) return false

		return true
	}

	static solve_pos(c,p) { 
		p.x = p.x + c.separation * c.normal.x
		p.y = p.y + c.separation * c.normal.y
	}

	static solve_vel(c,v,r) { 
		var vn = v.x * c.normal.x + v.y * c.normal.y
		if (vn < 0) {
			var j = -(1 + r) * vn
			v.x = v.x + c.normal.x * j
			v.y = v.y + c.normal.y * j
		}
	}

	static get_contacts(b,into) { 
		var cid = -1
		var c = null
		for (oth in Game.space.objects.values) {
			if (oth != b) {
				if (Collision.circle_circle_fast(b.x,b.y,b.r,oth.x,oth.y,oth.r)) {
					cid = Utils.elegant_pair(b.entity,oth.entity)
					c = into[cid]
					if (c == null) {
						c = Game.contacts_pool.get()
						c.id = cid
						c.entity = b.entity
						c.other = oth.entity
						into[cid] = c
					} else {
						c.remove = false
					}
				}
			}
		}
		// clear contacts
		for (c in into.values) {
			if (c.remove) {
				Game.contacts_pool.put(c)
				into.remove(c.id)
				c.clear()
			} else {
				c.remove = true
			}
		}
	}

	static get_contacts2(b,into) { 

		for (oth in Game.space.objects.values) {
			if (oth != b) {
				var c = Game.contacts_pool.get()
				c.entity = b.entity
				c.other = oth.entity
				into.add(c)
			}
		}

	}

	static remove_contacts2(into) { 

		for (c in into) {
			Game.contacts_pool.put(c)
		}
		into.clear()

	}

}

class CollisionInfo {

	id { _id }
	entity { _entity }
	other { _other }
	normal { _norm }
	separation { _sep }
	remove { _rem }

	id=(v) { _id=v }
	entity=(v) { _entity=v }
	other=(v) { _other=v }
	normal=(v) { _norm=v }
	separation=(v) { _sep=v }
	remove=(v) { _rem=v }

	construct new() {
		_norm = Vector.new()
		_id = -1
		_sep = 0
		_rem = false
	}

	reset() { 
		_norm.set(0,0)
		_sep = 0
	}

	clear() { 
		reset()
		_id = -1
		_rem = false
		_entity = null
		_other = null
	}

}

// renderer
class Drawable {

	x { _x }
	y { _y }
	x=(v) { _x = v }
	y=(v) { _y = v }
	
	ox { _ox }
	oy { _oy }
	ox=(v) { _ox = v }
	oy=(v) { _oy = v }

	visible { _visible }
	visible=(v) { _visible = v }

	layer { _layer }
	layer=(v) { 
		if (_rl != null) {
			_rl.remove(this)
			_layer = v
			_rl = Game.renderer.add(this)
		} else {
			_layer = v
		}
	}

	depth { _depth }
	depth=(v) { _depth = v }

	construct new() {
		_visible = true
		_layer = 0
		_depth = 0
		_x = 0
		_y = 0
		_ox = 0
		_oy = 0
		_rl = null
	}

	init() { 
		_rl = Game.renderer.add(this)
	}

	draw() {}

	destroy() { 
		if (_rl != null) {
			_rl.remove(this)
		}
	}
	
}

class RenderLayer {
	
	construct new() {
		_objects = []
	}

	add(e) { 
		_objects.add(e)
	}

	remove(e) { 
		Utils.list_remove(_objects, e)
	}

	draw() { 
		for (e in _objects){
			if (e.visible) {
				e.draw()
			}
		}
	}

}

class Renderer {

	color { _color }
	color=(v) { _color=v }

	construct new() {
		_color = 0
		_layers_list = []
		_layers = {}
	}

	create_layer(idx) { 
		if (_layers.containsKey(idx)) return
		var rl = RenderLayer.new()
		_layers[idx] = rl
		if (_layers_list.count == 0) {
			_layers_list.add(idx)
		} else {
			insert_sorted_key(_layers_list, idx)
		}
	}

	destroy_layer(idx) { 
		if (_layers.containsKey(idx)) {
			_layers.remove(idx)
			Utils.list_remove(_layers_list, idx)
		}
	}

	add(e) { 
		var rl = _layers[e.layer]
		if (rl != null) rl.add(e)
		return rl
	}

	remove(e) { 
		var rl = _layers[e.layer]
		if (rl != null) rl.remove(e)
		return rl
	}

	process() { 
		TIC.cls(_color)
		for (lid in _layers_list){
			_layers[lid].draw()
		}
	}

	insert_sorted_key(list, key) {
		var result = 0
		var	mid = 0
		var	min = 0
		var	max = list.count - 1
		while (max >= min) {
			mid = min + ((max - min) / 2).floor
			result = list[mid] - key
			if (result > 0) {
				max = mid - 1 
			} else if(result < 0) {
				min = mid + 1
			} else {
				return
			}
		}
		list.insert(result > 0 ? mid : mid + 1, key)
	}

}


class RadialSpawnModule is ParticleModule {

	radius { _r }
	radius=(v) { _r=v }

	construct new(r) {
		super()
		_r = r
		_rnd_point = Vector.new()
	}

	onspawn(p) {

		Utils.random_point_in_unit_circle(_rnd_point)

		p.x = emitter.system.x + emitter.x + _rnd_point.x * _r
		p.y = emitter.system.y + emitter.y + _rnd_point.y * _r

	}

}

class ColorLifeModule is ParticleModule {

	colors { _colors }
	colors=(v) { _colors=v }

	construct new(cl) {
		super()
		_colors = cl
	}

	update(dt) {
		var clen = _colors.count
		particles.each{|p|p.color = _colors[(p.phase*clen).floor]}
	}
	
}

class ScaleLifeModule is ParticleModule {

	construct new(ss,es) {
		super()
		_ss = ss
		_es = es
	}

	update(dt) {
		for (p in particles) {
			var s = (1-p.phase)*_ss+p.phase*_es
			p.w = s
			p.h = s
		}
	}

}

class VelocityModule is ParticleModule {

	construct new(vx,vy) {
		super()
		_vx = vx
		_vy = vy
	}

	construct new(vx,vy,mvx,mvy) {
		super()
		_vx = vx
		_vy = vy
		_mvx = mvx
		_mvy = mvy
	}

	onspawn(p) {
		if (_mvx != null) {
			p.vx = emitter.random.int(_vx,_mvx)
			p.vy = emitter.random.int(_vy,_mvy)
		} else {
			p.vx = _vx
			p.vy = _vy
		}
	}

}

class VelocityLifeModule is VelocityModule {

	construct new(vx,vy,evx,evy) {
		super(vx,vy)
		_evx = evx
		_evy = evy
	}

	onspawn(p) {
		p.vx = _vx
		p.vy = _vy
	}

	update(dt) {
		for (p in particles) {
			var vx = (1-p.phase)*_vx+p.phase*_evx
			var vy = (1-p.phase)*_vy+p.phase*_evy
			p.vx = vx
			p.vy = vy
		}
	}

}

class GravityModule is ParticleModule {

	x { _x }
	y { _y }
	x=(v) { _x=v }
	y=(v) { _y=v }

	construct new(x,y) {
		super()
		_x = x
		_y = y
	}

	update(dt) {
		for (p in particles) {
			p.vx = p.vx + _x * dt
			p.vy = p.vy + _y * dt
		}
	}

}

class ParticleRenderer {

	emitter { _emtr_ }
	particles { _prts_ }

	construct new() {}

	setup(e) {
		_emtr_= e
		_prts_= _emtr_.particles
	}
	
}

class CircleDrawModule is ParticleRenderer {
	construct new() { super() }
	draw() { particles.each{|p|TIC.circ(p.x-Camera.x, p.y-Camera.y, p.w*0.5, p.color)} }
}

class FPS {

	static value { __vl }

	static init() {
		__vl = 0
		__frms = 0
		__lt = 0
	}
	
	static update() {
		if (TIC.time() - __lt <= 1000) {
			__frms = __frms+1
		} else {
			__vl = __frms
			__frms = 0
			__lt = TIC.time()
		}
	}
	
}


// ecs
class IdBuffer {

	used { _used }

	construct new(n) {
		_cp = n
		_used = 0
		_mask = n - 1
		_head = 0
		_tail = 0
		if((_mask & n) != 0) Fiber.abort("capacity %(n) must be power of two")

		_buffer = List.filled(n, 0)
		for (i in 0...n) {
			_buffer[i] = i
		}
	}

	pop() {
		if(_used >= _cp) Fiber.abort("Out of entities, max allowed %(_cp)")
		_used = _used + 1
		var ppat = _head
		_head = ppat + 1
		_head = _head & _mask
		return _buffer[ppat]
	}

	push(v) {
		_used = _used - 1
		var plat = _tail
		_buffer[plat] = v
		plat = plat + 1
		_tail = plat & _mask
	}

	clear(){
		_head = 0
		_tail = 0
		_buffer = List.filled(_cp, 0)
		for (i in 0..._cp) {
			_buffer[i] = i
		}
	}

}

class BitVector {

	construct new(count) {
		_list = List.filled((count/32).ceil, 0)
		_lrs = Fn.new { |x,n|(x >> n) & ~(((0x1 << 32) >> n) << 1) }
	}

	[i]{
		var adress = _lrs.call(i, 5)
		var mask = 0x1 << (i & 0x1F)
		return (_list[adress] & mask) != 0
	}

	[i]=(v){
		var adress = _lrs.call(i, 5)
		var mask = 0x1 << (i & 0x1F)
		_list[adress] = v ? _list[adress] | mask : _list[adress] & ~mask
	}

	clear () { 
		for (i in 0..._list.count) {
			_list[i] = 0
		}
	}

}

class IntVector is Sequence {

	construct new(n) {
		_idxs = List.filled(n, -1)
		_buff = List.filled(n, 0)
		_len = 0
	}

	length { _len }

	add(id){
		_buff[_len] = id
		_idxs[id] = _len
		_len = _len + 1
	}

	has(idx){_idxs[idx] != -1}

	[i]{_buff[i]}

	remove(id){
		var idx = _idxs[id]
		var last_idx = _len - 1
		if(idx != last_idx) {
			var last_id = _buff[last_idx]
			_buff[idx] = last_id
			_idxs[last_id] = idx
		}
		_idxs[id] = -1
		_len = _len - 1
	}

	clear () { 
		_idxs.each {|id| id = -1 } // bug
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
			lst.add(_buff[i])
		}
		return lst.toString
	}

}

class BitFlag {

	bits0 { _b0 }
	bits1 { _b1 }

	construct new() {

		_b0 = 0
		_b1 = 0
		
	}

	set_true(b) {

		if (b < 33) {
			_b0 = _b0 | 1 << (b - 1)
		} else if(b < 65) {
			_b1 = _b1 | 1 << (b - 33)
		}

	}

	set_false(b) {

		if (b < 33) {
			_b0 = _b0 & ~(1 << (b - 1 ))
		} else if (b < 65) {
			_b1 = _b1 & ~(1 << (b - 33))
		}

	}

	flip() {

		_b0 = ~_b0
		_b1 = ~_b1

	}

	clear() {

		_b0 = 0
		_b1 = 0

	}

	contains(f) {

		if (_b0 & f.bits0 == f.bits0 && 
			_b1 & f.bits1 == f.bits1) {
			return true
		}
		
		return false

	}
	
}

class Signal {

	length { _lsn.count }

	construct new() {
		_lsn = []
		_chk = false
	}

	add(h){
		if (h is Fn) {
			if (!has(h)) {
				_lsn.add(h)
			} else {
				Fiber.abort("Signal: attempted to add the same listener twice")
			}
		}
	}

	remove(h){
		for (i in 0..._lsn.count) {
			if (_lsn[i] == h) {
				_lsn[i] = null
				_chk = true
				break
			}
		}
	}

	has(h){ _lsn.contains(h) }

	emit(args){

		var idx = 0
		var count = _lsn.count
		var fn = null
		while(idx < count) {
			fn = _lsn[idx]
			if(fn != null) fn.call(args)
			idx = idx + 1
		}

		if (_chk) {
			while(count > 0) {
				if(_lsn[count-1] == null) _lsn.removeAt(count-1)
				count = count - 1
			}
			_chk = false
		}

	}

	clear(){
		_lsn.clear()
		_chk = false
	}

}


class Components {

	static get(ccl) { World.current.comps_get(ccl) }
	static set(e,comp) { set(e,comp,null) }
	static set(e,comp,ctype) { World.current.component_set(e,comp,ctype) }

	construct new(world, ctype) {
		_world = world
		_type = ctype
		_comps = List.filled(_world.capacity, null)
		_removed_mask = BitVector.new(_world.capacity)
		_removed = []
	}

	set(e, c){ set_(e, c, true) }

	set_(e, c, ev){
		remove(e)
		_comps[e] = c
		_world.oncompadded(e, _type, ev)
	}

	get(e){ _comps[e] }

	has(e){ _comps[e] != null }

	remove(e){
		if (has(e)) {
			_world.oncompremoved(e, _type)
			if (!_removed_mask[e]) {
				_removed_mask[e] = true
				_removed.add(e)
			}
// 			_comps[e] = null
		}
	}

	clear(){
		for (i in 0..._comps.length) {
			if(_comps[i] != null) {
				world.oncompremoved(i, _type)
				_comps[i] = null
			}
		}
	}

	update() { 
		if (_removed.count > 0) {
			for (e in _removed) {
				_comps[e] = null
			}
			_removed_mask.clear()
			_removed.clear()
		}	
	}

	toString {
		var cname = ""
		for (t in _world.comp_types.keys) {
			if (_type == _world.comp_types[t]) cname = t
		}
		var comps = 0
		var arr = []
		for (j in 0..._comps.count) {
			if(_comps[j] != null) {
				arr.add(j)
				comps = comps + 1
			}
		}
		return "%(cname): ents:%(comps) %(arr)"
	}

}

class Family is Sequence {

	static create(name, incl) { create(name, incl, null) }
	static create(name, incl, excl) { World.current.family_create(name, incl, excl) }
	static get(name) { World.current.family_get(name) }
	static remove(name) { World.current.family_remove(name) }

	name { _name }
	onadded { _onadd }
	onremoved { _onrem }

	construct new_(world, name, incl, excl) {
		_world = world
		_name = name
		_onadd = Signal.new()
		_onrem = Signal.new()
		_incl = BitFlag.new()
		_excl = BitFlag.new()
		_excl.flip()
		_ents = IntVector.new(_world.capacity)

		incl.each {|c| _incl.set_true(_world.comp_get_type(c)+1) } 

		if (excl != null) excl.each {|c| _incl.set_false(_world.comp_get_type(c)+1) } 
		
		// private functions
		_match_entity = Fn.new{|e|
			var flags = _world.comp_flags[e]
			return flags.contains(_incl) && _excl.contains(flags)
		}
	}

	has(e) { _ents.has(e) }

	check(e) {
		if(!has(e)) {
			if(_match_entity.call(e)){
				_ents.add(e)
				_onadd.emit(e)
			}
		} else if(!_match_entity.call(e)) {
			_onrem.emit(e)
			_ents.remove(e)
		}
	}

	remove(e) { 
		if(has(e)) {
			_onrem.emit(e)
			_ents.remove(e)
		}
	}

	iterate(i) {
		if (i == null) i = 0 else i = i + 1
		return i >= _ents.length ? null : i
	}

	iteratorValue(i) { _ents[i] }

	toString { "%(_name):%(_ents.toString)" }
	
}


class Processor {

	static add(p) { add(p,null,true) }
	static add(p,pr) { add(p,pr,true) }
	static add(p,pr,en) { World.current.processor_add(p,pr,en)}
	static get(pc) { World.current.processor_get(pc) }
	static remove(pc) { World.current.processor_remove(pc) }

	active{_active}
	active=(v){_active = v}

	priority{_priority}
	priority=(v){_priority = v}
	
	construct new() {
		_priority = 0
		_active = false
	}

	setup_(w) { _world = w }

	init(){}
	onadded(){}
	onremoved(){}
	onenabled(){}
	ondisabled(){}
	update(dt){}

}

class Entity {
	static create() { World.current.entity_create() }
	static destroy(e) { World.current.entity_destroy(e) }
	static has(e) { World.current.entity_alive(e) }
}


// components
class Bounds {
	
	entity { _e }
	x { _x }
	y { _y }
	r{ _r }

	x=(v) { _x=v }
	y=(v) { _y=v }
	r=(v) { _r=v }

	contacts {_cnt}
	tag {_tp}

	construct new(e,x,y,r,tp) {
		_e = e
		_x = x
		_y = y
		_r = r
		_tp = tp
		_cnt = {}
	}

}

class Star {

	paralax { _p }

	construct new(p) {
		_p = p
	}

}

class Planet {

	density { _d }
	radius { _r }
	radius=(v) { _r=v }
	grav_radius { _gr }
	mass { _m }

	construct new(r,d) {
		_r = r
		_gr = r+(d)
		_d = d
		_m = Maths.get_sphere_mass(r,1)
	}

	update_mass() { 
		_m = Maths.get_sphere_mass(_r,1)
	}

}

class Comet is Planet {

	polarity { _pol }
	polarity=(v) { _pol=v }

	hitcd { _hcd }
	hitcd=(v) { _hcd=v }
	sunhit { _sh }
	sunhit=(v) { _sh=v }

	construct new(r,d) {
		super(r,d)
		_pol = -1
		_hcd = 0
		_sh = 0
	}

}

class Text {

	x { _x }
	y { _y }
	scale { _sc }
	color { _clr }
	text { _txt }
	x=(v) { _x=v }
	y=(v) { _y=v }
	scale=(v) { _sc=v }
	color=(v) { _clr=v }
	text=(v) { _txt=v }

	construct new(txt,x,y,clr,sc) {
		_txt = txt
		_x = x
		_y = y
		_sc = sc
		_clr = clr
	}

	draw() { 
		TIC.print(_txt,_x,_y,_clr,false,_sc)
	}
	
}

class Lines is Drawable {

	lines { _lns }
	lines2 { _lns2 }
	color { _c }
	color2 { _c2 }
	color=(v) { _c=v }
	color2=(v) { _c2=v }
	
	construct new(n,c,c2) {
		super()
		_c = c
		_c2 = c2
		_lns = []
		_lns2 = []
		for (i in 0...n) {
			_lns.add(Vector.new())
			_lns2.add(Vector.new())
		}
	}

	draw() { 
		_lns2.each{|d| TIC.pix(d.x-Camera.x, d.y-Camera.y, color2) }
		_lns.each{|d| TIC.pix(d.x-Camera.x, d.y-Camera.y, color) }
	}

}

class PlanetImage is Drawable {

	radius { _r }
	radius2 { _r2 }
	color { _c }
	color2 { _c2 }

	radius2=(v) { _r2=v }
	radius=(v) { _r=v }
	color=(v) { _c=v }
	color2=(v) { _c2=v }
	
	construct new(r,r2,c,c2) {
		super()
		_r = r
		_r2 = r2
		_c = c
		_c2 = c2
		layer = 2
	}

	draw() { 
		TIC.circb(x, y, radius2, color2)
		TIC.circ(x, y, radius, color)
	}

}

class BlackholeImage is Drawable {

	radius { _r }
	radius2 { _r2 }
	color { _c }
	color2 { _c2 }

	radius2=(v) { _r2=v }
	radius=(v) { _r=v }
	color=(v) { _c=v }
	color2=(v) { _c2=v }
	
	construct new(r,r2,c,c2) {
		super()
		_r = r
		_r2 = r2
		_c = c
		_c2 = c2
		layer = 2
	}

	draw() { 
		for (i in radius..radius2) {
			if (i%4 == 0) {
				TIC.circb(x, y, i, color2)
			}
		}
		TIC.circ(x, y, radius, color)
	}

}

class IceImage is Drawable {

	radius { _r }
	color { _c }
	color=(v) { _c=v }
	

	construct new(r,c) {
		super()
		_r = r
		_c = c
		layer = 2
		_tvert = [
			Vector.new(-1,-1),
			Vector.new(1,-1),
			Vector.new(1,1),
			Vector.new(-1,1),
		]
		_tind = [
			3,0,1,
			1,2,3
		]

		_tmpvec = Vector.new()
		for (v in _tvert) {
			Utils.random_point_in_unit_circle(_tmpvec).multiply(0.25)
			v.add(_tmpvec)
		}
		_av = Game.random.int(-60,60)

	}

	draw() { 

		for (v in _tvert) {
			Utils.rotate(0,0, _av/60, v)
		}

		var n = 0
		for (i in 0...(_tind.count/3).floor) {
			n = i*3
			TIC.tri(_tvert[_tind[n]].x*_r+x, _tvert[_tind[n]].y*_r+y, _tvert[_tind[n+1]].x*_r+x, _tvert[_tind[n+1]].y*_r+y,_tvert[_tind[n+2]].x*_r+x, _tvert[_tind[n+2]].y*_r+y, color)
		}

	}
}

class Circle is Drawable {

	radius { _r }
	color { _c }

	radius=(v) { _r=v }
	color=(v) { _c=v }
	
	construct new(r,c,l) {
		super()
		_r = r
		_c = c
		layer = l
	}

	draw() { 
		TIC.circ(x-ox, y-oy, radius, color)
	}

}

class CometImage is Drawable {

	radius { _r }
	color { _c }
	angvel { _av }

	radius=(v) { _r=v }
	color=(v) { _c=v }
	angvel=(v) { _av=v }
	
	construct new(r,c,l) {
		super()
		_r = r
		_c = c
		layer = l
		_tvert = [
			Vector.new(-0.7,-0.7),
			Vector.new(0,-1),
			Vector.new(0.7,-0.7),
			Vector.new(1,0),
			Vector.new(0.7,0.7),
			Vector.new(0,1),
			Vector.new(-0.7,0.7),
			Vector.new(-1,0)
		]
		_tind = [
			7,0,1,
			1,2,3,
			3,4,5,
			5,6,7,
			5,7,1,
			1,3,5
		]

		_tmpvec = Vector.new()
		for (v in _tvert) {
			Utils.random_point_in_unit_circle(_tmpvec).multiply(0.25)
			v.add(_tmpvec)
		}
		_av = Game.random.int(-60,60)

	}

	draw() { 

		if (_av.abs > 30) {
			_av = _av * 0.999
		}

		for (v in _tvert) {
			Utils.rotate(0,0, _av/60, v)
		}

		var n = 0
		for (i in 0...(_tind.count/3).floor) {
			n = i*3
			TIC.tri(_tvert[_tind[n]].x*_r+x, _tvert[_tind[n]].y*_r+y, _tvert[_tind[n+1]].x*_r+x, _tvert[_tind[n+1]].y*_r+y,_tvert[_tind[n+2]].x*_r+x, _tvert[_tind[n+2]].y*_r+y, color)
		}
	}

}


class Position is Vector {

	construct new(x,y) {
		super(x,y)
	}

}

class Velocity is Vector {

	damping { _damp }
	damping=(v) { _damp=v }

	construct new(x,y, d) {
		super(x,y)
		_damp = d
	}

}


// processors
class DrawProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() { 
		_ln_comps = Components.get(Lines)
		_draw_comps = Components.get(Drawable)
		_star_comps = Components.get(Star)
		_pos_comps = Components.get(Position)
		_ps_comps = Components.get(ParticleSystem)
		_cm_comps = Components.get(Comet)
		_comets = Family.get("comets")
		_planets = Family.get("planets")
		_stars = Family.get("stars")
		_particles = Family.get("particles")

		_draw_added = Fn.new {|e|
			var p = _pos_comps.get(e)
			var d = _draw_comps.get(e)
			var s = _star_comps.get(e)
			if (s != null) {
				d.x = (p.x - (Camera.x*s.paralax)).floor
				d.y = (p.y - (Camera.y*s.paralax)).floor
			} else {
				d.x = (p.x - Camera.x).floor
				d.y = (p.y - Camera.y).floor
			}
			d.init()

		}

		_cm_added = Fn.new {|e|
			var p = _pos_comps.get(e)
			var d = _draw_comps.get(e)
			d.x = (p.x - Camera.x).floor
			d.y = (p.y - Camera.y).floor
			_ln_comps.get(e).init()
			d.init()
		}

		_cm_removed = Fn.new {|e|
			_ln_comps.get(e).destroy()
			_draw_comps.get(e).destroy()
		}

		_ps_added = Fn.new {|e|
			var d = _ps_comps.get(e)
			d.init()
		}

		_draw_removed = Fn.new {|e|
			_draw_comps.get(e).destroy()
		}

		_planets.onadded.add(_draw_added)
		_planets.onremoved.add(_draw_removed)
		_comets.onadded.add(_cm_added)
		_comets.onremoved.add(_cm_removed)
		_stars.onadded.add(_draw_added)
		_stars.onremoved.add(_draw_removed)
		_particles.onadded.add(_ps_added)
	}

	ondisabled() { 
		_planets.onadded.remove(_draw_added)
		_planets.onremoved.remove(_draw_removed)
		_comets.onadded.remove(_cm_added)
		_comets.onremoved.remove(_cm_removed)
		_stars.onadded.remove(_draw_added)
		_stars.onremoved.remove(_draw_removed)
		_particles.onadded.remove(_ps_added)
	}

	set_dr_pos(e) { 
		var p = _pos_comps.get(e)
		var d = _draw_comps.get(e)
		d.x = (p.x - Camera.x).floor
		d.y = (p.y - Camera.y).floor
	}

	update(dt) { 
		var d
		var p
		var s

		for (e in _comets) {
			set_dr_pos(e)
		}

		for (e in _planets) {
			set_dr_pos(e)
		}
		for (e in _stars) {
			p = _pos_comps.get(e)
			d = _draw_comps.get(e)
			s = _star_comps.get(e)
			d.x = (p.x - (Camera.x*s.paralax)).floor
			d.y = (p.y - (Camera.y*s.paralax)).floor
		}
		
	}
	
}

class CometProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() { 
		_comet_comps = Components.get(Comet)
		_ln_comps = Components.get(Lines)
		_b_comps = Components.get(Bounds)
		_planet_comps = Components.get(Planet)
		_dr_comps = Components.get(Drawable)
		_pos_comps = Components.get(Position)
		_vel_comps = Components.get(Velocity)
		_ps_comps = Components.get(ParticleSystem)
		_comets = Family.get("comets")
		_planets = Family.get("planets")
		_nsup = 1024
		_btmp = Bounds.new(0,0,0,0,null)
		_vtmp = Vector.new(0,0)
		_ptmp = Vector.new(0,0)
		_cont = []

	}

	ondisabled() { 
		_planet_comps = null
		_comet_comps = null
		_pos_comps = null
		_vel_comps = null
		_planets = null
		_comets = null
	}

	hit(e, burst) { 
		Camera.shake(6)

		var cm = _comet_comps.get(e)
		var ps = _ps_comps.get(e)
		var dr = _dr_comps.get(e)
		var b = _b_comps.get(e)
		cm.radius = cm.radius -1
		if (cm.radius <= 0) {
			cm.radius = 1 // dead
			burst = true
			_comet_comps.remove(e)
			ps.stop()
			TIC.sfx(20,20,-1,1,15)
			TIC.sfx(16,20,-1,0,15)
			Timer.schedule(1,Fn.new {
				Game.fsm.set("gameover")
			})
		} else {
			TIC.sfx(19,20,-1,1,15)
		}
		b.r = cm.radius
		ps.emitters[0].modules[0].radius = cm.radius
		ps.emitters[2].modules[0].radius = cm.radius+2
		dr.radius = cm.radius
		dr.angvel = Game.random.int(-360,360)
		if (burst) {
			ps.emitters[1].emit()
		}
		Game.remove_score(4)
		cm.hitcd = 1
		cm.update_mass()
	}

	grow(e, burst) { 
		var cm = _comet_comps.get(e)
		var ps = _ps_comps.get(e)
		var dr = _dr_comps.get(e)
		var b = _b_comps.get(e)
		cm.radius = cm.radius + 0.5
		if (cm.radius > 28) {
			cm.radius = 28
		}
		b.r = cm.radius
		ps.emitters[0].modules[0].radius = cm.radius
		ps.emitters[2].modules[0].radius = cm.radius+2
		dr.radius = cm.radius
		Game.add_score(8)
		TIC.sfx(18,30,-1,1,15)

		cm.update_mass()
	}

	update(dt) { 
		var vel
		var pos
		var pos_b
		var pl
		var cm
		var dr
		var dist
		var ps
		var b
		var ln
		var contacts
		Game.speed = Maths.lerp(Game.chances[0][8], Game.chances[1][8], Game.prog) * Game.gravity

		for (e in _comets) {
			cm = _comet_comps.get(e)
			pos = _pos_comps.get(e)
			vel = _vel_comps.get(e)
			ps = _ps_comps.get(e)
			b = _b_comps.get(e)
			dr = _dr_comps.get(e)
			ln = _ln_comps.get(e)

			contacts = b.contacts

			vel.x = Game.speed

			if (TIC.btn(4)) {
				cm.polarity = -1
				TIC.sfx(1,24,8,0,2)
			} else {
				cm.polarity = 1
			}

			Collision.get_contacts(b,contacts)

			if (cm.hitcd > 0) {
				cm.hitcd = cm.hitcd - dt
			} else {
				cm.hitcd = 0
			}

			var grmodule = ps.emitters[2].modules[3]
			grmodule.x = 0
			grmodule.y = 0
			ps.emitters[2].enabled = false
			var gf = Game.gravity

			var at_sun = false
			var other = null
			var velb = null
			for (c in contacts.values) {
				velb = _vel_comps.get(c.other)
				other = _b_comps.get(c.other)
				pl = _planet_comps.get(c.other)
				pos_b = _pos_comps.get(c.other)
				if (other.tag == "planet" || other.tag == "sun" || other.tag == "blackhole" || other.tag == "ice") {
					if (Collision.circle_circle(pos.x,pos.y,cm.radius,pos_b.x,pos_b.y,pl.grav_radius,c)) {
						var ima = 1 / cm.mass
						var imb = 1 / pl.mass
						var ims = ima + imb
						var imp_n = c.separation / pl.grav_radius / ims
						if (other.tag == "sun") {
							ps.emitters[2].enabled = true
							grmodule.x = grmodule.x + c.normal.x * imp_n * ima * 1000 * gf
							grmodule.y = grmodule.y + c.normal.y * imp_n * ima * 1000 * gf
							at_sun = true
						}

						var sign = pos.y > pos_b.y ? 1 : -1

						if (other.tag == "blackhole") {
							vel.y = vel.y - imp_n * ims * sign * Settings.bh_force * gf
							if (cm.polarity < 0) {
								vel.y = vel.y + imp_n * ims * sign * Settings.bh_revforce * gf
							}
							TIC.sfx(21,24,16,0,15)

						} else if(other.tag == "sun" || other.tag == "planet"){

							var f_ = 1
							if (cm.polarity < 0) f_ = Settings.pl_factor
							vel.y = vel.y - imp_n * ima * sign * cm.polarity * f_ * Settings.pl_force * gf
							if (other.tag == "sun") TIC.sfx(17,60,16,0,10)

						} else if(other.tag == "ice"){
							velb.x = velb.x + c.normal.x * ims * imp_n * Settings.ice_force * gf
							velb.y = velb.y + c.normal.y * ims * imp_n * Settings.ice_force * gf
						}

						if (c.separation > pl.grav_radius - pl.radius){

							if (other.tag == "blackhole") {
								cm.radius = cm.radius - (4..cm.radius*0.5).max.floor
								if (cm.hitcd == 0) hit(e,true)
							} else if (other.tag == "ice") {
								grow(e, false)
								Entity.destroy(c.other)
							} else {
								if (pl.radius < cm.radius) {
									Game.add_score(pl.radius)
									var ps_other = _ps_comps.get(c.other)
									ps_other.x = pos_b.x
									ps_other.y = pos_b.y
									ps_other.emitters[0].emit()
									TIC.sfx(22,10,-1,1,15)

									_dr_comps.remove(c.other)
									_b_comps.remove(c.other)
									contacts.remove(c.id)
								} else {
									c.separation = c.separation - (pl.grav_radius - pl.radius)
									Collision.solve_vel(c,vel,Settings.comet_rest)
									Collision.solve_pos(c,pos)

									if (cm.hitcd == 0) hit(e,true)
									
								}
							}

						}
					}
				}

			}

			if (at_sun) {
				cm.sunhit = cm.sunhit - dt
				if (cm.sunhit <= 0) {
					cm.sunhit = Settings.sun_hittime
					hit(e,false)
				}
			} else {
				if (cm.sunhit < Settings.sun_hittime) {
					cm.sunhit = cm.sunhit + dt
				} else {
					cm.sunhit = Settings.sun_hittime
				}
			}

			if (vel.y.abs < 0.1) vel.y = 0

			var lim = Settings.camera_limit
			// cam
			if (pos.y-Camera.y < cm.radius+lim) {
				Camera.y = Camera.y - (cm.radius+lim-pos.y+Camera.y)
			} else if (pos.y-Camera.y > Screen.height-cm.radius-lim) {
				Camera.y = Camera.y - (Screen.height-cm.radius-lim-pos.y+Camera.y)
				
			}

			ps.x = pos.x
			ps.y = pos.y

			if (cm.polarity > 0) {
				dr.color = 11
			} else {
				dr.color = 3

			}
			ps.emitters[0].modules[2].colors[0] = dr.color
			Camera.x = pos.x - Settings.comet_dist
// 			var cl = System.clock

// 			trajectory stuff
			Collision.get_contacts2(_btmp,_cont)

			getnextpos(pos,vel,cm,cm.polarity,ln.lines)
			getnextpos(pos,vel,cm,cm.polarity*-1,ln.lines2)

			Collision.remove_contacts2(_cont)

// 			TIC.trace("elapsed: %(System.clock-cl)")

		}

		
	}

	getnextpos(p,v,cm,pol,into) { 
		var damp = v.damping
		var gf = Game.gravity
		_ptmp.set(p.x,p.y)
		_vtmp.set(v.x,v.y)
		_btmp.x = p.x - Camera.x
		_btmp.y = p.y - Camera.y
		_btmp.r = cm.radius
		var other
		var pl
		var pos_b
		var ni = 0
		var dead = false
		for (i in 0...into.count*4) {
			_vtmp.y = _vtmp.y * damp
			_ptmp.x = _ptmp.x + _vtmp.x * Game.dt
			_ptmp.y = _ptmp.y + _vtmp.y * Game.dt
			_btmp.x = _ptmp.x - Camera.x
			_btmp.y = _ptmp.y - Camera.y
			_vtmp.x = Game.speed

			if (_vtmp.y.abs < 0.1) _vtmp.y = 0
			
			for (c in _cont) {
				other = _b_comps.get(c.other)
				if (other.tag == "planet" || other.tag == "sun" || other.tag == "blackhole") {

					pl = _planet_comps.get(c.other)
					pos_b = _pos_comps.get(c.other)

					if (Collision.circle_circle(_ptmp.x,_ptmp.y,cm.radius,pos_b.x,pos_b.y,pl.grav_radius,c)) {
						var ima = 1 / cm.mass
						var imb = 1 / pl.mass
						var ims = ima + imb
						var imp_n = c.separation / pl.grav_radius / ims
						var sign = _ptmp.y > pos_b.y ? 1 : -1
						if (other.tag == "blackhole") {

							_vtmp.y = _vtmp.y - imp_n * ims * sign * Settings.bh_force * gf
							if (pol < 0) {
								_vtmp.y = _vtmp.y + imp_n * ims * sign * Settings.bh_revforce * gf
							}

						} else if(other.tag == "sun" || other.tag == "planet"){

							var f_ = 1
							if (pol < 0) f_ = Settings.pl_factor
							_vtmp.y = _vtmp.y - imp_n * ima * sign * pol * f_ * Settings.pl_force * gf

						}

					}
				}
			}

			if (i%4 == 0) {
				into[ni].set(_ptmp.x, _ptmp.y)
				ni = ni+1
			}

		}
		
	}
	
}


class PosVelProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() { 
		_pos_comps = Components.get(Position)
		_vel_comps = Components.get(Velocity)
		_pos_vel = Family.get("pos_vel")
	}

	update(dt) { 
		var p
		var v
		for (e in _pos_vel) {
			p = _pos_comps.get(e)
			v = _vel_comps.get(e)
			v.x = v.x * v.damping
			v.y = v.y * v.damping
			p.x = p.x + v.x * dt
			p.y = p.y + v.y * dt
		}

	}
	
}

class SpawnProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() { 
		_planet_comps = Components.get(Planet)
		_pos_comps = Components.get(Position)
		_star_comps = Components.get(Star)
		_planets = Family.get("planets")
		_stars = Family.get("stars")
		_snextdist = 0
		var ch = Game.chances[0]
		_pnextdist = Game.random.int(ch[0],ch[1])
		_sunnext = Game.random.int(ch[2],ch[3])
		_dhnext = Game.random.int(ch[4],ch[5])
		_icenext = Game.random.int(ch[6],ch[7])
		_last_star = null
		_last_cam = 0
	}

	ondisabled() { 
		_planet_comps = null
		_pos_comps = null
		_planets = null
	}

	update(dt) { 

		var pos
		var pl
		var s
		var ch = Game.chances
		var cp = Camera.x
		var t = Game.prog

		var spp = Camera.x+Screen.width

		var rmin = 0
		var rmax = 0

		while (_pnextdist < spp) {
			var r = Game.random.int(2,8)
			var d = Game.random.int(8*r,16*r)
			var gr = r+d
			var sy = Game.random.int(Camera.y-Screen.height*1.5,Camera.y+Screen.height+Screen.height*1.5)
			var sx = _pnextdist+gr
			var e = EntityCreator.planet(sx,sy,r,d)
			rmin = Maths.lerp(ch[0][0],ch[1][0],t)
			rmax = Maths.lerp(ch[0][1],ch[1][1],t)
			_pnextdist = _pnextdist + Game.random.int(rmin,rmax)
		}

		while (_sunnext < spp) {
			var r = Game.random.int(8,24)
			var d = Game.random.int(4*r,8*r)
			var gr = r+d
			var sy = Game.random.int(Camera.y-(Screen.height*1.5),Camera.y+Screen.height+(Screen.height*1.5))
			var sx = _sunnext+gr
			var e = EntityCreator.sun(sx,sy,r,d)
			rmin = Maths.lerp(ch[0][2],ch[1][2],t)
			rmax = Maths.lerp(ch[0][3],ch[1][3],t)
			_sunnext = _sunnext + Game.random.int(rmin,rmax)
		}

		while (_dhnext < spp) {
			var r = Game.random.int(1,4)
			var d = Game.random.int(16*r,32*r)
			var gr = r+d
			var sy = Game.random.int(Camera.y-(Screen.height*1.5),Camera.y+Screen.height+(Screen.height*1.5))
			var sx = _dhnext+gr
			var e = EntityCreator.blackhole(sx,sy,r,d)
			rmin = Maths.lerp(ch[0][4],ch[1][4],t)
			rmax = Maths.lerp(ch[0][5],ch[1][5],t)
			_dhnext = _dhnext + Game.random.int(rmin,rmax)
		}

		while (_icenext < spp) {
			var sy = Game.random.int(Camera.y-(Screen.height*1.5),Camera.y+Screen.height+(Screen.height*1.5))
			var sx = _icenext+87
			var e = EntityCreator.ice(sx,sy)
			rmin = Maths.lerp(ch[0][6],ch[1][6],t)
			rmax = Maths.lerp(ch[0][7],ch[1][7],t)
			_icenext = _icenext + Game.random.int(rmin,rmax)
		}

		while (_snextdist < spp) {

			var sy = Game.random.int(Camera.y-(Screen.height*0.5),Camera.y+Screen.height+(Screen.height*0.5))
			var sx = _snextdist+4

			var e = EntityCreator.star(0,0)
			var s = _star_comps.get(e)
			var spos = _pos_comps.get(e)
			spos.x = Camera.x*s.paralax+(sx-Camera.x)
			spos.y = Camera.y*s.paralax+(sy-Camera.y)
			_snextdist = _snextdist + Game.random.int(32,96)

		}

		for (e in _planets) {
			pos = _pos_comps.get(e)
			pl = _planet_comps.get(e)
			if (pos.x+pl.grav_radius < Camera.x-4) {
				Entity.destroy(e)
			}
		}

		for (e in _stars) {
			pos = _pos_comps.get(e)
			s = _star_comps.get(e)

			if (pos.x-Camera.x*s.paralax < -4) {
				Entity.destroy(e)
			}
		}
		
	}
	
}

class ParticlesProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() { 
		_ps_comps = Components.get(ParticleSystem)
		_particles = Family.get("particles")

		_ps_added = Fn.new {|e|

		}

		_ps_removed = Fn.new {|e|
			var ps = _ps_comps.get(e)
			ps.stop(true)
		}

		_particles.onadded.add(_ps_added)
		_particles.onremoved.add(_ps_removed)
	}

	ondisabled() { 
		_particles.onadded.remove(_ps_added)
		_particles.onremoved.remove(_ps_removed)
		_particles = null
		_ps_comps = null
	}

	update(dt) { 

		for (e in _particles) {
			_ps_comps.get(e).update(dt)
		}
		
	}
	
}

class BoundsProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() { 
		_b_comps = Components.get(Bounds)
		_p_comps = Components.get(Position)
		_bounds = Family.get("bounds")

		_b_added = Fn.new {|e|
			var b = _b_comps.get(e)
			var p = _p_comps.get(e)
			b.x = p.x
			b.y = p.y
			Game.space.check(b)
		}

		_b_removed = Fn.new {|e|
			var b = _b_comps.get(e)
			Game.space.remove(b)
		}

		_bounds.onadded.add(_b_added)
		_bounds.onremoved.add(_b_removed)
	}

	ondisabled() { 
		_bounds.onadded.remove(_b_added)
		_bounds.onremoved.remove(_b_removed)
		_b_comps = null
		_p_comps = null
		_bounds = null
	}

	update(dt) { 
		var p
		var b
		for (e in _bounds) {
			b = _b_comps.get(e)
			p = _p_comps.get(e)
			b.x = p.x - Camera.x
			b.y = p.y - Camera.y
			Game.space.check(b)
		}
		
	}
	
}

class CameraProcessor is Processor {

	construct new() {
		super()
	}

	onenabled() {
		_shake_vector = Vector.new()
	}

	update(dt) { 

		if (Camera.shaking) {
			Utils.random_point_in_unit_circle(_shake_vector)
			_shake_vector.multiply(Camera.shake_amount)
			Camera.shake_amount = Camera.shake_amount * 0.9

			if (Camera.shake_amount < 0.1) {
				Camera.shaking = false
			}
			Camera.x = Camera.x + _shake_vector.x
			Camera.y = Camera.y + _shake_vector.y
		}
		
	}

}



// create
class EntityCreator {

	static planet(x,y,r,d) { 

		var e = Entity.create()
		var gr = r+d
		var c = 7

		var rnd = Game.random.float()

		if (rnd < 0.25) {
			c = 6
		} else if (rnd < 0.5) {
			c = 9
		} else if (rnd < 0.75) {
			c = 1
		} else if (rnd < 0.85) {
			c = 6
		}

		Components.set(e, Planet.new(r,d))
		Components.set(e, Position.new(x,y))
		Components.set(e, Velocity.new(0,0,0.99))
		Components.set(e, PlanetImage.new(r,gr,c,15), Drawable)
		Components.set(e, Bounds.new(e,0,0,gr,"planet"))

		var ps = ParticleSystem.new()
		var em2 = ParticleEmitter.new(
			128,
			[
				RadialSpawnModule.new(r),
				ScaleLifeModule.new(r/3,1),
				ColorLifeModule.new([4,3,2]),
				VelocityModule.new(-100,-100,100,100),
			],
			CircleDrawModule.new()

		)

		em2.count = 128
		em2.life = 0.8
		em2.enabled = false
		ps.add(em2)
		ps.layer = 3
		Components.set(e, ps)

		return e

	}

	static sun(x,y,r,d) { 

		var e = Entity.create()
		var gr = r+d
		Components.set(e, Planet.new(r,d))
		Components.set(e, Position.new(x,y))
		Components.set(e, Velocity.new(0,0,0.99))
		Components.set(e, PlanetImage.new(r,gr,4,4), Drawable)
		Components.set(e, Bounds.new(e,0,0,gr,"sun"))

		var ps = ParticleSystem.new()
		var em2 = ParticleEmitter.new(
			128,
			[
				RadialSpawnModule.new(r),
				ScaleLifeModule.new(r/3,1),
				ColorLifeModule.new([4,3,2]),
				VelocityModule.new(-100,-100,100,100),
			],
			CircleDrawModule.new()

		)

		em2.count = 128
		em2.life = 0.8
		em2.enabled = false
		ps.add(em2)
		ps.layer = 3
		Components.set(e, ps)

		return e

	}

	static ice(x,y) { 

		var e = Entity.create()
		var r = 2
		var gr = r+48
		var hgs = Game.speed * 0.5
		Components.set(e, Planet.new(r+2,gr))
		Components.set(e, Position.new(x,y))
		Components.set(e, Velocity.new(Game.random.int(-hgs,hgs),Game.random.int(-hgs,hgs),0.99))
		Components.set(e, IceImage.new(r,10), Drawable)
		Components.set(e, Bounds.new(e,0,0,gr,"ice"))

		return e

	}

	static blackhole(x,y,r,d) { 

		var e = Entity.create()
		var gr = r+d
		Components.set(e, Planet.new(r,d))
		Components.set(e, Position.new(x,y))
		Components.set(e, Velocity.new(0,0,0.99))
		Components.set(e, BlackholeImage.new(r,gr,14,14), Drawable)
		Components.set(e, Bounds.new(e,0,0,gr,"blackhole"))

		return e

	}

	static star(x,y) { 

		var e = Entity.create()
		var s = Star.new(Game.random.float(0.05,0.15))
		Components.set(e, s)

		Components.set(e, Position.new(x ,y))
		Components.set(e, Circle.new(Game.random.int(0,2),13,1), Drawable)

		return e
		
	}

	static comet(r) { 
		
		var e = Entity.create()
		Components.set(e, Comet.new(r,1))
		Components.set(e, Position.new(48,Screen.height/2))
		Components.set(e, Velocity.new(0,0,0.99))
		Components.set(e, CometImage.new(r,15,3), Drawable)
		Components.set(e, Bounds.new(e,0,0,r,"comet"))
		Components.set(e, Lines.new((((0..Game.vis-Game.diff).max)*10).floor,9,15))


		var ps = ParticleSystem.new()
		var em = ParticleEmitter.new(
			512,
			[
				RadialSpawnModule.new(r),
				ScaleLifeModule.new(2,4),
				ColorLifeModule.new([1,10,10,9,9]),
				VelocityModule.new(0,-12,0,12),
			],
			CircleDrawModule.new()

		)
		var em2 = ParticleEmitter.new(
			128,
			[
				RadialSpawnModule.new(r),
				ScaleLifeModule.new(3,1),
				ColorLifeModule.new([4,3,2]),
				VelocityModule.new(-100,-100,100,100),
			],
			CircleDrawModule.new()

		)
		var em3 = ParticleEmitter.new(
			512,
			[
				RadialSpawnModule.new(r),
				ScaleLifeModule.new(2,4),
				ColorLifeModule.new([4,3]),
				GravityModule.new(0,0),
				VelocityModule.new(0,0,0,0),
			],
			CircleDrawModule.new()

		)
		em.cache_wrap = true
		em.rate = 200
		em.life = 0.2
		em.life_max = 1
		em2.count = 64
		em2.life = 0.8
		em2.enabled = false
		em3.enabled = false
		ps.add(em)
		ps.add(em2)
		ps.add(em3)
		ps.layer = 3
		Components.set(e, ps)

		return e

	}
	
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



class PlayState is State {
	

	construct new() {
		super("play")
	}

	init(){
		_dist_text = Text.new("Score: 0",0,0,12,1)
	}

	onenter(d){
		Camera.x = 0
		Camera.y = 0
		Game.score = 0
		Game.time = 0
		_last_cam = Camera.x
		Processor.add(SpawnProcessor.new(), 1)
		Processor.add(PosVelProcessor.new(), 8)
		Processor.add(BoundsProcessor.new(), 9)
		Processor.add(CometProcessor.new(), 10)
		Processor.add(CameraProcessor.new(), 11)
		Processor.add(ParticlesProcessor.new(), 100)
		Processor.add(DrawProcessor.new(), 999)
		EntityCreator.comet(3)
	}

	onleave(d){
		Camera.x = 0
		Camera.y = 0
		World.empty()
		Processor.remove(SpawnProcessor)
		Processor.remove(PosVelProcessor)
		Processor.remove(BoundsProcessor)
		Processor.remove(CometProcessor)
		Processor.remove(CameraProcessor)
		Processor.remove(ParticlesProcessor)
		Processor.remove(DrawProcessor)
	}

	update(dt) { 
		Game.time = Game.time + dt
		_last_cam = Camera.x
		World.update(Game.dt)
		var dist = Camera.x - _last_cam
		Game.score = Game.score + (dist * 0.001)
		_dist_text.text = "Score: %(Game.score.floor)"
		if(TIC.btn(7)) {
			Game.fsm.set("menu")
// 			World.empty()
		}
	}

	draw() { 
		Game.renderer.process()
		_dist_text.draw()
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

// game
class Game is TIC {

	static dt { __dt }
	static prog { __tm/__tm_max }
	static time { __tm }
	static space { __space }
	static renderer { __renderer }
	static random { __rnd }
	static speed { __spd }
	static speed=(v) { __spd=v }
	static contacts_pool { __cpool }
	static diff { __diff }
	static diff=(v) {
		__gr = 1 + v*0.25
		__diff=v
	}
	static vis { __vis }
	static vis=(v) { __vis=v }
	static music { __mus }
	static music=(v) {
		if (v) {
			TIC.music(0)
		} else {
			TIC.music()
		}
		__mus = v
	}
	static fsm { __fsm }
	static score { __score }
	static score=(v) { __score=v }
	static timescale { __ts }
	static timescale=(v) { __ts=v }
	static time=(v) { __tm=v }

	static chances { __ch }
	static gravity { __gr }

	construct new(){
		__mus = true
		TIC.music(0)
		__tm_max = 10*60 // 10 mins
		__gr = 1
		__tm = 0
		__vis = 3
		__ts = 1
		__diff = 0
		__score = 0
		__spd = 100
		__dt = 1/60
		var m = 64
		__ch = [
		[
			0.8,1.0, // planet
			11.0,13.0, // sun
			10.0,16.0, // blackhole
			2.0,4.0, // ice
			1.0 // speed
		],
		[
			0.1,0.2, // planet
			3.5,6.0, // sun
			3.0,8.0, // blackhole
			0.4,0.8, // ice
			1.75 // speed
		]
		]
		for (i in 0...__ch.count) {
			for (j in 0...__ch[i].count) {
				__ch[i][j] = __ch[i][j] * m
			}
		}
		Timer.init()

		__rnd = Random.new()
// 		FPS.init()
		__cpool = DynamicPool.new(32, Fn.new { CollisionInfo.new() })
		__space = Space.new(40,0,Screen.width-40,Screen.height)

		__renderer = Renderer.new()
		Camera.init()

		// create Layers
		__renderer.create_layer(0) // bg
		__renderer.create_layer(1) // stars
		__renderer.create_layer(2) // planets
		__renderer.create_layer(3) // comet
		__renderer.create_layer(4) // fg

		World.init(4096)
		Family.create("planets", [Planet, Drawable, Position])
		Family.create("comets", [Comet, Drawable, Position])
		Family.create("particles", [ParticleSystem, Position])
		Family.create("bounds", [Bounds, Position])
		Family.create("pos_vel", [Position,Velocity])
		Family.create("stars", [Star, Drawable, Position])

		__fsm = FSM.new()
		__fsm.add(GameOverState.new())
		__fsm.add(MenuState.new())
		__fsm.add(PlayState.new())
		__fsm.set("menu")
// 		__fsm.set("play")

	}

	static add_score(v) {
		__score = __score + v
	}

	static remove_score(v) {
		__score = __score - v
		if (__score < 0) {
			__score = 0
		}
	}

	TIC(){
		__fsm.update(Game.dt)
		Timer.update(Game.dt)

		TIC.cls(0)
		__fsm.draw()
// 		__space.draw()
// 		TIC.trace(__space)
// 		FPS.update()
// 		TIC.print("FPS : %(FPS.value)",196,4,3)
	}
}

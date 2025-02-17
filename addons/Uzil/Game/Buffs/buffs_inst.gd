

class DoBuffInfo :
	var idx : int = -1
	var sort : int = -1 
	var id : String = ""
	var buff = null
	func _init (idx: int, sort: int, id: String, buff) :
		self.idx = idx
		self.sort = sort
		self.id = id
		self.buff = buff
		

# Variable ===================

## 索引
var Buffs

## 辨識
var id : String

## id:附加狀態物件
var _id_to_buff : Dictionary = {}

## 請求方法
var req_buff_data_fn : Callable

# GDScript ===================

func _init (index_Buff) :
	self.Buffs = index_Buff

# Extends ====================

# Interface ==================

# Public =====================

## 取得 附加狀態
func get_buff (id: String) :
	if self._id_to_buff.has(id) : 
		return self._id_to_buff[id]
	
	if not self.req_buff_data_fn.is_null() :
		var got_data = self.req_buff_data_fn.call(id)
		if got_data != null :
			return self.new_buff(id, got_data)
	
	return null

## 新增 附加狀態
func new_buff (id: String, data: Dictionary) :
	var buff = self.Buffs.Buff.new(self, data)
	self.set_buff(id, buff)
	return buff

## 設置 附加狀態
func set_buff (id: String, buff) :
	if buff != null :
		self._id_to_buff[id] = buff
		buff.id = id
	else :
		self.del_buff(id)

## 移除 附加狀態
func del_buff (id: String) :
	if not self._id_to_buff.has(id) : return
	self._id_to_buff.erase(id)

## 執行 附加狀態
## editable_data 若有需要duplicate請自行處理, 此處保留彈性不干涉.
func do_buff (tags: Array, buff_id: String, editable_data: Dictionary, opts := {}) :
	var buff = self.get_buff(buff_id)
	if buff == null : 
		G.error("[Buffs.Inst] do_buff() buff[%s] not found" % [buff_id])
		return
	
	# 若 無指定 則 設置選項 不在處理後停止
	if not opts.has("is_stop_on_handled") : 
		opts["is_stop_on_handled"] = false
	
	# 夾帶 Buff自己
	editable_data["_buff"] = buff
	
	# 若 回傳字典 則 視為取代 editable_data
	var new_data = buff.do_buff(tags, editable_data, opts)
	if new_data != null and typeof(new_data) == TYPE_DICTIONARY :
		editable_data = new_data
	
	return editable_data

## 執行 附加狀態
## editable_data 若有需要duplicate請自行處理, 此處保留彈性不干涉.
func do_buffs (tags: Array, buff_ids: Array, editable_data: Dictionary, opts := {}) :
	var is_auto_sort : bool = true
	if opts.has("is_auto_sort") : 
		is_auto_sort = opts["is_auto_sort"]
	var on_each_done : Callable
	if opts.has("on_each_done") :
		on_each_done = opts["on_each_done"]
		
	# 快照副本
	var _buff_ids = buff_ids.duplicate()
	
	var buffs : Array = []
	for idx in _buff_ids.size() :
		var each_id : String = _buff_ids[idx]
		
		var buff = self.get_buff(each_id)
		if buff == null : 
			G.error("[Buffs.Inst] do_buffs() buff[%s] not found" % [buff])
			continue
		
		var sort : int = -1
		if buff.has_method(&"get_sort") :
			sort = buff.get_sort(tags, opts)
		elif "sort" in buff :
			sort = buff.sort
		
		buffs.push_back(DoBuffInfo.new(idx, sort, each_id, buff))
	
	# 若需 自動排序
	if is_auto_sort :
		buffs.sort_custom(self._compare_do_buff_info)
	
	# 若 無指定 則 設置選項 不在處理後停止
	if not opts.has("is_stop_on_handled") : 
		opts["is_stop_on_handled"] = false
	
	# 依序 執行buff
	for each in buffs :
		# 若 已經不在實際列表中 則 忽略
		if not buff_ids.has(each.buff.id) : continue
		
		editable_data["_buff"] = each.buff
		
		# 若 回傳字典 則 視為取代 editable_data
		var new_data = each.buff.do_buff(tags, editable_data, opts)
		if new_data != null and typeof(new_data) == TYPE_DICTIONARY :
			editable_data = new_data
		
		if not on_each_done.is_null() :
			on_each_done.call(editable_data)
	
	return editable_data


## 取得 處理器串 實例
func get_handlers_inst () :
	return UREQ.acc(&"Uzil:handlers").inst("game.buffs.%s" % [self.id])

# Private ====================

func _compare_do_buff_info (a: DoBuffInfo, b: DoBuffInfo) :
	var b_valid := b.sort > 0
	if a.sort > 0 :
		if b_valid : return a.sort < b.sort
		else : return true
	else :
		if b_valid : return false
		else : return a.idx < b.idx

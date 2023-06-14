extends Node

## StateMachine.Mgr 狀態機 實體 管理
##
## 以key取得/建立 實體.
## 

# Variable ===================

## key:實體 表
var _key_to_inst := {}

# GDScript ===================

func _init (_dont_set_in_scene) :
	pass

func _process (_dt) :
	for each in self._key_to_inst.values() :
		each.process(_dt)

# Public =====================

func inst (key := "_") :
	if self._key_to_inst.has(key):
		return self._key_to_inst[key]
	else:
		var StateMachine = UREQ.access_g("Uzil", "Advance.StateMachine")
		var _inst = StateMachine.Inst.new()
		
		self._key_to_inst[key] = _inst
		return _inst


# Private ====================



# Variable ===================

var some_text := "module_A_text"

# GDScript ===================

func _init () :
	var module_b = UREQ.scope("test").access("B")
	G.print("init module a")

# Called when the node enters the scene tree for the first time.
func _ready () :
	pass

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process (_dt) :
	pass

# Extends ====================

# Interface ==================

# Public =====================

# Private ====================


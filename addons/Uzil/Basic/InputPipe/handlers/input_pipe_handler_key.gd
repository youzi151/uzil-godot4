
# Variable ===================

# GDScript ===================

# Extends ====================

# Public =====================

# Interface ==================

## 設置 核心
func set_core (core) :
	pass

## 處理 訊號
func handle_msg (input_msg) :
	
	input_msg.virtual_key = input_msg.real_key
	
	return input_msg

## 讀取
func load_memo (_memo : Dictionary) :
	pass

# Private ====================


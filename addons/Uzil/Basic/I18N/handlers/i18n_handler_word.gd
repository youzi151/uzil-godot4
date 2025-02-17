
## i18n handler word 在地化 處理器 字詞
##
## 依照 語言字典 內的 字詞 替換關鍵字.
##

# Variable ===================

## 正則式
var regex_pattern := "<#([^<>#]*)#>"

## 正則
var regex : RegEx = null

## 當 不存在時 替代
var replace_when_not_found = null

# GDScript ===================

func _init () :
	self.regex = RegEx.new()
	self.regex.compile(self.regex_pattern)

# Interface ==================

## 處理 翻譯
func handle (trans_task) :
	# 搜尋
	var matches = self.regex.search_all(trans_task.text)
	
	# 若 沒有找到 則 返回
	if matches.size() == 0 :
		return false
	
	# 是否有替換
	var is_trans = false
	
	# 取得 當前語言
	var current_lang = trans_task.inst.get_current_language()
	if current_lang == null : return false
	
	var current_fallback_langs = trans_task.inst.get_current_fallback_languages()
	
	# 已經替換過的鍵
	var replaced_keys := []
	
	# 每個 搜尋結果
	for each in matches :
		
		# 鍵
		var key = each.get_string(1)
		
		# 若 已替換過 則 忽略
		if replaced_keys.has(key) : break
		
		# 完整字串
		var full_str = each.get_string(0)
		# 要替換成的文字
		var replace = null
		
		# 從 字典 中 尋找 
		if current_lang.key_to_word.has(key) :
			replace = current_lang.key_to_word[key]
		else :
			# 從 備選語言 中 尋找
			for each_fallback in current_fallback_langs :
				if each_fallback.key_to_word.has(key) :
					replace = each_fallback.key_to_word[key]
				
			
		# 若 要替換成的文字不存在
		if replace == null :
			# 若有 預設替換文字 則 使用
			if self.replace_when_not_found != null :
				replace = self.replace_when_not_found
			# 否則 不替換
			else :
				continue
		
		# 替換文字
		trans_task.text = (trans_task.text as String).replace(full_str, str(replace))
		
		# 紀錄 已替換過
		replaced_keys.push_back(key)
		is_trans = true
	
	return is_trans

# Public =====================

# Private ====================

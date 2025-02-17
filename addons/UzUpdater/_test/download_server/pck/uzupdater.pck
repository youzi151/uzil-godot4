GDPC                 0                                                                         ,   res://.godot/global_script_class_cache.cfg          �       �h��#@|�	�       res://.godot/uid_cache.bin   0      `      �ګ��f�Tm�����e    ,   res://addons/GlobalDictionary/Scripts/G.gd  �)      L      CEe��|���`�Ɵ�    (   res://addons/Uzil/Scripts/uzil_init.gd  �+      G      ��!.U��9�����    L   res://addons/Uzupdater/Scripts/updatable/updater/uzupdater_updater_main.gd  �       �      ��fΈ�Vp�E���$    L   res://addons/Uzupdater/Scripts/updatable/updater/uzupdater_updater_pck.gd   @      I       O>��ԓ��|��af    <   res://addons/Uzupdater/Scripts/updatable/uzupdater_config.gd�%      �      ��nZ�NɹR6	W�I       res://project.binary�2      o      �0�����`x��i~    ���!���list=Array[Dictionary]([{
"base": &"Node",
"class": &"Uzil_Test_Base",
"icon": "",
"language": &"GDScript",
"path": "res://addons/Uzil/Test/test_base.gd"
}])
�+
## Uzupdater.Updater.Main 主要 更新器
##
## 更新 遊戲內容的部分.
##

# Variable ===================

# GDScript ===================

# Extends ====================

# Public =====================

## 開始
func start_update (task, callback_fn : Callable) :
	print("==== updater_main update start")
	print("uzupdater updater main in pck")
	
	var uzupdater = task.uzupdater
	
	# 更新器列表 (即時讀取並建立)
	var updater_list := [
		["pck", uzupdater.load_updater("uzupdater_updater_pck.gd").new()]
	]
	
	# 每個 更新器 準備更新
	for each in updater_list :
		each[1].prepare_update(task)
	
	# 每個 更新器 依序 開始更新
	uzupdater.async.each_series(
		updater_list,
		func(idx, each, ctrlr):
			# 名稱
			var name : String = each[0]
			# 更新器
			var updater = each[1]
			
			# 開始更新
			updater.start_update(task, func(err):
				# 若有錯誤
				if err != null :
					err = "updater[%s] error : %s" % [name, err]
					callback_fn.call(err)
					return
				
				# 下個更新器
				ctrlr.next.call()
			),
		func():
			print("==== updater_main update end")
			callback_fn.call(null)
	)

# Private ====================
�z^ɚ
## Uzupdater.Updater.PCK PCK 的 更新器
##
## 檢查, 下載/移除, 讀取 各PCK.
##

# Variable ===================

const UPDATER_KEY := "pck"

## 是否 嚴謹讀取
var is_strict_load := true

# GDScript ===================

# Extends ====================

## 準備
func prepare_update (task) :
	
	print("==== updater_pck update prepare")
	print("uzupdater updater pck in pck")
	
	var uzupdater = task.uzupdater
	var updater_pck_data = task.request_updater_data(self.UPDATER_KEY)
	
	var PCK_LIST = uzupdater.config.get_updater_pck_list()
	
	var PCK_STORE_DIR_PATH = ProjectSettings.globalize_path(uzupdater.config.get_updater_pck_dir_path())
	updater_pck_data["PCK_STORE_DIR_PATH"] = PCK_STORE_DIR_PATH
	
	# 要更新的列表
	var to_update_list : Array[String] = []
	# 要移除的列表
	var to_remove_list : Array[String] = []
			
	# 比對 版本資料 列出 需要更新的
	var version_diff_list : Array[String] = []
	
	# 當前版本 pck資料
	var version_pck_dict_last := {}
	if task.version_data_last.has("pck") :
		version_pck_dict_last = task.version_data_last["pck"]
	
	# 新版版本 pck資料
	var version_pck_dict_new := {}
	var version_pck_dict_new_keys := []
	if task.version_data_new.has("pck") : 
		version_pck_dict_new = task.version_data_new["pck"]
		version_pck_dict_new_keys = version_pck_dict_new.keys()
	
	# 每個 當前 pck資料
	for key in version_pck_dict_last.keys() :
		# 若 不在 新版版本 中 則 加入 要移除的列表
		if not version_pck_dict_new_keys.has(key) :
			to_remove_list.push_back(key)
	
	# 每個 新版 pck資料
	for key in version_pck_dict_new_keys :
		# 若 不在 當前版本 中 則 加入 版本不一致列表
		if not version_pck_dict_last.has(key) :
			version_diff_list.push_back(key)
			continue
		
		# 若 當前 與 新版 pck資料
		var pck_info_last = version_pck_dict_last[key]
		var pck_info_new = version_pck_dict_new[key]
		# 若 檢查碼 不一致 則 加入 版本不一致列表
		if pck_info_last["check"] != pck_info_new["check"] :
			version_diff_list.push_back(key)
			continue
	
	# 每個 遊戲定義的PCK
	for each in PCK_LIST :
		
		# 若 在 版本不一致列表 中 則 加入 要更新的列表
		if version_diff_list.has(each) :
			to_update_list.push_back(each)
			print("need update %s because new version avalible (or last version not exist)" % each)
			continue
		
		# 若 檔案 不存在 則 加入 要更新的列表
		var file_path = PCK_STORE_DIR_PATH.path_join(each+".pck")
		if not FileAccess.file_exists(file_path) :
			to_update_list.push_back(each)
			print("need update %s because file not exist" % each)
			continue
	
	# 依照 要更新的列表
	for each in to_update_list :
		# 申請 子進度 佔位
		var sub_progress_key = self._get_sub_progress_key(each)
		var sub_progress = task.request_sub_progress(sub_progress_key)
		var pck_info_new = version_pck_dict_new[each]
		sub_progress.max = pck_info_new["size"]
		sub_progress.tags.push_back("file")
		sub_progress.tags.push_back("main")
	
	# 紀錄 要更新/移除的列表
	updater_pck_data["to_update_list"] = to_update_list
	updater_pck_data["to_remove_list"] = to_remove_list
	

## 開始
func start_update (task, callback_fn : Callable) :
	print("==== updater_pck update start")
	
	var uzupdater = task.uzupdater
	
	var updater_pck_data : Dictionary = task.request_updater_data(self.UPDATER_KEY)
	var to_update_list : Array = updater_pck_data["to_update_list"]
	var to_remove_list : Array = updater_pck_data["to_remove_list"]
	
	var PCK_STORE_DIR_PATH : String = updater_pck_data["PCK_STORE_DIR_PATH"]
	var PCK_DOWNLOAD_URL : String = uzupdater.config.get_updater_pck_download_url()
	for each in to_remove_list :
		var store = PCK_STORE_DIR_PATH.path_join(each+".pck")
		if FileAccess.file_exists(store) :
			DirAccess.remove_absolute(store)
	
	# test
#	self.start_update_test(task, callback_fn)
#	return

	var ref = {}
	
	uzupdater.async.waterfall([
		# 檢查 階段 ====
			
		# 下載 階段 ====
		func (ctrlr) :
			
			# 確保 建立 目錄
			if not DirAccess.dir_exists_absolute(PCK_STORE_DIR_PATH) :
				DirAccess.make_dir_recursive_absolute(PCK_STORE_DIR_PATH)
				
			# 每個 要更新的PCK
			uzupdater.async.each_series(
				to_update_list,
				func (idx, each, ctrlr) :
					
					var url = PCK_DOWNLOAD_URL.path_join(each+".pck")
					var store = PCK_STORE_DIR_PATH.path_join(each+".pck")
					
					var ref2 = {}
					
					# 嘗試次數
					ref2.retry = 2
					
					var sub_progress_key = self._get_sub_progress_key(each)
					var sub_progress = task.request_sub_progress(sub_progress_key)
					
					task.current_sub_progress_key = sub_progress_key
					
					# 當 下載結束
					ref2.on_download_done = func (err) :
						# 若有錯誤
						if err != null :
							# 遞減嘗試次數
							ref2.retry -= 1
							# 若 還可繼續嘗試
							if ref2.retry > 0 :
								# 重新下載
								self.download_pck(task, sub_progress, url, store, ref2.on_download_done)
							else :
								# 停止更新
								self._end_update(task, callback_fn, "pck download fail : %s" % err)
								
							return
						
						ctrlr.next.call()
					
					# 開始下載
					self.download_pck(task, sub_progress, url, store, ref2.on_download_done)
					
					,
				func () :
					ctrlr.next.call()
			)
			,
			
		# 載入 階段 ====
		func (ctrlr) :
			
			# PCK存放目錄
			var pck_dst_dir : DirAccess = DirAccess.open(PCK_STORE_DIR_PATH)
			
			var PCK_LIST = uzupdater.config.get_updater_pck_list()
			
			# 其中的每個檔案
			for each in PCK_LIST :
				var full_path = PCK_STORE_DIR_PATH.path_join(each+".pck")
				print("updater_pck load %s" % full_path)
				# 載入 PCK
				var is_success = ProjectSettings.load_resource_pack(full_path)
				# 若 失敗 且 開啟 嚴格讀取
				if not is_success and self.is_strict_load :
					self._end_update(task, callback_fn, "load pck failed : %s" % each)
					return
			
			ctrlr.next.call()
	], func () :
		print("==== updater_pck update end")
		self._end_update(task, callback_fn, null)
	)

# Public =====================

func start_update_test (task, callback_fn : Callable) :
	
	# check
	
	# download
	var pck_src_path = task.uzupdater.PATH.path_join("_test/pck")
	var pck_src_dir : DirAccess = DirAccess.open(pck_src_path)
	var pck_dst_path = ProjectSettings.globalize_path("./pck")
	
	if not DirAccess.dir_exists_absolute(pck_dst_path) :
		DirAccess.make_dir_recursive_absolute(pck_dst_path)
	
	for file in pck_src_dir.get_files() :
		var file_abs_path = pck_src_path.path_join(file)
		DirAccess.copy_absolute(file_abs_path, pck_dst_path.path_join(file))
	
	# load
	var pck_dst_dir : DirAccess = DirAccess.open(pck_dst_path)
	var files = pck_dst_dir.get_files()
	for file in files :
		var full_path = pck_dst_path.path_join(file)
		ProjectSettings.load_resource_pack(full_path)
	
	callback_fn.call()

func download_pck (task, sub_progress, download_url, store_path, on_downloaded) :
	
	var uzupdater = task.uzupdater
	
	var ref = {}
	
	sub_progress.cur = 0
	
	# 下載
	var result = uzupdater.http.download(
		download_url, store_path,
		# 當 完成下載
		func (response) :
			# 移除 更新行為:進度更新
			if ref.has("update_progress_fn") :
				ref.update_progress_fn.call(0)
				uzupdater.off_process(ref.update_progress_fn)
			
			# 若 非成功
			if response.result != HTTPRequest.RESULT_SUCCESS :
				on_downloaded.call(uzupdater.http.result_string(response.result))
				return
				
			# 下個PCK
			on_downloaded.call(null)
	)
	
	if result.err != null :
		on_downloaded.call(result.err)
		return
	
	ref.request = result.req
	
	# 更新行為:進度更新
	# 依照 下載進度 設置 任務子進度
	ref.update_progress_fn = func (_dt) :
		
		var downloaded = ref.request.get_downloaded_bytes()
		sub_progress.cur = downloaded
		
		var total = ref.request.get_body_size()
		if total != -1 : sub_progress.max = total
	
	ref.update_progress_fn.call(0)
	
	# 註冊 更新行為:進度更新
	uzupdater.on_process(ref.update_progress_fn)

# Private ====================

func _get_sub_progress_key (pck_file_name) :
	return "updater_pck."+pck_file_name

func _end_update (task, callback_fn, err) :
	task.erase_updater_data(self.UPDATER_KEY)
	callback_fn.call(err)
CzՀ(Z[
## Uzupdater Config 設置
##
## Uzupdater更新器 可被更新的設置.
##

# Variable ===================

## 更新器:PCK 下載網址
const _UPDATER_PCK_DOWNLOAD_URL := "http://localhost:8000/pck"
## 更新器:PCK 存放位置
const _UPDATER_PCK_STORE_DIR_PATH := "pck"
## 更新器:PCK 更新列表
const _UPDATER_PCK_LIST := [
	"uzil"
]

var uzupdater = null

# GDScript ===================

func _init (_uzupdater) :
	self.uzupdater = _uzupdater

# Extends ====================

# Public =====================

# [更新器:PCK] ====

## 取得 更新器:PCK 下載網址
func get_updater_pck_download_url () :
	return self._UPDATER_PCK_DOWNLOAD_URL

## 取得 更新器:PCK 儲存位置
func get_updater_pck_dir_path () :
	return self.uzupdater.constant.get_local_store_root().path_join(self._UPDATER_PCK_STORE_DIR_PATH)

## 取得 更新器:PCK PCK列表
func get_updater_pck_list () :
	print("uzupdater config in pck")
	return self._UPDATER_PCK_LIST

# Private ====================

P��+y�X:���extends Node

# 將此Node節點設為AutoLoad, 並命名為"G".
# 就可以用G.v.key或G.v["key"]的方式存取一個全域Dictionary中的值.

# add this node in to singleton/autoload, and name "G".
# then there is a global dictionary can access value with G.v.key or G.v["key"].

var v := {}

func set_global (_name : String, val) :
	self.v[_name] = val
	if _name in self :
		self[_name] = val


# 其他需要事先定義的變數可以新增在下方
# other custom variable that don't need to in runtime can define below
#=======================================

var Uzil = null
�l�extends Node

## Uzil 初始化
## 
## 因為需要在autoload中就初始化Uzil, 才能在啟動時對視窗尺寸(預設設為0x0的)做及時調整避免被改為最小64x64.[br]
## 但又不能使Uzil在autoload中固定為常數而無法更新, 所以改由另一個腳本(這裡)來呼叫初始化.
##

# Variable ===================

# GDScript ===================

func _init () :
	self.init()

# Called when the node enters the scene tree for the first time.
func _ready () :
	pass

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process (_dt) :
	pass

# Extends ====================

# Public =====================

func init () :
	
	# 釋放先前的
	if G.Uzil != null :
		var uzil_node : Node = G.Uzil
		uzil_node.get_parent().remove_child(uzil_node)
		uzil_node.free()
	
	# 讀取並建立 Uzil節點
	var uzil = ResourceLoader.load("res://addons/Uzil/Scripts/uzil.gd", "", ResourceLoader.CACHE_MODE_IGNORE).new()
	uzil.name = "Uzil"
	
	# 加為 G節點 子節點
	G.add_child(uzil)
	
	# 初始化
	uzil.init()

# Private ====================

�)��Nթ	   �af!���E   res://addons/Uzil/Scripts/Advance/Audio/_test/default_bus_layout.tres�l�k7�Vc6   res://addons/Uzil/Scripts/Advance/Audio/_test/test.ogga����CD%   res://addons/Uzil/Test/uzil_test.tscn	����C8   res://addons/Uzupdater/Scripts/_test/test_uzupdater.tscn�F��;AE   res://addons/Uzupdater/Scripts/_test/test_uzupdater_progress_bar.tscn�F��;A3   res://addons/_test/test_uzupdater_progress_bar.tscn�iĖ�9(3   res://addons/_test/test_uzupdater_progress_bar.tscn"n1DY��0   res://addons/Uzupdater/_test/test_uzupdater.tscn�"q�/Rkx=   res://addons/Uzupdater/_test/test_uzupdater_progress_bar.tscnECFG      application/config/name         uzil-godot4    application/run/main_scene0      %   res://addons/Uzil/Test/uzil_test.tscn      application/config/features(   "         4.0    GL Compatibility    
   autoload/G4      +   *res://addons/GlobalDictionary/Scripts/G.gd    autoload/Uzil_Init0      '   *res://addons/Uzil/Scripts/uzil_init.gd    editor_plugins/enabled\   "         res://addons/Uzil/plugin.cfg    )   res://addons/GlobalDictionary/plugin.cfg    #   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility=
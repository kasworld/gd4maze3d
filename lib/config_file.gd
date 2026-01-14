class_name JsonFile

static func file_full_path(fname :String)->String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/" + fname

static func file_exist(fname :String)->bool:
	return FileAccess.file_exists(file_full_path(fname))

static func save_json(fname :String, config :Dictionary)-> String:
	config.erase("load_error") # remove old load result
	var fileobj = FileAccess.open( file_full_path(fname), FileAccess.WRITE)
	var json_string = JSON.stringify(config)
	fileobj.store_line(json_string)
	return "%s save" % [file_full_path(fname)]

static func new_by_load(fname :String, config :Dictionary, version_key:String)->Dictionary:
	config.erase("load_error") # remove old load result
	var rtn = {}
	var fileobj = FileAccess.open(file_full_path(fname), FileAccess.READ)
	var json_string = fileobj.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		rtn = json.data
		for k in config:
			if rtn.get(k) == null :
				rtn.load_error = "field not found %s" % [ k ]
				break
		if rtn.get("load_error") == null and ( rtn[version_key] != config[version_key] ):
			rtn.load_error = "version not match %s %s" % [rtn[version_key] , config[version_key]]
	else:
		rtn.load_error = "JSON Parse Error: %s in %s at line %s" % [ json.get_error_message(),  json_string,  json.get_error_line()]
	return rtn

# call at start
static func load_or_save(fname :String, config :Dictionary, version_key:String)->Dictionary:
	if !file_exist(fname):
		save_json(fname,config)
		return config
	var new_config = new_by_load(fname,config,version_key)
	if new_config.get("load_error") != null:
		print_debug(new_config.load_error)
		save_json(fname,config)
		return config
	else :
		return new_config

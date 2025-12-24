extends Node

class_name InfoText

signal text_updated(info_text :String)

var request_dict = {}
func init_request(weather_url :String, dayinfo_url:String, todayinfo_url:String )->void:
	request_dict["weather_url"] = MyHTTPRequest.new(
		weather_url,
		60,	weather_success, weather_fail,
	)
	request_dict["dayinfo_url"] = MyHTTPRequest.new(
		dayinfo_url,
		60, dayinfo_success, dayinfo_fail,
	)
	request_dict["todayinfo_url"] = MyHTTPRequest.new(
		todayinfo_url,
		60, todayinfo_success, todayinfo_fail,
	)
	for k in request_dict:
		add_child(request_dict[k])

func update_urls(weather_url :String, dayinfo_url:String, todayinfo_url:String )->void:
	request_dict.weather_url.url_to_get = weather_url
	request_dict.dayinfo_url.url_to_get = dayinfo_url
	request_dict.todayinfo_url.url_to_get = todayinfo_url

func force_update()->void:
	for k in request_dict:
		request_dict[k].force_update()

func make_info_text():
	var dayinfo = day_info.get_daystringlist()
	var all = []
	if weather_info.size() > 0:
		all.append_array(weather_info)
	all.append_array(dayinfo)
	all.append_array(today_info)
	var info_text = "\n".join(all)
	text_updated.emit(info_text)

var weather_info :Array[String]
func weather_success(body)->void:
	var text = body.get_string_from_utf8()
	weather_info = split2list( text )
	make_info_text()
func weather_fail()->void:
	weather_info.clear()
	make_info_text()

var day_info = DayInfo.new()
func dayinfo_success(body)->void:
	day_info.make(body.get_string_from_utf8())
	make_info_text()
func dayinfo_fail()->void:
	day_info.clear()
	make_info_text()

var today_info :Array[String]
func todayinfo_success(body)->void:
	today_info = split2list( body.get_string_from_utf8().strip_edges() )
	make_info_text()
func todayinfo_fail()->void:
	today_info.clear()
	make_info_text()

# remove empty line
func split2list(text :String)->Array[String]:
	var lines = text.strip_edges().split("\n", false,0)
	var rtn :Array[String]=[]
	for l in lines:
		if not l.is_empty():
			rtn.append(l.strip_edges())
	return rtn

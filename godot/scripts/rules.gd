class_name Rules
extends RefCounted

const ALGA_PRICE := 300
const FOUND_PRICE := 90
const FARE_CITY := 50
const FARE_SUBURB := 100
const FARE_INTERCITY := 500
const FARE_CONCESSION := 25
const FINE := 500
const MONTH_PASS := 2200


static func delivery_pay(meters: float) -> int:
	return int(round(80.0 + clampf(meters, 40.0, 1100.0) * 0.16))
const LATE_AFTER_MIN := 4.0
const MIN_PER_METER := 0.09
const STOP_DWELL_MIN := 2.0
const MINUTES_PER_SECOND := 0.55

const WEIGHTS := {
	"onTime": {"delta": 3, "label": "Остановка по расписанию", "who": "водитель"},
	"late": {"delta": -8, "label": "Опоздание к остановке", "who": "водитель"},
	"skip": {"delta": -12, "label": "Пропуск остановки", "who": "водитель"},
	"fareOk": {"delta": 5, "label": "Верная сдача", "who": "кондуктор, малый класс"},
	"fareBad": {"delta": -15, "label": "Ошибка в сдаче", "who": "кондуктор, малый класс"},
	"accident": {"delta": -20, "label": "Занос или столкновение", "who": "водитель"},
	"curb": {"delta": -5, "label": "Задели бордюр или встречку", "who": "водитель"},
	"doors": {"delta": -10, "label": "Двери на ходу", "who": "водитель"},
	"finish": {"delta": 15, "label": "Рейс до конечной", "who": "водитель"},
}

const DENOMS := [1, 2, 5, 10, 50, 100, 200]

const WEATHER_LABEL := {"clear": "Ясно", "rain": "Дождь", "snow": "Снег", "fog": "Туман"}
const PERIOD_LABEL := {"day": "День", "evening": "Вечер"}
const TYPE_LABEL := {"bus": "Автобус", "trolley": "Троллейбус", "tram": "Трамвай"}


static func ride_price(route: Dictionary, method: String) -> int:
	# Печка тарифов: город 50, пригород 100, междугородний 500, льгота 25, проездной 0.
	if method == "pass":
		return 0
	if method == "concession":
		return FARE_CONCESSION
	var zone := String(route.get("zone", "city"))
	if bool(route.get("intercity", false)) or zone == "intercity":
		return FARE_INTERCITY
	if zone == "suburb":
		return FARE_SUBURB
	return FARE_CITY


static func fare_due(vehicle_type: String, method: String) -> int:
	if method == "pass":
		return 0
	if method == "concession":
		return FARE_CONCESSION
	return FARE_CITY


static func grip_for(vehicle_type: String, weather: String) -> float:
	# Дождь: рельс скользкий. Снег режет всех. Туман почти не меняет сцепление.
	if vehicle_type == "tram":
		return {"clear": 1.0, "rain": 0.85, "snow": 0.8, "fog": 1.0}.get(weather, 1.0)
	if vehicle_type == "trolley":
		return {"clear": 1.0, "rain": 0.8, "snow": 0.58, "fog": 0.95}.get(weather, 1.0)
	return {"clear": 1.0, "rain": 0.62, "snow": 0.38, "fog": 0.92}.get(weather, 1.0)


static func speed_cap(vehicle_type: String, weather: String) -> float:
	var base := 12.0
	if vehicle_type == "trolley":
		base = 11.5
	elif vehicle_type == "bus":
		base = 13.5
	var cap := base
	if weather != "snow" and vehicle_type != "tram":
		cap = base * (0.62 + 0.38 * grip_for(vehicle_type, weather))
	if weather == "snow":
		cap *= 0.8
	elif weather == "fog":
		cap *= 0.85
	return cap


static func accel_power(vehicle_type: String, weather: String) -> float:
	return 4.8 * grip_for(vehicle_type, weather)


static func brake_power(vehicle_type: String, weather: String) -> float:
	var power := 11.0 * grip_for(vehicle_type, weather)
	# Дождь удлиняет тормозной путь примерно на 30%.
	if weather == "rain":
		power /= 1.3
	return power


static func sun_factor(minutes: float) -> float:
	var hour: float = wrapf(minutes, 0.0, 1440.0) / 60.0
	if hour < 16.0:
		return 1.0
	if hour < 20.0:
		return 1.0 - (hour - 16.0) / 4.0 * 0.82
	return 0.16


static func period_of(minutes: float) -> String:
	var hour: float = wrapf(minutes, 0.0, 1440.0) / 60.0
	return "evening" if hour >= 16.0 or hour < 6.0 else "day"


static func format_clock(minutes: float) -> String:
	var total: float = wrapf(minutes, 0.0, 1440.0)
	return "%02d:%02d" % [int(total / 60.0), int(fmod(total, 60.0))]


static func traffic_count(route: Dictionary, period: String) -> int:
	# traffic — максимум машин, которые одновременно едут по маршруту.
	var cap := int(route["traffic"])
	if period == "evening" and route.get("evening_off", false):
		return 0
	if period == "evening":
		return int(max(1, ceil(float(cap) * 0.45)))
	return cap


static func timetable(start_minutes: float, offsets: Array, weather: String = "clear") -> Array:
	# Перегоны у маршрутов разной длины, поэтому график считаем по расстоянию:
	# при едином шаге на длинных перегонах опоздание было неизбежным.
	# По дождю и снегу график растягивают: машина едет медленнее.
	var factor: float = {"clear": 1.0, "rain": 1.1, "snow": 1.2, "fog": 1.08}.get(weather, 1.0)
	var table := []
	for i in offsets.size():
		if i == 0:
			table.append(start_minutes)
			continue
		var leg: float = absf(float(offsets[i]) - float(offsets[i - 1]))
		table.append(float(table[i - 1]) + leg * MIN_PER_METER * factor + STOP_DWELL_MIN)
	return table


static func judge_stop(minutes: float, scheduled: float, served: bool) -> String:
	if not served:
		return "skip"
	if minutes > scheduled + LATE_AFTER_MIN:
		return "late"
	return "onTime"


static func allowed_codes(role: String, small_bus: bool) -> Array:
	if role == "passenger":
		return []
	if role == "conductor":
		return ["fareOk", "fareBad"]
	var codes := ["onTime", "late", "skip", "accident", "doors", "finish", "curb"]
	if small_bus:
		codes.append("fareOk")
		codes.append("fareBad")
	return codes


static func change_for(tender: int, due: int) -> int:
	return tender - due


static func is_card(tender) -> bool:
	return typeof(tender) == TYPE_STRING

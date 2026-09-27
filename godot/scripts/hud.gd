class_name Hud
extends CanvasLayer

const Depot = preload("res://scripts/company.gd")

signal action(name: String, arg: String)

const GOLD := Color(0.95, 0.76, 0.31)
const INK := Color(0.9, 0.93, 0.96)
const MUTED := Color(0.66, 0.73, 0.8)

var menu_layer: Control
var play_layer: Control
var modal_layer: Control
var dock_layer: Control
var chips := {}
var toast_label: Label
var banner: Button
var reverse_button: Button
var reverse_on := false
var reverse_styled := false
var hint_label: Label
var toast_until := 0.0


func _ready() -> void:
	layer = 10
	menu_layer = _full_control("Menu")
	play_layer = _full_control("Play")
	dock_layer = _full_control("Dock")
	modal_layer = _full_control("Modal")
	_build_play()
	play_layer.visible = false
	dock_layer.visible = false


func _full_control(name: String) -> Control:
	var c := Control.new()
	c.name = name
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _process(_delta: float) -> void:
	if toast_label != null and toast_label.visible and Time.get_ticks_msec() / 1000.0 > toast_until:
		toast_label.visible = false


# --- вспомогательные виджеты -------------------------------------------

static func panel_style(alpha := 0.93) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.08, 0.13, alpha)
	box.border_color = Color(0.95, 0.76, 0.31, 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(18)
	return box


static func chip_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.07, 0.11, 0.82)
	box.border_color = Color(1, 1, 1, 0.12)
	box.set_border_width_all(1)
	box.set_corner_radius_all(999)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box


func label(text: String, size := 16, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func button(text: String, act: String, arg := "", active := false, enabled := true) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 15)
	b.disabled = not enabled
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD if active else Color(1, 1, 1, 0.06)
	style.border_color = GOLD if active else Color(1, 1, 1, 0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.border_color = GOLD
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", style)
	b.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02) if active else INK)
	b.add_theme_color_override("font_hover_color", Color(0.1, 0.08, 0.02) if active else GOLD)
	b.pressed.connect(func(): action.emit(act, arg))
	return b


func row(nodes: Array) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for n in nodes:
		h.add_child(n)
	return h


func card(width := 900) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style())
	panel.custom_minimum_size = Vector2(width, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


func center(node: Control, parent: Control) -> void:
	var box := CenterContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.07, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	box.add_child(node)
	parent.add_child(box)


func clear(node: Control) -> void:
	for child in node.get_children():
		child.queue_free()


# --- меню ---------------------------------------------------------------

func show_menu(state: Dictionary, routes: Array) -> void:
	clear(menu_layer)
	menu_layer.visible = true
	play_layer.visible = false
	dock_layer.visible = false
	clear(modal_layer)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.custom_minimum_size = Vector2(880, 0)

	body.add_child(label("Уфа: транспорт", 34, INK))
	body.add_child(label("Сделано в Cursor", 13, MUTED))
	var pocket_n := 0
	if state.has("pocket"):
		pocket_n = state["pocket"].size()
	body.add_child(label("Юг и Черниковка. Кошелёк %d ₽ · альбом %d · находок %d · %s · смен %d"
		% [state["wallet"], state["album"].size(), pocket_n,
		"машина есть" if state.get("car", false) else "машины нет", state["shifts"]], 15, MUTED))

	var alga_text: String = "Карта «Алга» есть" if state["alga"] else "Купить «Алга» 300 ₽"
	body.add_child(row([
		button("На линию", "start", "", true),
		button(alga_text, "buy"),
		button("Альбом билетов", "album"),
		button("Сбросить сохранение", "reset"),
		button("Выход", "quit"),
	]))

	body.add_child(label("Роль", 15, GOLD))
	body.add_child(row([
		button("Водитель", "role", "driver", state["role"] == "driver"),
		button("Кондуктор", "role", "conductor", state["role"] == "conductor"),
		button("Пассажир", "role", "passenger", state["role"] == "passenger"),
	]))
	body.add_child(label("Пассажир ходит от остановки к остановке, подбирает чужие чеки и может купить машину.", 13, MUTED))
	var book: Array = state.get("achievements", [])
	var titles := {
		"lucky": "Счастливый билет",
		"first_run": "Первый рейс",
		"all_modes": "Все виды транспорта",
		"million": "Миллионер",
		"rain_run": "Рейс в ливень",
		"winter": "Зимний марафон",
		"empire": "Империя",
		"ic_first": "Первый рейс Уфа — Стерлитамак",
		"ic_10": "Опытный",
		"ic_50": "Дальнобойщик",
		"ic_100": "Легенда трассы",
		"ic_night": "Ночной рейс",
		"ic_winter": "Зимний рейс",
		"ic_million": "Миллионер трассы",
	}
	if book.size() > 0:
		var names: Array = []
		for id in book:
			names.append(String(titles.get(id, id)))
		body.add_child(label("Достижения: " + ", ".join(names), 14, GOLD))

	body.add_child(label("Смена, погода, графика", 15, GOLD))
	body.add_child(row([
		button("День 08:00", "period", "day", state["period"] == "day"),
		button("Вечер 19:00", "period", "evening", state["period"] == "evening"),
		button("Ясно", "weather", "clear", state["weather"] == "clear"),
		button("Дождь", "weather", "rain", state["weather"] == "rain"),
		button("Снег", "weather", "snow", state["weather"] == "snow"),
		button("Туман", "weather", "fog", state["weather"] == "fog"),
		button("Графика: высокая", "quality", "high", state["quality"] == "high"),
		button("средняя", "quality", "medium", state["quality"] == "medium"),
	]))
	body.add_child(label("Город 50 ₽ · пригород 100 ₽ · междугородний 500 ₽ · льготный 25 ₽ · штраф без билета 500 ₽. Дождь удлиняет тормозной путь, снег замедляет, туман включает противотуманки.", 13, MUTED))
	var pass_n := int(state.get("pass_left", 0))
	var drivers_n := int(state.get("drivers", 0))
	var profit_n := int(state.get("last_profit", 0))
	body.add_child(label("Депо · директор · прибыль прошлого рейса %d ₽" % profit_n, 15, GOLD))
	body.add_child(row([
		button("Нанять водителя · %d ₽ (%d/4)" % [Depot.HIRE_COST, drivers_n], "hire"),
		button("Проездной · %d ₽ · смен %d" % [Rules.MONTH_PASS, pass_n], "buyPass"),
		button("Льготный тариф", "concession", "", bool(state.get("concession", false))),
	]))
	body.add_child(row([
		button("ГАЗель · 2.4 млн", "buyFleet", "gazelle"),
		button("ЛиАЗ-677 · 8.5 млн", "buyFleet", "liaz677"),
		button("Икарус-260 · 6.2 млн", "buyFleet", "ikarus"),
		button("КТМ-5 · 12 млн", "buyFleet", "ktm5"),
		button("ЗиУ-9 · 7.4 млн", "buyFleet", "ziu9"),
	]))

	body.add_child(label("Маршрут", 15, GOLD))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 190)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	var opened: Array = state.get("open_routes", [])
	for route in routes:
		var cost := int(route.get("build", 0))
		var locked: bool = cost > 0 and not opened.has(String(route["id"]))
		var off: bool = state["period"] == "evening" and bool(route["evening_off"])
		var place := String(route.get("district", ""))
		var text := "%s %s · %s · до %d машин · %s%s%s" % [
			Rules.TYPE_LABEL[route["type"]], route["number"], route["title"], int(route["traffic"]),
			route["operator"], (" · " + place) if place != "" else "", " · вечером в парке" if off else "",
		]
		if locked:
			text = "Построить маршрут · %s · %d ₽" % [route["title"], cost]
		var b := button(text, "buildRoute" if locked else "route", String(route["id"]), state["route_id"] == route["id"], not off)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(b)
	scroll.add_child(list)
	body.add_child(scroll)

	body.add_child(label("Машина", 15, GOLD))
	if state["role"] == "passenger":
		body.add_child(label("Пассажир садится в тот транспорт, что открыл двери на остановке.", 14, MUTED))
	else:
		var route: Dictionary = Routes.find_route(routes, String(state["route_id"]))
		var models := []
		for model_id in route["models"]:
			models.append(button(Fleet.title_of(model_id), "model", String(model_id), state["model_id"] == model_id))
		body.add_child(row(models))

	body.add_child(label("Оценка смены: старт 80, потолок 100", 15, GOLD))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	for code in Rules.WEIGHTS.keys():
		var w: Dictionary = Rules.WEIGHTS[code]
		grid.add_child(label(String(w["label"]), 13, INK))
		grid.add_child(label(String(w["who"]), 13, MUTED))
		var delta: int = int(w["delta"])
		grid.add_child(label(("+%d" % delta) if delta > 0 else str(delta), 13,
			Color(0.55, 0.88, 0.63) if delta > 0 else Color(1.0, 0.6, 0.6)))
	body.add_child(grid)

	body.add_child(label("Водитель: W/S, R или кнопка «Задний ход», E двери, P телефон. Пассажир: зебра у остановки, P — отзыв со звёздами.", 13, MUTED))

	var panel := card(920)
	panel.add_child(body)
	var scroll_all := ScrollContainer.new()
	scroll_all.custom_minimum_size = Vector2(940, 700)
	scroll_all.add_child(panel)
	center(scroll_all, menu_layer)


# --- игровой HUD --------------------------------------------------------

func _build_play() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.position = Vector2(18, 14)
	for key in ["clock", "weather", "money", "rating", "speed", "grip", "next"]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", chip_style())
		var l := label("—", 15)
		panel.add_child(l)
		top.add_child(panel)
		chips[key] = l
	play_layer.add_child(top)

	toast_label = label("", 16, GOLD)
	toast_label.position = Vector2(24, 62)
	toast_label.visible = false
	play_layer.add_child(toast_label)

	banner = button("Конечная — завершить смену", "finish")
	banner.position = Vector2(24, 96)
	banner.visible = false
	play_layer.add_child(banner)

	reverse_button = button("Задний ход  R", "reverse")
	reverse_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	reverse_button.offset_left = -230
	reverse_button.offset_top = -86
	reverse_button.offset_right = -24
	reverse_button.offset_bottom = -40
	reverse_button.visible = false
	play_layer.add_child(reverse_button)

	hint_label = label("", 14, MUTED)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_label.position = Vector2(20, -34)
	play_layer.add_child(hint_label)


func show_play() -> void:
	menu_layer.visible = false
	clear(menu_layer)
	clear(modal_layer)
	play_layer.visible = true


func set_chip(key: String, text: String) -> void:
	if chips.has(key):
		(chips[key] as Label).text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func set_banner(visible_state: bool) -> void:
	banner.visible = visible_state


func set_reverse(active: bool, shown: bool) -> void:
	if reverse_button == null:
		return
	reverse_button.visible = shown
	if reverse_styled and reverse_on == active:
		return
	reverse_styled = true
	reverse_on = active
	reverse_button.text = "Задний ход включён" if active else "Задний ход  R"
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD if active else Color(0.45, 0.12, 0.1, 0.88)
	style.border_color = GOLD if active else Color(1, 0.45, 0.35, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	reverse_button.add_theme_stylebox_override("normal", style)
	reverse_button.add_theme_stylebox_override("hover", style)
	reverse_button.add_theme_stylebox_override("pressed", style)
	reverse_button.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02) if active else Color(1, 0.92, 0.88))


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.visible = true
	toast_until = Time.get_ticks_msec() / 1000.0 + 2.6


# --- модальные окна -----------------------------------------------------

func show_fare(session: Dictionary, vehicle_type: String) -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	var due: int = int(session["due"])
	var card_pay: bool = Rules.is_card(session["tender"])
	var change: int = 0 if card_pay else int(session["tender"]) - due
	var sum := 0
	for piece in session["pieces"]:
		sum += int(piece)
	body.add_child(label("Расчёт с пассажиром", 22))
	body.add_child(label("%s · к оплате %d ₽ · пассажир даёт %s"
		% [Rules.TYPE_LABEL.get(vehicle_type, "Проезд"), due,
		"карту «Алга»" if card_pay else "%d ₽" % int(session["tender"])], 14, MUTED))
	body.add_child(label("Сдача %d ₽ · в лотке %d ₽" % [change, sum], 20,
		GOLD if sum == change else INK))
	var keys := []
	var denoms := Money.denominations()
	for i in denoms.size():
		keys.append(button("%d  %d ₽" % [i + 1, int(denoms[i])], "piece", str(int(denoms[i]))))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	for k in keys:
		grid.add_child(k)
	body.add_child(grid)
	body.add_child(row([
		button("Enter — отдать", "confirm", "", true),
		button("Backspace — забрать", "undo"),
		button("Сброс", "clearpieces"),
	]))
	body.add_child(label("По карте сдача не нужна — отдайте с пустым лотком." if card_pay
		else "Цифры 1–9 кладут монету или купюру в лоток. Деньги настоящие: падают и лежат.", 13, MUTED))
	var panel := card(520)
	panel.add_child(body)
	var wrap := MarginContainer.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.position = Vector2(-560, 90)
	wrap.add_child(panel)
	modal_layer.add_child(wrap)


func show_receipt(data: Dictionary) -> void:
	# Напечатанный чек выезжает в углу экрана и уходит сам.
	var wrap := MarginContainer.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.position = Vector2(-300, 110)
	wrap.add_child(TicketArt.album_card(data))
	play_layer.add_child(wrap)
	var timer := get_tree().create_timer(6.0)
	timer.timeout.connect(func():
		if is_instance_valid(wrap):
			wrap.queue_free())


func show_passenger_till(session: Dictionary, vehicle_type: String) -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	var due: int = int(session["due"])
	var sum := 0
	for piece in session["pieces"]:
		sum += int(piece)
	body.add_child(label("Оплата проезда", 22))
	body.add_child(label("%s · нужно %d ₽ · в лотке %d ₽" % [Rules.TYPE_LABEL.get(vehicle_type, "Проезд"), due, sum], 16,
		GOLD if sum >= due else INK))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	var denoms := Money.denominations()
	for i in denoms.size():
		grid.add_child(button("%d  %d ₽" % [i + 1, int(denoms[i])], "piece", str(int(denoms[i]))))
	body.add_child(grid)
	body.add_child(row([
		button("Enter — заплатить", "confirm", "", true),
		button("Backspace — забрать", "undo"),
		button("Сброс", "clearpieces"),
		button("Назад", "cancelPay"),
	]))
	body.add_child(label("Каждая монета и купюра — отдельный предмет в лотке. Сдача остаётся в кошельке.", 13, MUTED))
	var panel := card(560)
	panel.add_child(body)
	var wrap := MarginContainer.new()
	wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	wrap.position = Vector2(-590, 90)
	wrap.add_child(panel)
	modal_layer.add_child(wrap)


func show_ride_pay(vehicle: Vehicle, has_alga: bool, price: int, ticket_label := "") -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.add_child(label("Оплатить проезд", 26))
	body.add_child(label("%s %s · %s" % [Rules.TYPE_LABEL[vehicle.vehicle_type], vehicle.route["number"], vehicle.title], 15, MUTED))
	var buttons := []
	if ticket_label != "":
		buttons.append(button(ticket_label, "payTicket", "", true))
	buttons.append(button("Наличные %d ₽" % price, "payCash", "", ticket_label == ""))
	if not bool(vehicle.route.get("intercity", false)):
		buttons.append(button("Алга 42 ₽", "payAlga", "", false, has_alga))
	buttons.append(button("Выйти", "leave"))
	body.add_child(row(buttons))
	var panel := card(620)
	panel.add_child(body)
	center(panel, modal_layer)


func show_office(routes: Array, wallet: int) -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.add_child(label("Касса · междугородние", 26))
	body.add_child(label("Кошелёк %d ₽. Билет кладётся в карман и подходит к рейсу с тем же номером." % wallet, 14, MUTED))
	for route in routes:
		var item: Dictionary = route
		body.add_child(button("%s · %s · %d ₽" % [String(item["number"]), String(item["title"]), int(item["fare"])],
			"buyPass", String(item["id"]), true))
	body.add_child(button("Закрыть", "closeOffice"))
	var panel := card(560)
	panel.add_child(body)
	center(panel, modal_layer)


func show_pause() -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.add_child(label("Пауза", 28))
	body.add_child(row([
		button("Дальше", "resume", "", true),
		button("Альбом", "album"),
		button("Завершить смену", "finish"),
		button("В меню", "menu"),
	]))
	var panel := card(520)
	panel.add_child(body)
	center(panel, modal_layer)


func show_summary(summary: Dictionary) -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.add_child(label("Смена закрыта", 28))
	body.add_child(label("Оценка %d · касса смены %d ₽ · кошелёк %d ₽"
		% [summary["rating"], summary["cash"], summary["wallet"]], 16, MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	if summary["log"].is_empty():
		grid.add_child(label("Без замечаний", 14))
	for entry in summary["log"]:
		grid.add_child(label(String(entry["clock"]), 13, MUTED))
		grid.add_child(label(String(entry["label"]), 13))
		var delta: int = int(entry["delta"])
		grid.add_child(label(("+%d" % delta) if delta > 0 else str(delta), 13,
			Color(0.55, 0.88, 0.63) if delta > 0 else Color(1.0, 0.6, 0.6)))
	body.add_child(grid)
	body.add_child(button("В меню", "menu", "", true))
	var panel := card(560)
	panel.add_child(body)
	center(panel, modal_layer)


func show_album(album: Array) -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.add_child(label("Альбом билетов", 28))
	if album.is_empty():
		body.add_child(label("Пока пусто. Чек печатает валидатор после верной оплаты.", 14, MUTED))
	else:
		body.add_child(label("Собрано чеков: %d" % album.size(), 14, MUTED))
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(900, 420)
		var shelf := GridContainer.new()
		shelf.columns = 3
		shelf.add_theme_constant_override("h_separation", 14)
		shelf.add_theme_constant_override("v_separation", 14)
		for i in range(album.size() - 1, -1, -1):
			shelf.add_child(TicketArt.album_card(album[i]))
		scroll.add_child(shelf)
		body.add_child(scroll)
	body.add_child(button("Закрыть", "closeAlbum", "", true))
	var panel := card(940)
	panel.add_child(body)
	center(panel, modal_layer)


func hide_modal() -> void:
	clear(modal_layer)


func show_dock(stop_name: String, boardable: Array, has_alga: bool, pocket: int, has_car: bool, errand := {}) -> void:
	clear(dock_layer)
	dock_layer.visible = true
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.add_child(label(stop_name, 20, GOLD))
	var car_line := "машина есть" if has_car else ("автосалон %d ₽" % TownCar.PRICE)
	body.add_child(label("Находок %d · скупка %d ₽ · %s" % [pocket, Rules.FOUND_PRICE, car_line], 13, MUTED))
	if not errand.is_empty():
		body.add_child(button(String(errand["text"]), String(errand["act"]), String(errand.get("arg", "")), true))
	if boardable.is_empty():
		body.add_child(label("Тротуар и зебра у остановки. E у открытых дверей — сесть.", 13, MUTED))
	else:
		for entry in boardable:
			var v: Vehicle = entry
			var wear := String(v.condition.get("label", ""))
			body.add_child(button("Сесть: %s %s · № %d · %s · %s" % [
				Rules.TYPE_LABEL[v.vehicle_type], v.route["number"], v.fleet_no, v.title, wear],
				"board", String(v.name), true))
	body.add_child(button("Телефон — отзыв", "phone"))
	body.add_child(button("Карта «Алга» есть" if has_alga else "Купить «Алга» 300 ₽", "buy"))
	if not has_car:
		body.add_child(button("Купить машину · %d ₽" % TownCar.PRICE, "buyCar", "", true))
	var panel := card(360)
	panel.add_child(body)
	var wrap := MarginContainer.new()
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wrap.position = Vector2(18, -340)
	wrap.add_child(panel)
	dock_layer.add_child(wrap)


func show_alight(possible: bool) -> void:
	clear(dock_layer)
	dock_layer.visible = true
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	if possible:
		body.add_child(button("Выйти на остановке", "alight", "", true))
	body.add_child(button("Телефон — отзыв", "phone"))
	var wrap := MarginContainer.new()
	wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	wrap.position = Vector2(18, -160)
	wrap.add_child(body)
	dock_layer.add_child(wrap)


func show_phone(rows: Array) -> void:
	clear(modal_layer)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.add_child(label("Телефон", 26, GOLD))
	body.add_child(label("Отзыв со звёздами по бортовому номеру", 14, MUTED))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 320)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	for row in rows:
		list.add_child(label(String(row["line"]), 16, INK))
		list.add_child(label(String(row["sub"]), 13, MUTED))
		var stars := []
		var have: int = int(row["stars"])
		for s in 5:
			var mark := "★" if s < have else "☆"
			stars.append(button(mark, "rate", "%d:%d" % [int(row["no"]), s + 1], s < have))
		list.add_child(self.row(stars))
	scroll.add_child(list)
	body.add_child(scroll)
	body.add_child(button("Закрыть", "closePhone"))
	var panel := card(500)
	panel.add_child(body)
	center(panel, modal_layer)


func hide_dock() -> void:
	clear(dock_layer)
	dock_layer.visible = false

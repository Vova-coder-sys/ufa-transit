class_name Company
extends RefCounted

# Депо игрока: до четырёх водителей, закупка машин, проездной.

const HIRE_COST := 45000
const DRIVER_CAP := 4
const WAGE := 2500
const FUEL := 800
const ROUTE_INCOME := 1800

const CATALOG := {
	"gazelle": 2400000,
	"liaz677": 8500000,
	"ikarus": 6200000,
	"ktm5": 12000000,
	"ziu9": 7400000,
}


static func price_of(model_id: String) -> int:
	return int(CATALOG.get(model_id, 0))


static func can_hire(drivers: int) -> bool:
	return drivers < DRIVER_CAP

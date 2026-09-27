class_name Fleet
extends RefCounted

# Парк Уфы. Кузова строятся лофтом по сечению, стёкла и ливрея — поясами.

const DEFAULTS := {
	"type": "bus",
	"length": 12.0,
	"half_w": 1.28,
	"y0": 0.30,
	"y1": 3.02,
	"r_bottom": 0.22,
	"r_top": 0.42,
	"tumble": 0.05,
	"win_low": 1.52,
	"win_high": 2.42,
	"floor": 0.38,
	"skirt_top": 0.92,
	"stripe": [1.06, 1.2],
	"roof_from": 2.62,
	"nose": {"len": 0.5, "sx": 0.9, "sy": 0.93, "dy": 0.02, "shear": 0.0},
	"tail": {"len": 0.45, "sx": 0.92, "sy": 0.95, "dy": 0.01, "shear": 0.0},
	"sections": [],
	"gap": 0.55,
	"doors": [0.3, -0.18],
	"axles": [0.34, -0.3],
	"wheel_r": 0.5,
	"roof_kit": "ac",
	"bonnet": false,
	"curve": "soft",
	"lamps": "block",
	"pillar": 1.28,
	"grille": false,
	"luggage": false,
	"body": Color(0.93, 0.95, 0.97),
	"skirt": Color(0.1, 0.24, 0.5),
	"line": Color(0.15, 0.5, 0.26),
	"roof": Color(0.86, 0.88, 0.9),
	"seats": Color(0.16, 0.26, 0.4),
}

const MODELS := {
	"vector": {
		"title": "Вектор NEXT", "fleet": 2104, "type": "bus", "length": 8.85, "half_w": 1.15, "y0": 0.32, "y1": 2.96, "r_top": 0.22, "tumble": 0.04,
		"nose": {"len": 0.85, "sx": 0.82, "sy": 0.86, "dy": 0.02, "shear": 0.38},
		"tail": {"len": 0.55, "sx": 0.9, "sy": 0.92, "dy": 0.02, "shear": -0.16},
		"doors": [-0.08, 0.22], "axles": [-0.28, 0.24], "wheel_r": 0.42, "floor": 0.36,
		"body": Color(0.95, 0.96, 0.97), "skirt": Color(0.06, 0.22, 0.5), "line": Color(0.13, 0.52, 0.28),
		"curve": "soft", "lamps": "swept", "pillar": 1.22,
	},
	"nefaz": {
		"title": "НефАЗ-5299", "fleet": 2238, "type": "bus", "length": 12.0, "half_w": 1.275, "y0": 0.32, "y1": 3.14,
		"floor": 0.36, "win_low": 1.15, "win_high": 2.35, "skirt_top": 0.85, "stripe": [0.95, 1.12], "roof_from": 2.55,
		"r_top": 0.06, "r_bottom": 0.04, "tumble": 0.0,
		"nose": {"len": 0.18, "sx": 0.99, "sy": 0.99, "dy": 0.0, "shear": 0.0, "curve": "slab"},
		"tail": {"len": 0.22, "sx": 0.98, "sy": 0.99, "dy": 0.0, "shear": 0.0, "curve": "slab"},
		"body": Color(0.92, 0.94, 0.96), "skirt": Color(0.07, 0.29, 0.56), "line": Color(0.45, 0.68, 0.88),
		"roof_kit": "ac_long", "curve": "slab", "lamps": "block", "pillar": 1.35, "axles": [-0.3, 0.24],
	},
	"liaz": {
		"title": "ЛиАЗ-5292.22", "fleet": 2416, "type": "bus", "length": 12.0, "half_w": 1.25, "y1": 3.06, "r_top": 0.7, "tumble": 0.12,
		"nose": {"len": 0.55, "sx": 0.9, "sy": 0.82, "dy": -0.02, "shear": 0.42},
		"tail": {"len": 0.4, "sx": 0.94, "sy": 0.94, "dy": 0.01, "shear": -0.08},
		"body": Color(0.96, 0.96, 0.95), "skirt": Color(0.2, 0.22, 0.24), "line": Color(0.86, 0.4, 0.06),
		"curve": "soft", "lamps": "swept", "pillar": 1.2,
	},
	"yutong": {
		"title": "Yutong", "fleet": 2602, "type": "bus", "length": 12.0, "y0": 0.42, "y1": 3.36, "floor": 1.0,
		"win_low": 1.86, "win_high": 2.78, "skirt_top": 1.5, "stripe": [1.58, 1.74], "roof_from": 2.96,
		"nose": {"len": 0.75, "sx": 0.88, "sy": 0.9, "dy": 0.03, "shear": 0.32},
		"tail": {"len": 0.6, "sx": 0.9, "sy": 0.92, "dy": 0.02, "shear": -0.18},
		"doors": [0.33], "axles": [0.34, -0.28], "wheel_r": 0.52,
		"body": Color(0.08, 0.14, 0.26), "skirt": Color(0.05, 0.08, 0.14), "line": Color(0.83, 0.65, 0.18),
		"roof": Color(0.12, 0.2, 0.32), "seats": Color(0.3, 0.16, 0.16),
		"curve": "soft", "lamps": "swept", "grille": true, "luggage": true, "pillar": 1.45,
	},
	"gazelle": {
		"title": "ГАЗель NEXT", "fleet": 4120, "type": "bus", "length": 6.62, "half_w": 1.035, "y1": 2.72,
		"win_low": 1.32, "win_high": 2.02, "skirt_top": 0.78, "stripe": [0.9, 1.0], "roof_from": 2.2,
		"r_top": 0.34, "floor": 0.44,
		"nose": {"len": 1.15, "sx": 0.68, "sy": 0.56, "dy": -0.02, "shear": 0.5, "curve": "hood"},
		"tail": {"len": 0.32, "sx": 0.94, "sy": 0.97, "dy": 0.0, "shear": 0.0, "curve": "flat"},
		"doors": [0.16], "axles": [0.33, -0.3], "wheel_r": 0.38, "roof_kit": "none",
		"body": Color(0.96, 0.96, 0.96), "skirt": Color(0.85, 0.63, 0.1), "line": Color(0.9, 0.7, 0.12),
		"curve": "hood", "lamps": "drop", "grille": true, "pillar": 0.92,
	},
	"ford": {
		"title": "Ford Transit", "fleet": 4288, "type": "bus", "length": 6.2, "half_w": 1.02, "y1": 2.48,
		"win_low": 1.3, "win_high": 1.96, "skirt_top": 0.74, "stripe": [0.86, 0.96], "roof_from": 2.14,
		"r_top": 0.36, "floor": 0.42,
		"nose": {"len": 1.05, "sx": 0.7, "sy": 0.6, "dy": -0.04, "shear": 0.42, "curve": "hood"},
		"tail": {"len": 0.3, "sx": 0.95, "sy": 0.97, "dy": 0.0, "shear": 0.0, "curve": "flat"},
		"doors": [0.14], "axles": [0.34, -0.3], "wheel_r": 0.36, "roof_kit": "none",
		"body": Color(0.94, 0.95, 0.96), "skirt": Color(0.1, 0.3, 0.6), "line": Color(0.16, 0.44, 0.78),
		"curve": "hood", "lamps": "rect", "grille": true, "pillar": 0.95,
	},
	"paz3205": {
		"title": "ПАЗ-3205", "fleet": 3014, "type": "bus", "length": 7.0, "half_w": 1.25, "y0": 0.4, "y1": 2.96,
		"win_low": 1.52, "win_high": 2.28, "skirt_top": 1.06, "stripe": [1.16, 1.28], "roof_from": 2.46,
		"floor": 0.78, "r_top": 0.3, "r_bottom": 0.16, "tumble": 0.02,
		"nose": {"len": 0.35, "sx": 0.93, "sy": 0.95, "dy": 0.0, "shear": 0.05},
		"tail": {"len": 0.3, "sx": 0.94, "sy": 0.96, "dy": 0.0, "shear": 0.0},
		"doors": [-0.02], "axles": [-0.3, 0.22], "wheel_r": 0.46, "roof_kit": "none", "bonnet": true,
		"body": Color(0.96, 0.94, 0.86), "skirt": Color(0.6, 0.12, 0.12), "line": Color(0.72, 0.16, 0.16),
		"curve": "flat", "lamps": "round", "grille": true, "pillar": 1.05,
	},
	"paz3206": {
		"title": "ПАЗ-3206", "fleet": 3186, "type": "bus", "length": 7.2, "half_w": 1.18, "y0": 0.44, "y1": 2.96,
		"win_low": 1.58, "win_high": 2.34, "skirt_top": 1.12, "stripe": [1.22, 1.34], "roof_from": 2.52,
		"floor": 0.84, "r_top": 0.3, "r_bottom": 0.16, "tumble": 0.02,
		"nose": {"len": 0.35, "sx": 0.93, "sy": 0.95, "dy": 0.0, "shear": 0.05},
		"tail": {"len": 0.3, "sx": 0.94, "sy": 0.96, "dy": 0.0, "shear": 0.0},
		"doors": [0.2], "axles": [0.3, -0.3], "wheel_r": 0.52, "roof_kit": "none", "bonnet": true,
		"body": Color(0.9, 0.94, 0.88), "skirt": Color(0.13, 0.36, 0.18), "line": Color(0.1, 0.3, 0.14),
		"curve": "flat", "lamps": "round", "grille": true, "pillar": 1.05,
	},
	"gorozhanin": {
		"title": "УТТЗ-6241.01 «Горожанин»", "fleet": 1124, "type": "trolley", "length": 12.4,
		"nose": {"len": 0.95, "sx": 0.82, "sy": 0.86, "dy": 0.03, "shear": 0.36},
		"tail": {"len": 0.6, "sx": 0.9, "sy": 0.92, "dy": 0.02, "shear": -0.12},
		"body": Color(0.95, 0.96, 0.98), "skirt": Color(0.06, 0.2, 0.46), "line": Color(0.22, 0.56, 0.86),
		"roof_kit": "poles", "doors": [0.32, -0.02, -0.32],
		"curve": "soft", "lamps": "block", "pillar": 1.2,
	},
	"uttz6243": {
		"title": "УТТЗ-6243 «Гармошка»", "fleet": 1360, "type": "trolley", "length": 18.4,
		"sections": [9.4, 8.4], "gap": 0.6,
		"nose": {"len": 0.95, "sx": 0.82, "sy": 0.86, "dy": 0.03, "shear": 0.36},
		"tail": {"len": 0.55, "sx": 0.9, "sy": 0.93, "dy": 0.02, "shear": -0.1},
		"body": Color(0.95, 0.96, 0.98), "skirt": Color(0.06, 0.2, 0.46), "line": Color(0.22, 0.56, 0.86),
		"roof_kit": "poles", "doors": [0.3, -0.25], "axles": [0.32, -0.3],
		"curve": "soft", "lamps": "block", "pillar": 1.2,
	},
	"btz": {
		"title": "БТЗ-52011", "fleet": 1518, "type": "trolley", "length": 11.9, "tumble": 0.03, "r_top": 0.3,
		"body": Color(0.72, 0.76, 0.79), "skirt": Color(0.24, 0.29, 0.34), "line": Color(0.45, 0.52, 0.58),
		"roof_kit": "poles", "curve": "flat", "lamps": "rect", "pillar": 1.35,
	},
	"ziu": {
		"title": "ЗиУ-682", "fleet": 1742, "type": "trolley", "length": 11.89, "half_w": 1.25, "y0": 0.42, "y1": 3.05,
		"floor": 0.88, "win_low": 1.55, "win_high": 2.42, "skirt_top": 1.02, "stripe": [1.1, 1.24], "roof_from": 2.58,
		"r_top": 0.28, "tumble": 0.03,
		"nose": {"len": 0.62, "sx": 0.72, "sy": 0.86, "dy": 0.02, "shear": 0.16, "curve": "circle"},
		"tail": {"len": 0.5, "sx": 0.82, "sy": 0.9, "dy": 0.01, "shear": -0.08, "curve": "circle"},
		"body": Color(0.94, 0.92, 0.78), "skirt": Color(0.16, 0.36, 0.2), "line": Color(0.13, 0.3, 0.17),
		"roof_kit": "poles", "doors": [-0.36, 0.0, 0.12], "axles": [-0.3, 0.2],
		"curve": "circle", "lamps": "round", "pillar": 1.35,
	},
	"pesa": {
		"title": "71-414 Pesa Fokstrot", "fleet": 1908, "type": "tram", "length": 26.5, "half_w": 1.25,
		"y0": 0.28, "y1": 3.4, "floor": 0.35, "win_low": 1.5, "win_high": 2.48,
		"skirt_top": 0.74, "stripe": [0.86, 1.02], "roof_from": 2.68, "r_top": 0.5, "tumble": 0.07,
		"sections": [9.0, 7.0, 9.0], "gap": 0.5,
		"nose": {"len": 1.7, "sx": 0.55, "sy": 0.8, "dy": 0.06, "shear": 0.58, "curve": "circle"},
		"tail": {"len": 1.5, "sx": 0.58, "sy": 0.82, "dy": 0.04, "shear": -0.48, "curve": "circle"},
		"doors": [0.28, -0.24], "roof_kit": "panto",
		"body": Color(0.95, 0.96, 0.97), "skirt": Color(0.66, 0.11, 0.12), "line": Color(0.78, 0.14, 0.15),
		"seats": Color(0.22, 0.3, 0.44),
		"curve": "circle", "lamps": "swept", "pillar": 1.35,
	},
	"ktm608": {
		"title": "КТМ-608", "fleet": 5108, "type": "tram", "length": 15.2, "half_w": 1.25, "y0": 0.34, "y1": 3.15,
		"floor": 0.92, "win_low": 1.72, "win_high": 2.54, "skirt_top": 1.24, "stripe": [1.34, 1.46],
		"roof_from": 2.74, "r_top": 0.34, "tumble": 0.03,
		"nose": {"len": 0.28, "sx": 0.97, "sy": 0.98, "dy": 0.0, "shear": 0.08, "curve": "slab"},
		"tail": {"len": 0.28, "sx": 0.97, "sy": 0.98, "dy": 0.0, "shear": -0.08, "curve": "slab"},
		"doors": [-0.18, 0.0, 0.18], "roof_kit": "panto",
		"body": Color(0.95, 0.95, 0.94), "skirt": Color(0.66, 0.13, 0.13), "line": Color(0.78, 0.16, 0.16),
		"curve": "slab", "lamps": "round", "ribs": true, "pillar": 1.4,
	},
	"ktm619": {
		"title": "КТМ-619", "fleet": 5319, "type": "tram", "length": 15.4, "half_w": 1.25, "y0": 0.34, "y1": 3.14,
		"floor": 0.92, "win_low": 1.72, "win_high": 2.54, "skirt_top": 1.24, "stripe": [1.34, 1.46],
		"roof_from": 2.74, "r_top": 0.4, "tumble": 0.04,
		"nose": {"len": 0.7, "sx": 0.9, "sy": 0.92, "dy": 0.02, "shear": 0.22},
		"tail": {"len": 0.6, "sx": 0.9, "sy": 0.93, "dy": 0.02, "shear": -0.18},
		"doors": [-0.18, 0.0, 0.18], "roof_kit": "panto",
		"body": Color(0.96, 0.94, 0.86), "skirt": Color(0.82, 0.42, 0.06), "line": Color(0.9, 0.62, 0.1),
		"curve": "soft", "lamps": "rect", "pillar": 1.4,
	},
	"ktm623": {
		"title": "КТМ-623", "fleet": 5523, "type": "tram", "length": 15.6, "half_w": 1.25, "y0": 0.32, "y1": 3.14,
		"floor": 0.62, "win_low": 1.66, "win_high": 2.52, "skirt_top": 1.1, "stripe": [1.2, 1.34],
		"roof_from": 2.72, "r_top": 0.44, "tumble": 0.05,
		"nose": {"len": 0.9, "sx": 0.88, "sy": 0.9, "dy": 0.03, "shear": 0.3},
		"tail": {"len": 0.8, "sx": 0.88, "sy": 0.91, "dy": 0.02, "shear": -0.24},
		"doors": [-0.18, 0.0, 0.18], "roof_kit": "panto",
		"body": Color(0.95, 0.96, 0.97), "skirt": Color(0.09, 0.32, 0.6), "line": Color(0.16, 0.5, 0.82),
		"curve": "soft", "lamps": "swept", "pillar": 1.35,
	},
	"tatraT3": {
		"title": "Tatra T3", "fleet": 6103, "type": "tram", "length": 14.0, "half_w": 1.25, "y0": 0.32, "y1": 3.06,
		"floor": 0.86, "win_low": 1.58, "win_high": 2.38, "skirt_top": 1.1, "stripe": [1.18, 1.32],
		"roof_from": 2.55, "r_top": 0.55, "tumble": 0.08,
		"nose": {"len": 1.25, "sx": 0.34, "sy": 0.58, "dy": 0.06, "shear": 0.04, "curve": "circle"},
		"tail": {"len": 1.25, "sx": 0.34, "sy": 0.58, "dy": 0.06, "shear": -0.04, "curve": "circle"},
		"doors": [-0.16, 0.0, 0.16], "roof_kit": "panto",
		"body": Color(0.72, 0.13, 0.12), "skirt": Color(0.5, 0.09, 0.08), "line": Color(0.95, 0.93, 0.86),
		"roof": Color(0.9, 0.89, 0.84),
		"curve": "circle", "lamps": "center", "pillar": 1.62,
	},
	"tatraT3M": {
		"title": "Tatra T3M", "fleet": 6316, "type": "tram", "length": 14.0, "half_w": 1.24, "y0": 0.34, "y1": 3.1,
		"floor": 0.9, "win_low": 1.66, "win_high": 2.42, "skirt_top": 1.18, "stripe": [1.28, 1.38],
		"roof_from": 2.62, "r_top": 0.5, "tumble": 0.07,
		"nose": {"len": 1.25, "sx": 0.34, "sy": 0.58, "dy": 0.06, "shear": 0.04, "curve": "circle"},
		"tail": {"len": 1.25, "sx": 0.34, "sy": 0.58, "dy": 0.06, "shear": -0.04, "curve": "circle"},
		"doors": [-0.16, 0.0, 0.16], "roof_kit": "panto",
		"body": Color(0.72, 0.13, 0.12), "skirt": Color(0.5, 0.09, 0.08), "line": Color(0.95, 0.93, 0.86),
		"roof": Color(0.9, 0.89, 0.84),
		"curve": "circle", "lamps": "center", "pillar": 1.62,
	},
	"mttch": {
		"title": "МТТЧ", "fleet": 6502, "type": "tram", "length": 15.3, "half_w": 1.26, "y0": 0.34, "y1": 3.12,
		"floor": 0.9, "win_low": 1.66, "win_high": 2.44, "skirt_top": 1.18, "stripe": [1.28, 1.4],
		"roof_from": 2.64, "r_top": 0.46, "tumble": 0.06,
		"nose": {"len": 0.42, "sx": 0.9, "sy": 0.78, "dy": 0.0, "shear": 0.22, "curve": "slab"},
		"tail": {"len": 1.15, "sx": 0.36, "sy": 0.6, "dy": 0.05, "shear": -0.04, "curve": "circle"},
		"doors": [-0.16, 0.0, 0.16], "roof_kit": "panto",
		"body": Color(0.74, 0.14, 0.13), "skirt": Color(0.42, 0.08, 0.07), "line": Color(0.96, 0.9, 0.78),
		"roof": Color(0.9, 0.87, 0.8),
		"curve": "slab", "lamps": "rect", "pillar": 1.5,
	},
	"ktm5": {
		"title": "КТМ-5 (71-605)", "fleet": 5605, "type": "tram", "length": 15.09, "half_w": 1.275,
		"y0": 0.34, "y1": 3.15, "floor": 0.9, "win_low": 1.68, "win_high": 2.46,
		"skirt_top": 1.14, "stripe": [1.22, 1.38], "roof_from": 2.68, "r_top": 0.05, "r_bottom": 0.04, "tumble": 0.0,
		"nose": {"len": 0.16, "sx": 0.995, "sy": 0.995, "dy": 0.0, "shear": 0.0, "curve": "slab"},
		"tail": {"len": 0.16, "sx": 0.995, "sy": 0.995, "dy": 0.0, "shear": 0.0, "curve": "slab"},
		"doors": [-0.18, 0.0, 0.18], "roof_kit": "panto",
		"body": Color(0.93, 0.93, 0.9), "skirt": Color(0.62, 0.12, 0.12), "line": Color(0.75, 0.16, 0.15),
		"curve": "slab", "lamps": "round", "ribs": true, "pillar": 1.48,
	},
	"liaz677": {
		"title": "ЛиАЗ-677", "fleet": 2677, "type": "bus", "length": 10.53, "half_w": 1.25,
		"y0": 0.48, "y1": 3.03, "floor": 0.9, "win_low": 1.62, "win_high": 2.38,
		"skirt_top": 1.12, "stripe": [1.2, 1.36], "roof_from": 2.55, "r_top": 0.48, "tumble": 0.06,
		"nose": {"len": 1.05, "sx": 0.55, "sy": 0.72, "dy": 0.02, "shear": 0.22, "curve": "circle"},
		"tail": {"len": 0.7, "sx": 0.78, "sy": 0.86, "dy": 0.02, "shear": -0.1, "curve": "circle"},
		"doors": [-0.1, 0.1], "axles": [-0.27, 0.22], "wheel_r": 0.51,
		"body": Color(0.95, 0.9, 0.72), "skirt": Color(0.62, 0.14, 0.12), "line": Color(0.72, 0.18, 0.14),
		"curve": "circle", "lamps": "round", "pillar": 1.25,
	},
	"ziu9": {
		"title": "ЗиУ-9", "fleet": 1809, "type": "trolley", "length": 11.89, "half_w": 1.25, "y0": 0.42, "y1": 3.05,
		"floor": 0.88, "win_low": 1.55, "win_high": 2.42, "skirt_top": 1.02, "stripe": [1.1, 1.24], "roof_from": 2.58,
		"r_top": 0.28, "tumble": 0.03,
		"nose": {"len": 0.62, "sx": 0.72, "sy": 0.86, "dy": 0.02, "shear": 0.16, "curve": "circle"},
		"tail": {"len": 0.5, "sx": 0.82, "sy": 0.9, "dy": 0.01, "shear": -0.08, "curve": "circle"},
		"body": Color(0.94, 0.92, 0.78), "skirt": Color(0.16, 0.36, 0.2), "line": Color(0.13, 0.3, 0.17),
		"roof_kit": "poles", "doors": [-0.36, 0.0, 0.12], "axles": [-0.3, 0.2],
		"curve": "circle", "lamps": "round", "pillar": 1.35,
	},
	"ikarus": {
		"title": "Икарус-260", "fleet": 7260, "type": "bus", "length": 11.0, "half_w": 1.25,
		"y0": 0.5, "y1": 3.04, "floor": 0.92, "win_low": 1.7, "win_high": 2.46,
		"skirt_top": 1.2, "stripe": [1.26, 1.42], "roof_from": 2.58, "r_top": 0.06, "r_bottom": 0.04, "tumble": 0.0,
		"nose": {"len": 0.2, "sx": 0.98, "sy": 0.99, "dy": 0.0, "shear": 0.0, "curve": "slab"},
		"tail": {"len": 0.26, "sx": 0.97, "sy": 0.98, "dy": 0.0, "shear": 0.0, "curve": "slab"},
		"doors": [-0.38, -0.02, 0.12], "axles": [-0.28, 0.21], "wheel_r": 0.48, "roof_kit": "none",
		"body": Color(0.93, 0.91, 0.84), "skirt": Color(0.7, 0.08, 0.08), "line": Color(0.78, 0.1, 0.1),
		"roof": Color(0.86, 0.84, 0.78), "seats": Color(0.45, 0.12, 0.1),
		"curve": "slab", "lamps": "round", "grille": false, "luggage": true, "ribs": true, "pillar": 1.15,
	},
}


static func spec(model_id: String) -> Dictionary:
	var data := DEFAULTS.duplicate(true)
	for key in MODELS[model_id].keys():
		data[key] = MODELS[model_id][key]
	data["id"] = model_id
	return data


static func title_of(model_id: String) -> String:
	return String(MODELS[model_id]["title"])


static func type_of(model_id: String) -> String:
	return String(MODELS[model_id].get("type", "bus"))


static func is_small(model_id: String) -> bool:
	return model_id in ["gazelle", "ford", "paz3205", "paz3206"]


# Состояние кузова привязано к бортовому номеру: одна и та же машина всегда такая.
const WEAR := [
	{"id": "clean", "label": "чистый", "dirt": 0.0, "squeak": 0.0, "pitch": 1.0},
	{"id": "dust", "label": "в пыли", "dirt": 0.32, "squeak": 0.0, "pitch": 1.0},
	{"id": "mud", "label": "грязный", "dirt": 0.74, "squeak": 0.25, "pitch": 0.82},
	{"id": "squeak", "label": "скрипит", "dirt": 0.14, "squeak": 0.92, "pitch": 1.18},
	{"id": "rattle", "label": "гремит", "dirt": 0.24, "squeak": 0.58, "pitch": 0.64},
	{"id": "worn", "label": "изношен", "dirt": 0.5, "squeak": 0.72, "pitch": 0.9},
]


static func condition_for(fleet_no: int) -> Dictionary:
	return WEAR[absi(fleet_no) % WEAR.size()]


static var _squeak_clip: AudioStreamWAV


static func squeak_clip() -> AudioStreamWAV:
	if _squeak_clip != null:
		return _squeak_clip
	var rate := 22050
	var count := int(rate * 0.32)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(rate)
		var env := sin(PI * t / 0.32)
		var freq := 380.0 + sin(t * 46.0) * 210.0
		phase += freq / float(rate)
		var sample := sin(phase * TAU) * env * 0.55
		sample += sin(float(i) * 0.37) * env * 0.12
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 28000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	_squeak_clip = stream
	return stream


static func build(model_id: String, route_number: String, detailed := false, lod := 0) -> Dictionary:
	var sp := spec(model_id)
	var lengths: Array = sp["sections"]
	if lengths.is_empty():
		lengths = [float(sp["length"])]
	var gap: float = float(sp["gap"]) if lengths.size() > 1 else 0.0
	var total: float = 0.0
	for l in lengths:
		total += float(l)
	total += gap * (lengths.size() - 1)

	var result := {
		"sections": [], "offsets": [], "doors": [], "wheels": [], "steer": [],
		"length": total, "type": sp["type"], "title": sp["title"], "model_id": model_id,
		"cabin": null, "seat": null, "steering": null, "headlights": [], "interior_lights": [],
		"beams": [], "taillights": [], "booms": [],
	}

	var cursor: float = 0.0
	for index in lengths.size():
		var seg_len: float = float(lengths[index])
		var section := _build_section(sp, seg_len, index, lengths.size(), route_number, detailed, result, lod)
		result["sections"].append(section)
		result["offsets"].append(cursor + seg_len * 0.5)
		cursor += seg_len + gap
	return result


static func _build_section(sp: Dictionary, seg_len: float, index: int, count: int,
		route_number: String, detailed: bool, result: Dictionary, lod := 0) -> Node3D:
	var root := Node3D.new()
	root.name = "Section%d" % index
	var is_front: bool = index == 0
	var is_rear: bool = index == count - 1
	var half_w: float = float(sp["half_w"])
	var y0: float = float(sp["y0"])
	var y1: float = float(sp["y1"])
	var win_low: float = float(sp["win_low"])
	var win_high: float = float(sp["win_high"])

	var stripe_pair: Array = sp["stripe"]
	var levels := [
		float(sp["skirt_top"]), float(stripe_pair[0]), float(stripe_pair[1]),
		win_low - 0.06, win_low - 0.01, win_low, win_high, win_high + 0.01, win_high + 0.06,
		float(sp["roof_from"]),
	]
	var profile_steps := 12 if lod <= 0 else (6 if lod == 1 else 3)
	var station_steps := 8 if lod <= 0 else (4 if lod == 1 else 2)
	var profile := MeshLib.rounded_profile(half_w, y0, y1, float(sp["r_bottom"]), float(sp["r_top"]), profile_steps, float(sp["tumble"]))
	profile = MeshLib.insert_levels(profile, levels, 0.22 if lod <= 0 else 0.55)
	var nose: Dictionary = (sp["nose"] as Dictionary).duplicate() if is_front else {"len": 0.02, "sx": 1.0, "sy": 1.0, "dy": 0.0, "shear": 0.0, "curve": "flat"}
	var tail: Dictionary = (sp["tail"] as Dictionary).duplicate() if is_rear else {"len": 0.02, "sx": 1.0, "sy": 1.0, "dy": 0.0, "shear": 0.0, "curve": "flat"}
	if not nose.has("curve"):
		nose["curve"] = String(sp.get("curve", "soft"))
	if not tail.has("curve"):
		var end_curve := String(sp.get("curve", "soft"))
		tail["curve"] = end_curve if end_curve == "circle" or end_curve == "flat" else "soft"
	var station_list := MeshLib.stations(seg_len, nose, tail, station_steps)

	var body_mat := MeshLib.paint(sp["body"])
	# Изнутри кузов должен быть стеной, а не дырой.
	body_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Кузов собирается двумя поясами: ниже и выше окон, сам пояс окон — стекло.
	_add_band(root, profile, station_list, y0, y1, y0, win_low, body_mat, 1.0, "BodyLow")
	_add_band(root, profile, station_list, y0, y1, win_high, y1, body_mat, 1.0, "BodyHigh")
	_add_band(root, profile, station_list, y0, y1, y0, float(sp["skirt_top"]), MeshLib.paint(sp["skirt"]), 1.004, "Skirt")
	_add_band(root, profile, station_list, y0, y1, float(stripe_pair[0]), float(stripe_pair[1]), MeshLib.paint(sp["line"]), 1.008, "Stripe")
	_add_band(root, profile, station_list, y0, y1, float(sp["roof_from"]), y1, MeshLib.mat(sp["roof"], 0.75), 1.004, "Roof")
	var glass_mat := MeshLib.glass()
	_add_band(root, profile, station_list, y0, y1, win_low, win_high, glass_mat, 1.0, "Windows")
	_add_band(root, profile, station_list, y0, y1, win_low - 0.06, win_low - 0.01, MeshLib.mat(Color(0.14, 0.15, 0.17), 0.5, 0.4), 1.014, "WinTrimLow")
	_add_band(root, profile, station_list, y0, y1, win_high + 0.01, win_high + 0.06, MeshLib.mat(Color(0.14, 0.15, 0.17), 0.5, 0.4), 1.014, "WinTrimHigh")

	# торцы
	var front_ring := MeshLib.ring_of(profile, station_list[0], y0, y1)
	var rear_ring := MeshLib.ring_of(profile, station_list[station_list.size() - 1], y0, y1)
	if is_front:
		var s0: Dictionary = station_list[0]
		# Лобовое стекло ниже и выше бокового пояса — водителю нужен обзор.
		var cap_low: float = MeshLib.level_at(s0, max(win_low - 0.34, float(sp["skirt_top"]) + 0.12))
		var cap_high: float = MeshLib.level_at(s0, min(float(sp["roof_from"]) + 0.08, y1 - float(sp["r_top"]) * 0.5))
		var caps := MeshLib.cap_with_window(front_ring, cap_low, cap_high, true)
		root.add_child(MeshLib.mesh_node(caps[0], body_mat, "FrontCap"))
		if caps[1] != null:
			root.add_child(MeshLib.mesh_node(caps[1], glass_mat, "Windshield"))
		# Юбка и цветная полоса обходят торец, иначе морда выглядит голой.
		_cap_band(root, front_ring, s0, y0, float(sp["skirt_top"]), true, MeshLib.paint(sp["skirt"]), "FrontSkirt")
		_cap_band(root, front_ring, s0, float(stripe_pair[0]), float(stripe_pair[1]), true, MeshLib.paint(sp["line"]), "FrontStripe")
	else:
		root.add_child(MeshLib.mesh_node(_plain_cap(front_ring, true), MeshLib.mat(Color(0.1, 0.11, 0.12), 0.8), "JointFront"))
	if is_rear:
		var sn: Dictionary = station_list[station_list.size() - 1]
		var caps2 := MeshLib.cap_with_window(rear_ring, MeshLib.level_at(sn, win_low), MeshLib.level_at(sn, win_high), false)
		root.add_child(MeshLib.mesh_node(caps2[0], body_mat, "RearCap"))
		if caps2[1] != null:
			root.add_child(MeshLib.mesh_node(caps2[1], glass_mat, "RearWindow"))
		_cap_band(root, rear_ring, sn, y0, float(sp["skirt_top"]), false, MeshLib.paint(sp["skirt"]), "RearSkirt")
		_cap_band(root, rear_ring, sn, float(stripe_pair[0]), float(stripe_pair[1]), false, MeshLib.paint(sp["line"]), "RearStripe")
	else:
		root.add_child(MeshLib.mesh_node(_plain_cap(rear_ring, false), MeshLib.mat(Color(0.1, 0.11, 0.12), 0.8), "JointRear"))
		var gap_len: float = float(sp["gap"])
		var ribs := 7
		for rib_i in ribs:
			var wide: float = 1.0 if rib_i % 2 == 0 else 0.86
			var rib_z: float = seg_len * 0.5 + gap_len * (float(rib_i) + 0.5) / float(ribs)
			root.add_child(MeshLib.box(
				Vector3(half_w * 1.82 * wide, (win_high - y0 - 0.12) * wide, gap_len / float(ribs) * 0.78),
				Vector3(0, (y0 + win_high) * 0.5, rib_z),
				MeshLib.mat(Color(0.07, 0.075, 0.08), 0.96), "Bellows"))

	_add_pillars(root, sp, seg_len, win_low, win_high)
	_add_doors(root, sp, seg_len, result)
	_add_running_gear(root, sp, seg_len, is_front, is_rear, count, result, lod)
	_add_details(root, sp, seg_len, is_front, is_rear, route_number, detailed, result, lod)
	if detailed:
		_add_interior(root, sp, seg_len, is_front, result)
	else:
		_add_shell_interior(root, sp, seg_len)
	return root


static func _add_pillars(root: Node3D, sp: Dictionary, seg_len: float, win_low: float, win_high: float) -> void:
	var half_w: float = float(sp["half_w"])
	var y0: float = float(sp["y0"])
	var y1: float = float(sp["y1"])
	var mid: float = (win_low + win_high) * 0.5
	var k: float = clamp((mid - y0) / max(0.001, y1 - y0), 0.0, 1.0)
	var x: float = half_w * (1.0 - float(sp["tumble"]) * k * k)
	var mat := MeshLib.mat(Color(0.07, 0.08, 0.09), 0.42, 0.12)
	var pitch: float = float(sp.get("pillar", 1.28))
	var count: int = max(3, int((seg_len - 1.15) / pitch))
	for i in count + 1:
		var z: float = -seg_len * 0.5 + 0.55 + (seg_len - 1.1) * float(i) / count
		for side in [-1.0, 1.0]:
			root.add_child(MeshLib.box(Vector3(0.07, win_high - win_low + 0.06, 0.08),
				Vector3(side * x, mid, z), mat, "Pillar"))


static func _add_shell_interior(root: Node3D, sp: Dictionary, seg_len: float) -> void:
	var half_w: float = float(sp["half_w"])
	var floor_y: float = float(sp["floor"])
	var y1: float = float(sp["y1"])
	var dark := MeshLib.mat(Color(0.2, 0.21, 0.23), 0.95)
	root.add_child(MeshLib.box(Vector3(half_w * 1.9, 0.08, seg_len - 0.3), Vector3(0, floor_y, 0), dark, "Floor"))
	root.add_child(MeshLib.box(Vector3(half_w * 1.86, 0.06, seg_len - 0.4), Vector3(0, y1 - 0.3, 0),
		MeshLib.mat(Color(0.72, 0.73, 0.75), 0.9), "Ceiling"))
	var seat_mat := MeshLib.mat(sp["seats"], 0.95)
	var rows := int((seg_len - 3.0) / 1.7)
	for i in rows:
		var z: float = -seg_len * 0.5 + 2.2 + i * 1.7
		for side in [-1.0, 1.0]:
			root.add_child(MeshLib.box(Vector3(0.86, 0.5, 0.42),
				Vector3(side * (half_w - 0.5), floor_y + 0.55, z), seat_mat, "SeatBlock"))


static func _add_band(root: Node3D, profile: PackedVector2Array, station_list: Array,
		y0: float, y1: float, low: float, high: float, material: Material, swell: float, name: String) -> void:
	if high <= low:
		return
	var runs := MeshLib.band_runs(profile, low, high)
	var i := 0
	for run in runs:
		var mesh := MeshLib.band_mesh(profile, station_list, run, y0, y1, swell)
		root.add_child(MeshLib.mesh_node(mesh, material, "%s%d" % [name, i]))
		i += 1


static func _cap_band(root: Node3D, ring: Array, st_data: Dictionary, low: float, high: float,
		front: bool, material: Material, name: String) -> void:
	if high <= low:
		return
	var parts := MeshLib.cap_with_window(ring, MeshLib.level_at(st_data, low), MeshLib.level_at(st_data, high), front)
	if parts[1] == null:
		return
	var node := MeshLib.mesh_node(parts[1], material, name)
	node.position.z = -0.012 if front else 0.012
	root.add_child(node)


static func _plain_cap(ring: Array, front: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	MeshLib.fan(st, ring, Vector3(0, 0, -1) if front else Vector3(0, 0, 1), front)
	st.generate_tangents()
	return st.commit()


static func _add_doors(root: Node3D, sp: Dictionary, seg_len: float, result: Dictionary) -> void:
	var half_w: float = float(sp["half_w"])
	var floor_y: float = float(sp["floor"])
	var win_high: float = float(sp["win_high"])
	var door_h: float = win_high - float(sp["y0"]) + 0.1
	var leaf_w := 0.58
	var frame_mat := MeshLib.mat(Color(0.12, 0.13, 0.15), 0.5, 0.3)
	var door_glass := MeshLib.glass(Color(0.1, 0.16, 0.2), 0.55)
	for frac in sp["doors"]:
		var z: float = float(frac) * seg_len
		if absf(z) > seg_len * 0.5 - 0.7:
			continue
		for side in [-1.0, 1.0]:
			var leaf := Node3D.new()
			leaf.name = "DoorLeaf"
			var y_center: float = float(sp["y0"]) + door_h * 0.5
			var panel := MeshLib.box(Vector3(0.07, door_h, leaf_w), Vector3(0, 0, 0), frame_mat, "Panel")
			leaf.add_child(panel)
			var pane := MeshLib.box(Vector3(0.04, door_h * 0.55, leaf_w * 0.78),
				Vector3(0.02, door_h * 0.12, 0), door_glass, "Pane")
			leaf.add_child(pane)
			var rail := MeshLib.mat(Color(0.55, 0.57, 0.6), 0.35, 0.7)
			leaf.add_child(MeshLib.box(Vector3(0.045, 0.035, leaf_w * 0.72),
				Vector3(0.035, -door_h * 0.08, 0), rail, "Handle"))
			leaf.position = Vector3(half_w * 0.995, y_center, z + side * leaf_w * 0.5)
			root.add_child(leaf)
			result["doors"].append({
				"node": leaf,
				"base": leaf.position,
				"slide": Vector3(0.09, 0.0, side * (leaf_w * 0.92)),
			})
		var step := MeshLib.box(Vector3(0.22, 0.06, leaf_w * 1.9),
			Vector3(half_w * 0.99, floor_y - 0.03, z), MeshLib.mat(Color(0.14, 0.15, 0.16), 0.9), "Step")
		root.add_child(step)


static func _add_running_gear(root: Node3D, sp: Dictionary, seg_len: float,
		is_front: bool, is_rear: bool, count: int, result: Dictionary, lod := 0) -> void:
	var half_w: float = float(sp["half_w"])
	var radius: float = float(sp["wheel_r"])
	var kind: String = String(sp["type"])
	if kind == "tram":
		var bogie_zs := []
		if count == 1:
			bogie_zs = [seg_len * 0.3, -seg_len * 0.3]
		elif is_front:
			bogie_zs = [-seg_len * 0.22]
		elif is_rear:
			bogie_zs = [seg_len * 0.22]
		else:
			bogie_zs = [0.0]
		for z in bogie_zs:
			var frame := MeshLib.box(Vector3(half_w * 1.55, 0.38, 2.3), Vector3(0, float(sp["y0"]) - 0.12, z),
				MeshLib.mat(Color(0.09, 0.1, 0.11), 0.85, 0.3), "Bogie")
			root.add_child(frame)
			for dz in [-0.85, 0.85]:
				for side in [-1.0, 1.0]:
					var w := MeshLib.wheel(0.33, 0.12, lod == 0)
					w.position = Vector3(side * (half_w - 0.42), 0.33, z + dz)
					root.add_child(w)
					result["wheels"].append(w)
					if lod < 2:
						_arch(root, w.position, 0.42, side)
		return

	var axles: Array = sp["axles"]
	var steer_frac: float = 1.0
	for frac in axles:
		steer_frac = min(steer_frac, float(frac))
	for frac in axles:
		var z: float = float(frac) * seg_len
		if count > 1 and not is_front and not is_rear:
			z = 0.0
		# Передняя ось поворачивается, поэтому колесо живёт внутри поворотного узла.
		var turns: bool = is_front and absf(float(frac) - steer_frac) < 0.001
		for side in [-1.0, 1.0]:
			var w := MeshLib.wheel(radius, 0.3, lod == 0)
			var place := Vector3(side * (half_w - 0.14), radius, z)
			if turns:
				var pivot := Node3D.new()
				pivot.name = "Knuckle"
				pivot.position = place
				pivot.add_child(w)
				root.add_child(pivot)
				result["steer"].append(pivot)
			else:
				w.position = place
				root.add_child(w)
			result["wheels"].append(w)
			if lod < 2:
				_arch(root, place, radius, side)
		var axle := MeshLib.cylinder(0.08, half_w * 1.7, MeshLib.mat(Color(0.12, 0.13, 0.14), 0.8, 0.5), 8)
		axle.rotation_degrees = Vector3(0, 0, 90)
		axle.position = Vector3(0, radius, z)
		root.add_child(axle)


static func _arch(root: Node3D, pos: Vector3, radius: float, side: float) -> void:
	var mat := MeshLib.mat(Color(0.06, 0.07, 0.08), 0.9)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshLib.mesh_node(MeshLib.fender_mesh(radius * 1.28, radius * 0.62), mat, "Arch")
	node.position = pos + Vector3(side * 0.05, 0.05, 0.0)
	root.add_child(node)


static func _add_details(root: Node3D, sp: Dictionary, seg_len: float,
		is_front: bool, is_rear: bool, route_number: String, detailed: bool, result: Dictionary, lod := 0) -> void:
	var half_w: float = float(sp["half_w"])
	var y0: float = float(sp["y0"])
	var y1: float = float(sp["y1"])
	var win_high: float = float(sp["win_high"])
	var win_low: float = float(sp["win_low"])
	var kind: String = String(sp["type"])
	var front_z: float = -seg_len * 0.5

	if is_front and String(sp.get("curve", "")) == "slab":
		var dest := MeshLib.box(Vector3(half_w * 1.35, 0.28, 0.06), Vector3(0, win_high + 0.22, front_z - 0.02),
			MeshLib.mat(Color(0.05, 0.06, 0.08), 0.4), "Dest")
		root.add_child(dest)
		var dest_text := MeshLib.label(route_number, 36, Color(0.55, 1.0, 0.45))
		dest_text.pixel_size = 0.003
		dest_text.position = Vector3(0, win_high + 0.22, front_z - 0.1)
		root.add_child(dest_text)

	if is_front and bool(sp["bonnet"]):
		var hood := MeshLib.box(Vector3(half_w * 1.5, 0.78, 1.0), Vector3(0, y0 + 0.62, front_z - 0.45),
			MeshLib.paint(sp["body"]), "Bonnet")
		root.add_child(hood)
		var grille := MeshLib.box(Vector3(half_w * 1.1, 0.4, 0.08), Vector3(0, y0 + 0.5, front_z - 0.94),
			MeshLib.mat(Color(0.1, 0.1, 0.11), 0.5, 0.6), "Grille")
		root.add_child(grille)

	if is_front:
		var lamp_z: float = front_z - 0.06 - (1.0 if bool(sp["bonnet"]) else 0.0)
		var style := String(sp.get("lamps", "block"))
		if String(sp.get("curve", "soft")) == "circle":
			var nose_len: float = float((sp["nose"] as Dictionary).get("len", 1.0))
			lamp_z += nose_len * (0.06 if style == "center" else 0.2)
		var lamp_y := y0 + (0.95 if style == "drop" or style == "center" else 0.48)
		if lod == 0 and bool(sp.get("grille", false)) and not bool(sp["bonnet"]):
			var grille := MeshLib.slat_grille(half_w * (1.2 if style == "drop" else 0.9), 0.46 if style == "drop" else 0.32, 5)
			grille.position = Vector3(0, y0 + (0.7 if style == "drop" else 0.5), lamp_z + 0.04)
			root.add_child(grille)
		if lod == 0:
			var bumper := MeshLib.bumper_bar(half_w * 1.75, 0.08, MeshLib.mat(Color(0.1, 0.11, 0.12), 0.5, 0.2))
			bumper.position = Vector3(0, y0 + 0.18, lamp_z - 0.05)
			root.add_child(bumper)
		for side in [-1.0, 1.0]:
			if style == "center" and side < 0.0:
				continue
			if lod == 0:
				var cluster: Dictionary = MeshLib.lamp_cluster("round" if style == "center" else style)
				var node: Node3D = cluster["node"]
				var lamp_x: float = 0.0 if style == "center" else side * half_w * (0.78 if style == "drop" else 0.68)
				node.position = Vector3(lamp_x, lamp_y, lamp_z)
				root.add_child(node)
				for lens in cluster["lenses"]:
					result["headlights"].append(lens)
			else:
				var lamp := MeshLib.box(Vector3(0.34, 0.2, 0.1),
					Vector3(side * half_w * 0.62, lamp_y, lamp_z),
					MeshLib.emissive(Color(1.0, 0.96, 0.85), 1.6), "Headlight")
				root.add_child(lamp)
				result["headlights"].append(lamp)
			if detailed:
				# Ближний свет: у игрока фары реально освещают дорогу.
				var beam := SpotLight3D.new()
				beam.light_color = Color(1.0, 0.95, 0.86)
				beam.light_energy = 0.0
				beam.spot_range = 46.0
				beam.spot_angle = 38.0
				beam.spot_angle_attenuation = 1.2
				beam.shadow_enabled = false
				beam.position = Vector3(side * half_w * 0.62, y0 + 0.42, lamp_z - 0.2)
				beam.rotation_degrees = Vector3(-4, 180, 0)
				root.add_child(beam)
				result["beams"].append(beam)
		if detailed:
			# Дворники видны из кабины.
			var wiper_mat := MeshLib.mat(Color(0.08, 0.09, 0.1), 0.6)
			for side in [-1.0, 1.0]:
				# Щётки лежат у нижней кромки стекла, иначе из кабины они
				# перечёркивают всю дорогу.
				var blade := MeshLib.box(Vector3(0.03, 0.52, 0.03),
					Vector3(side * half_w * 0.5, win_low + 0.02, front_z + 0.08), wiper_mat, "Wiper")
				blade.rotation_degrees = Vector3(0, 0, side * 84)
				root.add_child(blade)
		var board_y: float = min(win_high + 0.34, y1 - 0.16)
		var board := MeshLib.label(route_number, 84)
		board.position = Vector3(0, board_y, front_z - 0.08 - (1.0 if bool(sp["bonnet"]) else 0.0))
		board.rotation_degrees = Vector3(0, 180, 0)
		root.add_child(board)
		var plate := MeshLib.box(Vector3(1.1, 0.34, 0.03),
			Vector3(0, board_y, front_z - 0.05 - (1.0 if bool(sp["bonnet"]) else 0.0)),
			MeshLib.mat(Color(0.05, 0.06, 0.08), 0.6), "Board")
		root.add_child(plate)
		var mirror_mat := MeshLib.mat(Color(0.1, 0.11, 0.12), 0.5, 0.4)
		for side in [-1.0, 1.0]:
			var arm := MeshLib.cylinder(0.025, 0.42, mirror_mat, 6)
			arm.rotation_degrees = Vector3(0, 0, 90 + side * 18)
			arm.position = Vector3(side * (half_w + 0.2), win_high + 0.04, front_z + 0.5)
			root.add_child(arm)
			var glass_m := MeshLib.box(Vector3(0.05, 0.4, 0.2),
				Vector3(side * (half_w + 0.4), win_high - 0.12, front_z + 0.5),
				MeshLib.mat(Color(0.3, 0.33, 0.36), 0.2, 0.7), "Mirror")
			root.add_child(glass_m)

	if is_rear:
		var tail_mat := MeshLib.emissive(Color(0.8, 0.09, 0.07), 1.1)
		result["taillights"].append(tail_mat)
		for side in [-1.0, 1.0]:
			root.add_child(MeshLib.box(Vector3(0.24, 0.42, 0.08),
				Vector3(side * half_w * 0.66, y0 + 0.5, seg_len * 0.5 + 0.04), tail_mat, "Taillight"))
			root.add_child(MeshLib.box(Vector3(0.16, 0.14, 0.07),
				Vector3(side * half_w * 0.66, y0 + 0.2, seg_len * 0.5 + 0.03),
				MeshLib.mat(Color(0.9, 0.78, 0.35), 0.4), "Reflector"))

	var side_board := MeshLib.label(route_number, 56)
	side_board.position = Vector3(half_w + 0.02, win_high + 0.18, seg_len * 0.22)
	side_board.rotation_degrees = Vector3(0, 90, 0)
	root.add_child(side_board)

	if bool(sp.get("ribs", false)) and lod < 2:
		var rib := MeshLib.mat(Color(0.12, 0.12, 0.13), 0.55, 0.08)
		var lines := 7
		var y_hi: float = min(win_low - 0.1, y0 + 0.95)
		for i in lines:
			var y: float = lerp(y0 + 0.16, y_hi, float(i) / float(lines - 1))
			for side in [-1.0, 1.0]:
				root.add_child(MeshLib.box(Vector3(0.02, 0.014, seg_len * 0.62),
					Vector3(side * (half_w + 0.016), y, seg_len * 0.02), rib, "Rib"))

	if bool(sp.get("luggage", false)) and lod < 2:
		var bay_mat := MeshLib.mat(Color(0.1, 0.11, 0.13), 0.7, 0.15)
		for i in 3:
			var z: float = lerp(-seg_len * 0.12, seg_len * 0.22, float(i) / 2.0)
			for side in [-1.0, 1.0]:
				root.add_child(MeshLib.box(Vector3(0.05, 0.5, 1.2),
					Vector3(side * half_w * 1.012, y0 + 0.78, z), bay_mat, "Bay"))

	match String(sp["roof_kit"]):
		"ac":
			root.add_child(MeshLib.box(Vector3(half_w * 1.3, 0.22, 2.4), Vector3(0, y1 + 0.08, -seg_len * 0.1),
				MeshLib.mat(Color(0.85, 0.87, 0.89), 0.7), "AC"))
		"ac_long":
			root.add_child(MeshLib.box(Vector3(half_w * 1.4, 0.26, 3.6), Vector3(0, y1 + 0.1, -seg_len * 0.05),
				MeshLib.mat(Color(0.82, 0.84, 0.86), 0.7), "AC"))
		"poles":
			if is_rear:
				var base := MeshLib.box(Vector3(half_w * 1.1, 0.16, 1.2), Vector3(0, y1 + 0.06, seg_len * 0.12),
					MeshLib.mat(Color(0.22, 0.24, 0.26), 0.7), "PoleBase")
				root.add_child(base)
				var pole_mat := MeshLib.mat(Color(0.16, 0.17, 0.18), 0.4, 0.7)
				var shoe_mat := MeshLib.mat(Color(0.42, 0.34, 0.18), 0.45, 0.6)
				for side in [-1.0, 1.0]:
					var pivot := Node3D.new()
					pivot.name = "BoomPivot"
					pivot.position = Vector3(side * 0.32, y1 + 0.16, seg_len * 0.28)
					root.add_child(pivot)
					var pole := MeshLib.cylinder(0.042, 6.2, pole_mat, 7)
					pole.position = Vector3(0, 3.1, 0)
					pivot.add_child(pole)
					var shoe := MeshLib.box(Vector3(0.18, 0.08, 0.42), Vector3(0, 6.2, 0), shoe_mat, "Shoe")
					pivot.add_child(shoe)
					result["booms"].append({"pivot": pivot, "pole": pole, "shoe": shoe, "side": side})
		"panto":
			if is_rear or true:
				var panto_mat := MeshLib.mat(Color(0.2, 0.21, 0.23), 0.4, 0.7)
				var z_base: float = seg_len * 0.16
				root.add_child(MeshLib.box(Vector3(half_w * 1.2, 0.1, 1.6), Vector3(0, y1 + 0.05, z_base),
					MeshLib.mat(Color(0.2, 0.22, 0.24), 0.7), "PantoBase"))
				for side in [-1.0, 1.0]:
					var lower := MeshLib.cylinder(0.035, 1.25, panto_mat, 6)
					lower.position = Vector3(side * 0.4, y1 + 0.5, z_base - 0.35)
					lower.rotation_degrees = Vector3(-42, 0, 0)
					root.add_child(lower)
					var upper := MeshLib.cylinder(0.03, 1.15, panto_mat, 6)
					upper.position = Vector3(side * 0.4, y1 + 1.06, z_base + 0.28)
					upper.rotation_degrees = Vector3(46, 0, 0)
					root.add_child(upper)
				root.add_child(MeshLib.box(Vector3(1.5, 0.05, 0.14), Vector3(0, y1 + 1.5, z_base + 0.62),
					MeshLib.mat(Color(0.5, 0.35, 0.18), 0.4, 0.8), "PantoShoe"))
			if kind == "tram":
				root.add_child(MeshLib.box(Vector3(half_w * 1.25, 0.2, 1.8), Vector3(0, y1 + 0.08, -seg_len * 0.22),
					MeshLib.mat(Color(0.86, 0.88, 0.9), 0.7), "AC"))


static func _add_interior(root: Node3D, sp: Dictionary, seg_len: float, is_front: bool, result: Dictionary) -> void:
	var half_w: float = float(sp["half_w"])
	var floor_y: float = float(sp["floor"])
	var y1: float = float(sp["y1"])
	var floor_mat := MeshLib.mat(Color(0.18, 0.19, 0.2), 0.9)
	var wall_mat := MeshLib.mat(Color(0.8, 0.81, 0.83), 0.85)
	var seat_mat := MeshLib.mat(sp["seats"], 0.92)
	var rail_mat := MeshLib.mat(Color(0.82, 0.68, 0.2), 0.32, 0.8)

	root.add_child(MeshLib.box(Vector3(half_w * 1.92, 0.06, seg_len - 0.3), Vector3(0, floor_y, 0), floor_mat, "Floor"))
	root.add_child(MeshLib.box(Vector3(half_w * 1.86, 0.05, seg_len - 0.4), Vector3(0, y1 - 0.28, 0), wall_mat, "Ceiling"))

	var strip := MeshLib.box(Vector3(0.3, 0.04, seg_len - 1.2), Vector3(0, y1 - 0.33, 0),
		MeshLib.emissive(Color(1.0, 0.96, 0.88), 0.0), "CeilLight")
	root.add_child(strip)
	result["interior_lights"].append(strip)

	for side in [-1.0, 1.0]:
		var rail := MeshLib.cylinder(0.025, seg_len - 1.0, rail_mat, 8)
		rail.rotation_degrees = Vector3(90, 0, 0)
		rail.position = Vector3(side * (half_w - 0.34), y1 - 0.52, 0)
		root.add_child(rail)

	var row_pitch := 0.72 if String(sp.get("id", "")) == "ikarus" else 0.82
	var rows := int((seg_len - 3.0) / row_pitch)
	var start_z: float = -seg_len * 0.5 + (2.6 if is_front else 0.9)
	for i in rows:
		var z: float = start_z + i * row_pitch
		if z > seg_len * 0.5 - 0.9:
			break
		for side in [-1.0, 1.0]:
			var seat := Node3D.new()
			seat.position = Vector3(side * (half_w - 0.5), floor_y + 0.03, z)
			seat.add_child(MeshLib.box(Vector3(0.9, 0.1, 0.46), Vector3(0, 0.42, 0), seat_mat, "Pan"))
			seat.add_child(MeshLib.box(Vector3(0.9, 0.56, 0.1), Vector3(0, 0.7, 0.2), seat_mat, "Back"))
			seat.add_child(MeshLib.box(Vector3(0.08, 0.38, 0.4), Vector3(0, 0.2, 0), MeshLib.mat(Color(0.25, 0.26, 0.28), 0.6), "Leg"))
			root.add_child(seat)
		var pole := MeshLib.cylinder(0.022, y1 - 0.34 - floor_y, rail_mat, 8)
		pole.position = Vector3(half_w - 0.72, floor_y + (y1 - 0.34 - floor_y) * 0.5, z - 0.4)
		root.add_child(pole)

	if is_front:
		var cab := Node3D.new()
		cab.name = "Cab"
		var cab_z: float = -seg_len * 0.5 + 1.2
		cab.position = Vector3(-half_w * 0.44, floor_y, cab_z)
		var dash := MeshLib.box(Vector3(1.3, 0.3, 0.64), Vector3(0.12, 0.8, -0.78),
			MeshLib.mat(Color(0.13, 0.14, 0.16), 0.85), "Dash")
		cab.add_child(dash)
		cab.add_child(MeshLib.box(Vector3(1.3, 0.5, 0.1), Vector3(0.12, 0.44, -1.04),
			MeshLib.mat(Color(0.11, 0.12, 0.14), 0.9), "DashFront"))
		var cluster := MeshLib.box(Vector3(0.46, 0.17, 0.05), Vector3(0.0, 0.93, -0.58),
			MeshLib.emissive(Color(0.08, 0.16, 0.22), 0.5), "Cluster")
		cluster.rotation_degrees = Vector3(-22, 0, 0)
		cab.add_child(cluster)
		var wheel_mesh := TorusMesh.new()
		wheel_mesh.inner_radius = 0.155
		wheel_mesh.outer_radius = 0.19
		wheel_mesh.rings = 24
		wheel_mesh.ring_segments = 10
		# Руль висит на наклонной колонке и крутится вокруг своей оси.
		var hub := Node3D.new()
		hub.name = "Column"
		hub.position = Vector3(0.0, 0.92, -0.52)
		hub.rotation_degrees = Vector3(66, 0, 0)
		var rim := Node3D.new()
		rim.name = "Rim"
		rim.add_child(MeshLib.mesh_node(wheel_mesh, MeshLib.mat(Color(0.08, 0.08, 0.09), 0.7), "Steering"))
		for spoke_i in 3:
			var spoke := MeshLib.box(Vector3(0.17, 0.02, 0.035), Vector3(0.085, 0, 0),
				MeshLib.mat(Color(0.11, 0.11, 0.12), 0.6), "Spoke")
			var holder := Node3D.new()
			holder.rotation.y = TAU * float(spoke_i) / 3.0
			holder.add_child(spoke)
			rim.add_child(holder)
		hub.add_child(rim)
		cab.add_child(hub)
		result["steering"] = rim
		var column := MeshLib.cylinder(0.035, 0.34, MeshLib.mat(Color(0.1, 0.11, 0.12), 0.8), 8)
		column.position = Vector3(0.0, 0.82, -0.62)
		column.rotation_degrees = Vector3(66, 0, 0)
		cab.add_child(column)
		var seat := MeshLib.box(Vector3(0.52, 0.12, 0.5), Vector3(0, 0.62, 0.22),
			MeshLib.mat(Color(0.14, 0.15, 0.17), 0.9), "DriverSeat")
		cab.add_child(seat)
		cab.add_child(MeshLib.box(Vector3(0.52, 0.62, 0.12), Vector3(0, 0.92, 0.46),
			MeshLib.mat(Color(0.14, 0.15, 0.17), 0.9), "DriverBack"))
		cab.add_child(MeshLib.box(Vector3(0.06, 1.05, 0.86), Vector3(0.8, 0.52, 0.22),
			MeshLib.mat(Color(0.66, 0.68, 0.7), 0.75), "Partition"))
		root.add_child(cab)
		if String(sp.get("id", "")) == "ikarus":
			var tv_mat := MeshLib.emissive(Color(0.15, 0.35, 0.85), 1.6)
			var tv := MeshLib.box(Vector3(0.62, 0.36, 0.04), Vector3(0.15, y1 - 0.7, cab_z + 1.6), tv_mat, "FilmTV")
			root.add_child(tv)
			result["tv"] = tv_mat
			var thermos := MeshLib.cylinder(0.06, 0.22, MeshLib.mat(Color(0.75, 0.78, 0.82), 0.35, 0.4), 8)
			thermos.position = Vector3(0.35, floor_y + 0.85, cab_z + 0.4)
			root.add_child(thermos)

		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.94, 0.86)
		lamp.light_energy = 1.1
		lamp.omni_range = 7.0
		lamp.shadow_enabled = false
		lamp.position = Vector3(0, y1 - 0.6, cab_z + 0.8)
		root.add_child(lamp)

		var eye := Node3D.new()
		eye.name = "CabinView"
		eye.position = Vector3(-half_w * 0.44, floor_y + 1.3, cab_z + 0.1)
		root.add_child(eye)
		result["cabin"] = eye

		var seat_view := Node3D.new()
		seat_view.name = "SeatView"
		seat_view.position = Vector3(half_w * 0.42, floor_y + 1.12, 0.6)
		root.add_child(seat_view)
		result["seat"] = seat_view

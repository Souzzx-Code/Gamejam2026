extends Node2D
## Mapa PIXEL ART procedural: FATEC Campinas - Game Jam 2026 "O Retorno do Vampiro"
## Godot 4.x. Anexe este script a um Node2D vazio e rode a cena.
##
## Andares: G (térreo), 1, 2 e 3 (o 3 é parecido com o 1).
## Escadaria direita: cópia espelhada da esquerda (x' = MAP_SIZE.x - x).
##
## LATERAIS EXTRAS: o mapa ganhou EXTRA (56 px de mundo ~ 1,5 cm a 96 dpi) de espaço vazio
## em cada lado, com o mesmo fundo de tijolos. NADA que já existia mudou de coordenada
## (escadas, portas, spawns...). O mapa agora vai de x = -EXTRA até x = MAP_SIZE.x + EXTRA
## (use get_map_bounds() para limites de câmera).
##
## PORTA DE SAÍDA (térreo, id "saida_lateral"): chegue perto, aperte [E] e informe a senha.
## Ao abrir, o jogador vence: sinal game_won, tela de vitória e [R] reinicia a cena.
##
## Como funciona o visual:
##   Todo o cenário é desenhado em uma imagem de baixa resolução (352 x 246 "pixels de arte")
##   e ampliada 4x com filtro NEAREST -> pixels grandes e nítidos, sem arquivos de imagem.
##   Tochas, fantasmas e morcegos são Sprite2D animados por cima do cenário.
##
## Física: lajes, paredes e rampas das escadas (StaticBody2D); portas e elevadores (Area2D).
## Dica: em Project Settings ligue "Rendering > 2D > Snap 2D Transforms to Pixel"
## e "Textures > Canvas Textures > Default Texture Filter = Nearest".

signal door_entered(door_id: String, body: Node2D)
signal elevator_entered(floor_id: String, body: Node2D)
signal elevator_exited(floor_id: String, body: Node2D)
## Emitido quando o jogador abre a porta de saída do térreo
signal game_won(body: Node2D)
signal task_completed(total: int)

@export var use_lighting: bool = true
@export var ambient_color: Color = Color(0.7, 0.64, 0.88)
## Copia também a decoração da escadaria esquerda (zumbi, espantalho, brasão, aranhas)
@export var mirror_stair_decor: bool = true
## Escadas: segure CIMA para subir um lance e BAIXO para atravessar o piso e descer
@export var stair_up_action: StringName = &"ui_up"
@export var stair_down_action: StringName = &"ui_down"
## Ajusta floor_max_angle / floor_snap_length do jogador ao entrar nas escadas
@export var auto_tune_player: bool = true

# ---------------------------------------------------------------------------
# Geometria (unidades de MUNDO = pixels de arte x PX)
# ---------------------------------------------------------------------------
const PX := 4
const ART_W := 422
const ART_H := 246
const MAP_SIZE := Vector2(1688, 984)

# Espaço extra em cada lateral (esquerda e direita). EXTRA = EXTRA_ART * PX.
const EXTRA_ART := 14
const EXTRA := 56.0

const LEFT := 20.0
const RIGHT := 1388.0
const TOP := 16.0
const SLAB_H := 24.0
const STAIR_X0 := 32.0
const STAIR_X1 := 300.0
const SHAFT_L := 764.0
const SHAFT_R := 944.0
const ELEV_X := 856.0

# Escadaria direita = espelho da esquerda: x' = MAP_SIZE.x - x
# (a parede direita antiga em RIGHT foi aberta; a nova parede externa é R_WALL)
const R_STAIR_X1 := 1388.0  # espelho de STAIR_X1 (300)
const R_STAIR_X0 := 1656.0  # espelho de STAIR_X0 (32)
const R_WALL := 1668.0      # espelho de LEFT (20)

const Y_G := 960.0
const Y_1 := 720.0
const Y_2 := 480.0
const Y_3 := 240.0
const FLOORS := {"G": Y_G, "1": Y_1, "2": Y_2, "3": Y_3}
const CEILS := {"G": 744.0, "1": 504.0, "2": 264.0, "3": 16.0}
const FLOOR_ORDER := ["G", "1", "2", "3"]

# Mesmas medidas em pixels de arte
const A_LEFT := 5
const A_RIGHT := 347
const A_STAIR0 := 8
const A_STAIR1 := 75
const A_SHAFT_L := 191
const A_SHAFT_R := 236
const A_ELEV := 214
const A_R_STAIR0 := 414  # espelho de A_STAIR0 (ART_W - 8)
const A_R_WALL := 417    # espelho de A_LEFT (ART_W - 5); A_RIGHT passa a ser o início da escadaria

const SPAWNS := {
	"entrada": Vector2(520, Y_G),
	"recepcao": Vector2(1100, Y_G),
	"andar_1": Vector2(520, Y_1),
	"andar_2": Vector2(520, Y_2),
	"andar_3": Vector2(520, Y_3),
}

# Porta do térreo que dá a vitória ao ser aberta
const WIN_DOOR_ID := "saida_lateral"

# ---------------------------------------------------------------------------
# Paleta
# ---------------------------------------------------------------------------
const SKY := Color("0b1030")
const INK := Color("14101a")
const BRICK1 := Color("a14d36")
const BRICK2 := Color("86402c")
const MORTAR := Color("4a2218")
const WALL := Color("d6c7a1")
const WALL_SH := Color("c2b18a")
const WALL_HI := Color("e8dcbd")
const STRIPE := Color("b45a40")
const STRIPE_HI := Color("c9735a")
const STRIPE_DK := Color("8e4430")
const PIPE := Color("5b5f6b")
const PIPE_HI := Color("7d8290")
const SLAB := Color("6e6e72")
const SLAB_HI := Color("a0a0a6")
const SLAB_DK := Color("45454c")
const WOOD := Color("8a5a2b")
const WOOD_HI := Color("b07a3e")
const WOOD_DK := Color("4e3118")
const ORANGE := Color("f08a24")
const ORANGE_DK := Color("b8501a")
const YELLOW := Color("ffe27a")
const GREEN := Color("4c7a2a")
const GLASS := Color("7fd8e6")
const STEEL := Color("a4abb3")
const STEEL_DK := Color("6c737a")
const WHITE := Color("eef0f4")
const BLUE := Color("2a6fd6")
const CYAN := Color("39a0d9")
const PURPLE := Color("6a3fa0")
const PURPLE_DK := Color("3a2450")
const EXIT_LIGHT := Color("fff1b8")

# Paleta dos sprites (cada letra = uma cor)
const PAL := {
	"w": Color("eef0f4"), "k": Color("1a1424"), "e": Color("202030"),
	"o": Color("f08a24"), "y": Color("ffe27a"), "B": Color("8a5a2b"),
	"G": Color("6d7f66"), "b": Color("4a4a58"), "d": Color("3a3a44"),
	"h": Color("3a2a1a"), "f": Color("d9a76a"), "s": Color("c8a040"),
	"c": Color("7fd8e6"),
}

# ---------------------------------------------------------------------------
# Sprites (linhas de texto = pixels)
# ---------------------------------------------------------------------------
const TORCH_FRAMES := [
	["...o...", "..ooo..", "..oyo..", ".ooyoo.", ".oyyyo.", "..ooo..", "..kkk..", "..BkB..", "...B...", "...B..."],
	["..o....", "..oo...", "..oyo..", ".ooyoo.", ".oyyyo.", "..ooo..", "..kkk..", "..BkB..", "...B...", "...B..."],
	["....o..", "...oo..", "..oyo..", ".ooyoo.", ".oyyyo.", "..ooo..", "..kkk..", "..BkB..", "...B...", "...B..."],
]
const GHOST := [
	"..wwwww..", ".wwwwwww.", "wwwwwwwww", "wwkkwkkww", "wwkkwkkww", "wwwwwwwww",
	"wwwwkwwww", "wwwwwwwww", "wwwwwwwww", "wwwwwwwww", "wwwwwwwww", "ww.www.ww",
]
const BAT_FRAMES := [
	["kk.....kk", "kkk.k.kkk", ".kkkkkkk.", "..kk.kk.."],
	["...k.k...", ".kkkkkkk.", "kkkkkkkkk", "kk.....kk"],
]
const SKULL := [
	".wwwww.", "wwwwwww", "wewwwew", "wewwwew", "wwwewww", ".wwwww.", ".wewew.",
]
const ZOMBIE := [
	"..GGGG...", ".GGGGGG..", ".GyGGyG..", ".GGGGGG..", "..GkkG...", "...GG....",
	".bbbbbb..", "bbbbbbbGG", "bbbbbb.GG", ".bbbbbb..", ".bbbbbb..", ".dd..dd..",
	".dd..dd..", ".dd..dd..", ".kk..kk..",
]
const SCARECROW := [
	"....h....", "...hhh...", ".hhhhhhh.", "...fff...", "..fkfkf..", "...fff...",
	"..sssss..", "sssssssss", "..sBBBs..", "..BBBBB..", "..BBBBB..", "...B.B...",
	"...B.B...", "...B.B...",
]

# ---------------------------------------------------------------------------
# Dados de cenário
# ---------------------------------------------------------------------------
# x em coordenadas de mundo
const DOORS := [
	{"id": "lab_3", "f": "3", "x": 368.0, "label": "LAB 3", "open": false},
	{"id": "sala_302", "f": "3", "x": 496.0, "label": "SALA 302", "open": false},
	{"id": "diretoria", "f": "3", "x": 660.0, "label": "DIRETORIA", "open": false},
	{"id": "lab_max", "f": "2", "x": 700.0, "label": "LAB MAX", "open": true},
	{"id": "sala_2_dir", "f": "2", "x": 1040.0, "label": "", "open": false},
	{"id": "lab_1", "f": "1", "x": 368.0, "label": "LAB 1", "open": false},
	{"id": "sala_202", "f": "1", "x": 496.0, "label": "SALA 202", "open": false},
	{"id": "coordenacao", "f": "1", "x": 660.0, "label": "COORDENAÇÃO", "open": false},
	{"id": "saida_lateral", "f": "G", "x": 1360.0, "label": "", "open": false},
]
const TORCH_X := {
	"G": [405.0, 664.0, 1128.0, 1272.0],
	"1": [288.0, 756.0, 956.0, 1400.0],
	"2": [288.0, 756.0, 956.0, 1400.0],
	"3": [288.0, 756.0, 956.0, 1400.0],
}
# [andar, x (mundo), altura do fundo do fantasma acima do chão]
const GHOSTS := [
	["1", 340.0, 140.0], ["1", 440.0, 132.0], ["1", 560.0, 138.0],
	["3", 380.0, 140.0], ["3", 600.0, 130.0],
]
# [andar, x (mundo), altura acima do chão]
const BAT_SPOTS := [
	["G", 276.0, 170.0], ["G", 320.0, 140.0], ["G", 300.0, 110.0], ["G", 708.0, 100.0],
	["1", 110.0, 200.0], ["1", 708.0, 150.0], ["2", 100.0, 200.0], ["2", 120.0, 160.0],
	["3", 110.0, 180.0],
	["1", 1578.0, 200.0], ["2", 1588.0, 200.0], ["2", 1568.0, 160.0], ["3", 1578.0, 180.0],
]
# r = metade da largura em pixels de arte
const PUMPKINS := [
	{"f": "G", "x": 1012.0, "r": 12},
	{"f": "1", "x": 960.0, "r": 4},
	{"f": "2", "x": 952.0, "r": 4},
	{"f": "3", "x": 1352.0, "r": 4},
]

var _lights: Array[PointLight2D] = []
var _torches: Array[Sprite2D] = []
var _torch_tex: Array[ImageTexture] = []
var _ghosts: Array[Sprite2D] = []
var _ghost_y: Array[float] = []
var _bats: Array[Sprite2D] = []
var _bat_pos: Array[Vector2] = []
var _bat_tex: Array[ImageTexture] = []
var _t := 0.0

# escadas
var _ramps: Array[Dictionary] = []
var _stair_slabs: Array[CollisionShape2D] = []
var _stair_body: CharacterBody2D
var _drop_t := 0.0
var _slabs_off := false

# elevador interativo
var _elev_body: Node2D
var _elev_floor := ""
var _menu_open := false
var _menu_layer: CanvasLayer
var _menu_sprite: Sprite2D
var _hint: Sprite2D
var _saved_proc: Array = []

# porta de saída / vitória
var _exit_body: Node2D
var _exit_door_sprite: Sprite2D
var _door_hint: Sprite2D
var _password_layer: CanvasLayer
var _password_sprite: Sprite2D
var _password_value := ""
var _password_feedback := ""
var _exit_password := ""
var _cable_obtained := false
var _director_body: Node2D
var _network_enabled := false
var _server_body: Node2D
var _monitor_body: Node2D
var _monitor_index := -1
var _network_body: Node2D
var _network_layer: CanvasLayer
var _network_sprite: Sprite2D
var _network_message := ""
var _network_digit_only := false
var _tasks_completed := 0
var _collected_digits := [false, false, false]
var _health_bar: ProgressBar
var _health_text: Label
var _game_over_started := false
var _win_layer: CanvasLayer
var _won := false


# ===========================================================================
# Canvas de pixels (desenha numa Image em coordenadas de arte)
# ===========================================================================
class PixelCanvas:
	extends RefCounted

	const FONT := {
		"A": [2, 5, 7, 5, 5], "B": [6, 5, 6, 5, 6], "C": [3, 4, 4, 4, 3], "D": [6, 5, 5, 5, 6],
		"E": [7, 4, 6, 4, 7], "F": [7, 4, 6, 4, 4], "G": [3, 4, 5, 5, 3], "H": [5, 5, 7, 5, 5],
		"I": [7, 2, 2, 2, 7], "J": [1, 1, 1, 5, 2], "K": [5, 5, 6, 5, 5], "L": [4, 4, 4, 4, 7],
		"M": [5, 7, 7, 5, 5], "N": [7, 5, 5, 5, 5], "O": [2, 5, 5, 5, 2], "P": [6, 5, 6, 4, 4],
		"Q": [2, 5, 5, 6, 3], "R": [6, 5, 6, 5, 5], "S": [3, 4, 2, 1, 6], "T": [7, 2, 2, 2, 2],
		"U": [5, 5, 5, 5, 7], "V": [5, 5, 5, 5, 2], "W": [5, 5, 7, 7, 5], "X": [5, 5, 2, 5, 5],
		"Y": [5, 5, 2, 2, 2], "Z": [7, 1, 2, 4, 7],
		"0": [7, 5, 5, 5, 7], "1": [2, 6, 2, 2, 7], "2": [6, 1, 2, 4, 7], "3": [6, 1, 2, 1, 6],
		"4": [5, 5, 7, 1, 1], "5": [7, 4, 6, 1, 6], "6": [3, 4, 7, 5, 7], "7": [7, 1, 2, 2, 2],
		"8": [7, 5, 7, 5, 7], "9": [7, 5, 7, 1, 6],
		"-": [0, 0, 7, 0, 0], ".": [0, 0, 0, 0, 2], "!": [2, 2, 2, 0, 2], " ": [0, 0, 0, 0, 0],
		">": [4, 2, 1, 2, 4],
	}

	var img: Image
	var w: int
	var h: int

	func _init(width: int, height: int) -> void:
		w = width
		h = height
		img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))

	func hash2(x: int, y: int) -> float:
		return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)

	func px(x: int, y: int, c: Color) -> void:
		if x < 0 or y < 0 or x >= w or y >= h:
			return
		if c.a < 1.0:
			c = img.get_pixel(x, y).blend(c)
		img.set_pixel(x, y, c)

	func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
		if rw <= 0 or rh <= 0:
			return
		if c.a >= 1.0:
			img.fill_rect(Rect2i(x, y, rw, rh), c)
		else:
			for yy in range(y, y + rh):
				for xx in range(x, x + rw):
					px(xx, yy, c)

	func hline(x: int, y: int, len_: int, c: Color) -> void:
		rect(x, y, len_, 1, c)

	func vline(x: int, y: int, len_: int, c: Color) -> void:
		rect(x, y, 1, len_, c)

	func outline(x: int, y: int, rw: int, rh: int, c: Color) -> void:
		hline(x, y, rw, c)
		hline(x, y + rh - 1, rw, c)
		vline(x, y, rh, c)
		vline(x + rw - 1, y, rh, c)

	func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
		var dx := absi(x1 - x0)
		var dy := -absi(y1 - y0)
		var sx := 1 if x0 < x1 else -1
		var sy := 1 if y0 < y1 else -1
		var err := dx + dy
		while true:
			px(x0, y0, c)
			if x0 == x1 and y0 == y1:
				break
			var e2 := 2 * err
			if e2 >= dy:
				err += dy
				x0 += sx
			if e2 <= dx:
				err += dx
				y0 += sy

	func disc(cx: int, cy: int, r: int, c: Color) -> void:
		for yy in range(-r, r + 1):
			for xx in range(-r, r + 1):
				if xx * xx + yy * yy <= r * r + r:
					px(cx + xx, cy + yy, c)

	func ellipse(cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
		for yy in range(-ry, ry + 1):
			for xx in range(-rx, rx + 1):
				var fx := float(xx) / (rx + 0.5)
				var fy := float(yy) / (ry + 0.5)
				if fx * fx + fy * fy <= 1.0:
					px(cx + xx, cy + yy, c)

	func poly(pts: Array, c: Color) -> void:
		var miny := 1000000
		var maxy := -1000000
		for p in pts:
			miny = mini(miny, p.y)
			maxy = maxi(maxy, p.y)
		for y in range(miny, maxy + 1):
			var xs: Array[int] = []
			for i in pts.size():
				var a: Vector2i = pts[i]
				var b: Vector2i = pts[(i + 1) % pts.size()]
				if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
					var t := float(y - a.y) / float(b.y - a.y)
					xs.append(roundi(a.x + t * (b.x - a.x)))
			xs.sort()
			for i in range(0, xs.size() - 1, 2):
				hline(xs[i], y, xs[i + 1] - xs[i] + 1, c)

	func sprite(rows: Array, pal: Dictionary, x: int, y: int, flip := false) -> void:
		for ry in rows.size():
			var row: String = rows[ry]
			var n := row.length()
			for rx in n:
				var ch := row[rx]
				if ch == "." or not pal.has(ch):
					continue
				var dx := (n - 1 - rx) if flip else rx
				px(x + dx, y + ry, pal[ch])

	func bricks(x: int, y: int, tw: int, th: int, base: Color, mortar: Color, seed_: int = 0) -> void:
		rect(x, y, tw, th, mortar)
		var row := 0
		var yy := y
		while yy < y + th:
			var bh := mini(3, y + th - yy)
			var off := 0 if row % 2 == 0 else 3
			var xx := x - off
			while xx < x + tw:
				var bx := maxi(xx, x)
				var bwid := mini(xx + 7, x + tw) - bx
				if bwid > 1:
					var n := hash2(xx + seed_, yy)
					var col := base
					if n > 0.8:
						col = base.lightened(0.08)
					elif n < 0.2:
						col = base.darkened(0.1)
					rect(bx, yy, bwid - 1, maxi(bh - 1, 1), col)
					hline(bx, yy, bwid - 1, col.lightened(0.12))
				xx += 7
			yy += 3
			row += 1

	func slab(x: int, y: int, sw: int, sh: int, base: Color, hi: Color, dk: Color) -> void:
		rect(x, y, sw, sh, base)
		hline(x, y, sw, hi)
		hline(x, y + sh - 1, sw, dk)
		for xx in range(x, x + sw):
			if hash2(xx, y) > 0.94:
				px(xx, y + 1 + int(hash2(y, xx) * (sh - 2)), dk)

	# ---- texto em fonte pixel 3x5 ----
	func text_width(s: String, scale := 1) -> int:
		var longest := 0
		for ln in s.split("\n"):
			longest = maxi(longest, ln.length() * 4 * scale - scale)
		return longest

	func text(s: String, x: int, y: int, col: Color, scale := 1) -> void:
		var cy := y
		for ln in s.split("\n"):
			var cx := x
			for ch in ln:
				_glyph(ch, cx, cy, col, scale)
				cx += 4 * scale
			cy += 6 * scale

	func text_center(s: String, cx: int, y: int, col: Color, scale := 1) -> void:
		var cy := y
		for ln in s.split("\n"):
			var tw := ln.length() * 4 * scale - scale
			text(ln, cx - tw / 2, cy, col, scale)
			cy += 6 * scale

	func _glyph(ch: String, x: int, y: int, col: Color, scale: int) -> void:
		var key := ch
		var extra := ""
		if ch == "Ã":
			key = "A"
			extra = "~"
		elif ch == "Ç":
			key = "C"
			extra = ","
		var rows: Array = FONT.get(key, FONT[" "])
		for r in 5:
			var bits: int = rows[r]
			for b in 3:
				if bits & (4 >> b):
					rect(x + b * scale, y + r * scale, scale, scale, col)
		if extra == "~":
			rect(x + scale, y - scale, scale, scale, col)
		elif extra == ",":
			rect(x + scale, y + 5 * scale, scale, scale, col)


# ===========================================================================
# Ciclo de vida
# ===========================================================================
func _ready() -> void:
	randomize()
	_exit_password = "%03d" % randi_range(0, 999)
	print("Senha da saída nesta partida: ", _exit_password)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_collisions()
	_build_zones()
	_render_static_art()
	_build_animated()
	_build_hint()
	_build_exit_door()
	_build_spawns()
	_build_lighting()
	_build_health_hud()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.connect("health_changed", _on_player_health_changed)
		player.connect("died", _on_player_died)
		_on_player_health_changed(int(player.get("health")), 5)


func _build_health_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HealthHUD"
	layer.layer = 10
	add_child(layer)

	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.03, 0.08, 0.9)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.position = Vector2(0, -52)
	panel.size = Vector2(0, 52)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)

	_health_text = Label.new()
	_health_text.position = Vector2(24, 16)
	_health_text.add_theme_font_size_override("font_size", 16)
	_health_text.add_theme_color_override("font_color", Color("ffe27a"))
	_health_text.text = "VIDA DO VAMPIRO"
	panel.add_child(_health_text)

	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(230, 18)
	_health_bar.size = Vector2(360, 18)
	_health_bar.show_percentage = false
	_health_bar.add_theme_stylebox_override("background", _health_style(Color("3a1d2b")))
	_health_bar.add_theme_stylebox_override("fill", _health_style(Color("c9364f")))
	panel.add_child(_health_bar)


func _health_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if _health_bar != null:
		_health_bar.max_value = max_health
		_health_bar.value = current_health
	if _health_text != null:
		_health_text.text = "VIDA DO VAMPIRO: %d/%d" % [current_health, max_health]


func _on_player_died() -> void:
	if _game_over_started:
		return
	_game_over_started = true
	get_tree().change_scene_to_file("res://menu.tscn")


func _process(delta: float) -> void:
	_t += delta
	for i in _torches.size():
		_torches[i].texture = _torch_tex[int(_t * 7.0 + i * 1.3) % 3]
	for i in _ghosts.size():
		_ghosts[i].position.y = _ghost_y[i] + roundi(sin(_t * 2.0 + i)) * PX
	for i in _bats.size():
		_bats[i].texture = _bat_tex[int(_t * 6.0 + i) % 2]
		_bats[i].position.x = _bat_pos[i].x + roundi(sin(_t * 0.8 + i) * 8.0) * PX
		_bats[i].position.y = _bat_pos[i].y + roundi(sin(_t * 1.3 + i * 2.0) * 3.0) * PX
	for i in _lights.size():
		_lights[i].energy = 1.0 + 0.18 * sin(_t * 9.0 + i * 1.7) + 0.08 * sin(_t * 23.0 + i)


# ===========================================================================
# Escadas: passagem livre entre os lances (sem bater a cabeça nem ficar preso)
# ===========================================================================
# Regras (valem para as duas escadarias):
#  - Cada rampa só é sólida quando os pés do jogador estão EM CIMA dela.
#    Quem passa por baixo atravessa -> acabou a batida de cabeça entre lances.
#  - Subir um lance que parte do nível onde você está: segure CIMA (embarque).
#    Descer pelo fim de um lance acontece sozinho.
#  - Descer atravessando o piso da escada: segure BAIXO.
const STAIR_TOL_BELOW := 10.0
const STAIR_TOL_ABOVE := 3.0
const STAIR_END_REACH := 24.0


func _physics_process(delta: float) -> void:
	_update_stairs(delta)


func _on_stair_enter(body: Node2D) -> void:
	var cb := body as CharacterBody2D
	if cb == null:
		return
	_stair_body = cb
	if auto_tune_player:
		cb.floor_max_angle = maxf(cb.floor_max_angle, deg_to_rad(46.0))
		cb.floor_snap_length = maxf(cb.floor_snap_length, 14.0)


func _on_stair_exit(body: Node2D) -> void:
	if body == _stair_body:
		_stair_body = null


func _up_held() -> bool:
	return (InputMap.has_action(stair_up_action) and Input.is_action_pressed(stair_up_action)) or Input.is_key_pressed(KEY_W)


func _down_held() -> bool:
	return (InputMap.has_action(stair_down_action) and Input.is_action_pressed(stair_down_action)) or Input.is_key_pressed(KEY_S)


func _set_stair_slabs_disabled(v: bool) -> void:
	if v == _slabs_off:
		return
	_slabs_off = v
	for cs in _stair_slabs:
		cs.disabled = v


func _body_feet(b: Node2D) -> Vector2:
	for ch in b.get_children():
		var cs := ch as CollisionShape2D
		if cs != null and cs.shape != null:
			var half := 0.0
			if cs.shape is RectangleShape2D:
				half = (cs.shape as RectangleShape2D).size.y * 0.5
			elif cs.shape is CapsuleShape2D:
				half = (cs.shape as CapsuleShape2D).height * 0.5
			elif cs.shape is CircleShape2D:
				half = (cs.shape as CircleShape2D).radius
			return Vector2(cs.global_position.x, cs.global_position.y + half)
	return b.global_position


func _update_stairs(delta: float) -> void:
	if not is_instance_valid(_stair_body):
		_stair_body = null
		for r in _ramps:
			r["engaged"] = false
			var cp0: CollisionPolygon2D = r["cp"]
			cp0.disabled = true
		_drop_t = 0.0
		_set_stair_slabs_disabled(false)
		return

	var feet := _body_feet(_stair_body)
	var want_up := _up_held()
	if _down_held():
		_drop_t = 0.25
	else:
		_drop_t = maxf(_drop_t - delta, 0.0)
	_set_stair_slabs_disabled(_drop_t > 0.0)

	for r in _ramps:
		var lo: Vector2 = r["lo"]
		var hi: Vector2 = r["up"]
		var xlo := minf(lo.x, hi.x)
		var xhi := maxf(lo.x, hi.x)
		var solid := false
		if feet.x >= xlo - 12.0 and feet.x <= xhi + 12.0:
			var cx := clampf(feet.x, xlo, xhi)
			var sy := lo.y + (hi.y - lo.y) * (cx - lo.x) / (hi.x - lo.x)
			var dy := feet.y - sy  # > 0: pés abaixo da superfície da rampa
			if dy > STAIR_TOL_BELOW:
				r["engaged"] = false  # por baixo: atravessa
			elif dy < -STAIR_TOL_ABOVE:
				r["engaged"] = true  # por cima: pousa / anda sobre a rampa
			elif not r["engaged"]:
				# colado na superfície, ainda sem ter embarcado
				var at_top := absf(feet.x - hi.x) <= STAIR_END_REACH
				if at_top or want_up:
					r["engaged"] = true
			solid = r["engaged"]
		else:
			r["engaged"] = false
		var cp: CollisionPolygon2D = r["cp"]
		cp.disabled = not solid


# ===========================================================================
# Elevador interativo: [E] abre o painel; 0 / 1 / 2 / 3 escolhem o andar
# Porta de saída do térreo: [E] abre o painel de senha e, se correta, vence
# ===========================================================================
const ELEV_KEYS := {
	KEY_0: "G", KEY_1: "1", KEY_2: "2", KEY_3: "3",
	KEY_KP_0: "G", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3",
}


func _key_is(ke: InputEventKey, key: int) -> bool:
	return ke.keycode == key or ke.physical_keycode == key


func _unhandled_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	# depois de vencer: só [R] funciona (reinicia a cena)
	if _won:
		if _key_is(ke, KEY_R):
			get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()
		return
	if _password_layer != null and _password_layer.visible:
		if _key_is(ke, KEY_ESCAPE):
			_close_password_panel()
		elif _key_is(ke, KEY_BACKSPACE):
			_password_value = _password_value.left(maxi(_password_value.length() - 1, 0))
			_password_feedback = ""
			_update_password_panel()
		elif _key_is(ke, KEY_ENTER) or _key_is(ke, KEY_KP_ENTER):
			_submit_password()
		else:
			var digit := _key_digit(ke)
			if digit != "":
				if _password_value.length() < 3:
					_password_value += digit
					_password_feedback = ""
					_update_password_panel()
		get_viewport().set_input_as_handled()
		return
	if _network_layer != null and _network_layer.visible:
		if _key_is(ke, KEY_ESCAPE) or _key_is(ke, KEY_E):
			_close_network_panel()
		get_viewport().set_input_as_handled()
		return
	if _menu_open:
		if _key_is(ke, KEY_E) or ke.keycode == KEY_ESCAPE:
			_close_menu()
		else:
			for k in ELEV_KEYS:
				if _key_is(ke, k):
					_select_floor(ELEV_KEYS[k])
					break
		get_viewport().set_input_as_handled()
	elif _elev_body != null and _key_is(ke, KEY_E):
		_open_menu()
		get_viewport().set_input_as_handled()
	elif _exit_body != null and _key_is(ke, KEY_E):
		_open_password_panel()
		get_viewport().set_input_as_handled()
	elif _server_body != null and _key_is(ke, KEY_E):
		_enable_network()
		get_viewport().set_input_as_handled()
	elif _monitor_body != null and _key_is(ke, KEY_E):
		_read_monitor(_monitor_index)
		get_viewport().set_input_as_handled()
	elif _director_body != null and _key_is(ke, KEY_E):
		_obtain_network_cable()
		get_viewport().set_input_as_handled()


func _on_elevator_enter(fid: String, body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	_elev_body = body
	_elev_floor = fid
	_show_hint(true)


func _on_elevator_exit(fid: String, body: Node2D) -> void:
	if body == _elev_body and _elev_floor == fid:
		if _menu_open:
			_close_menu()
		_elev_body = null
		_elev_floor = ""
		_show_hint(false)


func _build_hint() -> void:
	var c := PixelCanvas.new(53, 9)
	c.rect(0, 0, 53, 9, INK)
	c.outline(0, 0, 53, 9, YELLOW)
	c.text("E - ELEVADOR", 3, 2, WHITE)
	_hint = _make_sprite(ImageTexture.create_from_image(c.img), Vector2.ZERO, self)
	_hint.z_index = 6
	_hint.visible = false


func _show_hint(v: bool) -> void:
	if _hint == null:
		return
	_hint.visible = v and not _menu_open
	if v and _elev_floor != "":
		_hint.position = Vector2(ELEV_X - 53.0 * PX / 2.0, float(FLOORS[_elev_floor]) - 204.0)


func _panel_texture(current: String) -> ImageTexture:
	var c := PixelCanvas.new(104, 56)
	c.rect(0, 0, 104, 56, PURPLE_DK)
	c.outline(0, 0, 104, 56, INK)
	c.outline(2, 2, 100, 52, ORANGE)
	c.text_center("ELEVADOR", 52, 6, YELLOW)
	var rows := [["G", "0 - TERREO"], ["1", "1 - PRIMEIRO ANDAR"], ["2", "2 - SEGUNDO ANDAR"], ["3", "3 - TERCEIRO ANDAR"]]
	for i in rows.size():
		var y := 16 + i * 8
		var is_cur: bool = rows[i][0] == current
		if is_cur:
			c.text(">", 7, y, YELLOW)
		c.text(rows[i][1], 13, y, YELLOW if is_cur else WHITE)
	c.text_center("E OU ESC FECHA", 52, 48, STEEL)
	return ImageTexture.create_from_image(c.img)


func _open_menu() -> void:
	if _menu_open or _elev_body == null:
		return
	_menu_open = true
	_show_hint(false)
	_freeze_body(_elev_body, true)
	if _menu_layer == null:
		_menu_layer = CanvasLayer.new()
		_menu_layer.layer = 20
		add_child(_menu_layer)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.45)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_menu_layer.add_child(dim)
		_menu_sprite = Sprite2D.new()
		_menu_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_menu_layer.add_child(_menu_sprite)
	_menu_sprite.texture = _panel_texture(_elev_floor)
	var vp := get_viewport().get_visible_rect().size
	var sc := clampi(int(vp.x / 160.0), 1, PX)
	_menu_sprite.scale = Vector2(sc, sc)
	_menu_sprite.position = vp / 2.0
	_menu_layer.visible = true


func _close_menu() -> void:
	if not _menu_open:
		return
	_menu_open = false
	if _menu_layer != null:
		_menu_layer.visible = false
	if is_instance_valid(_elev_body):
		_freeze_body(_elev_body, false)
	_show_hint(_elev_body != null)


func _select_floor(fid: String) -> void:
	var body := _elev_body
	var current := _elev_floor
	_close_menu()
	if body == null or fid == current:
		return
	teleport_to_floor(body, fid)


# Congela o jogador enquanto o painel está aberto (sem removê-lo da física,
# para o elevador não achar que ele saiu da zona).
func _freeze_body(b: Node, frozen: bool) -> void:
	if frozen:
		_saved_proc = [b.is_processing(), b.is_physics_processing(), b.is_processing_input(), b.is_processing_unhandled_input()]
		b.set_process(false)
		b.set_physics_process(false)
		b.set_process_input(false)
		b.set_process_unhandled_input(false)
		if b is CharacterBody2D:
			b.velocity = Vector2.ZERO
	elif _saved_proc.size() == 4:
		b.set_process(_saved_proc[0])
		b.set_physics_process(_saved_proc[1])
		b.set_process_input(_saved_proc[2])
		b.set_process_unhandled_input(_saved_proc[3])
		_saved_proc = []


# ===========================================================================
# Porta de saída do térreo (vitória)
# ===========================================================================
func _on_exit_enter(body: Node2D) -> void:
	if _won or not (body is CharacterBody2D):
		return
	_exit_body = body
	_show_door_hint(true)


func _on_exit_exit(body: Node2D) -> void:
	if body == _exit_body:
		_exit_body = null
		_show_door_hint(false)


func _show_door_hint(v: bool) -> void:
	if _door_hint == null:
		return
	_door_hint.visible = v and not _won


func _key_digit(ke: InputEventKey) -> String:
	var digits := {
		KEY_0: "0", KEY_1: "1", KEY_2: "2", KEY_3: "3", KEY_4: "4",
		KEY_5: "5", KEY_6: "6", KEY_7: "7", KEY_8: "8", KEY_9: "9",
		KEY_KP_0: "0", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3", KEY_KP_4: "4",
		KEY_KP_5: "5", KEY_KP_6: "6", KEY_KP_7: "7", KEY_KP_8: "8", KEY_KP_9: "9",
	}
	for key in digits:
		if _key_is(ke, key):
			return digits[key]
	return ""


func _password_texture() -> ImageTexture:
	var c := PixelCanvas.new(124, 64)
	c.rect(0, 0, 124, 64, PURPLE_DK)
	c.outline(0, 0, 124, 64, INK)
	c.outline(2, 2, 120, 60, ORANGE)
	c.text_center("SENHA DA SAIDA", 62, 7, YELLOW)
	c.text_center("DIGITOS: " + ("*".repeat(_password_value.length()) + "_".repeat(3 - _password_value.length())), 62, 19, WHITE, 2)
	if _password_feedback != "":
		c.text_center(_password_feedback, 62, 35, ORANGE if _password_feedback == "ERRADA!" else GREEN)
	else:
		c.text_center("3 DIGITOS + ENTER", 62, 35, STEEL)
	c.text_center("ESC FECHA", 62, 49, STEEL)
	return ImageTexture.create_from_image(c.img)


func _open_password_panel() -> void:
	if _password_layer != null and _password_layer.visible:
		return
	_password_value = ""
	_password_feedback = ""
	_freeze_body(_exit_body, true)
	if _password_layer == null:
		_password_layer = CanvasLayer.new()
		_password_layer.layer = 20
		add_child(_password_layer)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.45)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_password_layer.add_child(dim)
		_password_sprite = Sprite2D.new()
		_password_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_password_layer.add_child(_password_sprite)
	_password_sprite.texture = _password_texture()
	var vp := get_viewport().get_visible_rect().size
	var sc := clampi(int(vp.x / 160.0), 1, PX)
	_password_sprite.scale = Vector2(sc, sc)
	_password_sprite.position = vp / 2.0
	_password_layer.visible = true


func _update_password_panel() -> void:
	if _password_sprite != null:
		_password_sprite.texture = _password_texture()


func _close_password_panel() -> void:
	if _password_layer == null or not _password_layer.visible:
		return
	_password_layer.visible = false
	if is_instance_valid(_exit_body):
		_freeze_body(_exit_body, false)


func _submit_password() -> void:
	if _password_value.length() != 3:
		_password_feedback = "3 DIGITOS!"
		_update_password_panel()
		return
	if _password_value != _exit_password:
		_password_value = ""
		_password_feedback = "ERRADA!"
		_update_password_panel()
		return
	_close_password_panel()
	_open_exit_door()


func _on_server_enter(body: Node2D) -> void:
	if body is CharacterBody2D:
		_server_body = body


func _on_server_exit(body: Node2D) -> void:
	if body == _server_body:
		_server_body = null


func _on_monitor_enter(index: int, body: Node2D) -> void:
	if body is CharacterBody2D:
		_monitor_body = body
		_monitor_index = index


func _on_monitor_exit(index: int, body: Node2D) -> void:
	if body == _monitor_body:
		_monitor_body = null
		_monitor_index = -1


func _on_directoria_enter(body: Node2D) -> void:
	if body is CharacterBody2D:
		_director_body = body


func _on_directoria_exit(body: Node2D) -> void:
	if body == _director_body:
		_director_body = null


func _obtain_network_cable() -> void:
	_cable_obtained = true
	_network_message = "CABO DE REDE OBTIDO!"
	_network_digit_only = false
	_open_network_panel(_director_body)


func _enable_network() -> void:
	if not _cable_obtained:
		_network_message = "PRECISA DO CABO DE REDE"
		_network_digit_only = false
		_open_network_panel(_server_body)
		return
	_network_enabled = true
	_network_message = "REDE HABILITADA!"
	_network_digit_only = false
	_open_network_panel(_server_body)


func _read_monitor(index: int) -> void:
	if not _network_enabled:
		_network_message = "SEM CONEXAO COM A REDE"
	else:
		_network_message = _exit_password[index]
		_network_digit_only = true
		if index >= 0 and index < _collected_digits.size() and not _collected_digits[index]:
			_collected_digits[index] = true
			_tasks_completed += 1
			task_completed.emit(_tasks_completed)
			var player := get_tree().get_first_node_in_group("player")
			if player != null:
				player.set("tasks_completed", _tasks_completed)
	_open_network_panel(_monitor_body)


func _network_texture() -> ImageTexture:
	var c := PixelCanvas.new(124, 48)
	c.rect(0, 0, 124, 48, PURPLE_DK)
	c.outline(0, 0, 124, 48, INK)
	c.outline(2, 2, 120, 44, ORANGE)
	if _network_digit_only:
		c.text_center(_network_message, 62, 14, WHITE, 4)
		return ImageTexture.create_from_image(c.img)
	c.text_center("SISTEMA", 62, 7, YELLOW)
	c.text_center(_network_message, 62, 21, WHITE, 1 if _network_message.length() > 18 else 2)
	c.text_center("E OU ESC FECHA", 62, 37, STEEL)
	return ImageTexture.create_from_image(c.img)


func _open_network_panel(body: Node2D = null) -> void:
	_network_body = body if body != null else (_server_body if _server_body != null else _monitor_body)
	_freeze_body(_network_body, true)
	if _network_layer == null:
		_network_layer = CanvasLayer.new()
		_network_layer.layer = 20
		add_child(_network_layer)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.45)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		_network_layer.add_child(dim)
		_network_sprite = Sprite2D.new()
		_network_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_network_layer.add_child(_network_sprite)
	_network_sprite.texture = _network_texture()
	var vp := get_viewport().get_visible_rect().size
	var sc := clampi(int(vp.x / 160.0), 1, PX)
	_network_sprite.scale = Vector2(sc, sc)
	_network_sprite.position = vp / 2.0
	_network_layer.visible = true


func _close_network_panel() -> void:
	if _network_layer == null or not _network_layer.visible:
		return
	_network_layer.visible = false
	if is_instance_valid(_network_body):
		_freeze_body(_network_body, false)
	_network_body = null


# Prepara (escondidos) a porta aberta que cobre a porta fechada e a dica "E - ABRIR"
func _build_exit_door() -> void:
	for d in DOORS:
		if d["id"] != WIN_DOOR_ID:
			continue
		var fy := _fy(d["f"])
		var cx := roundi(float(d["x"]) / PX)
		var dx := cx - 6
		var dy := fy - 23
		# porta aberta: o vão fica iluminado (é a saída)
		var cv := PixelCanvas.new(20, 23)
		_draw_open_door(cv, 0, 0, EXIT_LIGHT)
		_exit_door_sprite = _make_sprite(ImageTexture.create_from_image(cv.img), Vector2(dx * PX, dy * PX), self)
		_exit_door_sprite.z_index = -9
		_exit_door_sprite.visible = false
		# dica
		var hc := PixelCanvas.new(41, 9)
		hc.rect(0, 0, 41, 9, INK)
		hc.outline(0, 0, 41, 9, YELLOW)
		hc.text("E - ABRIR", 3, 2, WHITE)
		var hp := Vector2(float(d["x"]) - 41.0 * PX / 2.0, float(FLOORS[d["f"]]) - 136.0)
		_door_hint = _make_sprite(ImageTexture.create_from_image(hc.img), hp, self)
		_door_hint.z_index = 6
		_door_hint.visible = false
		return


func _open_exit_door() -> void:
	if _won or _exit_body == null:
		return
	_won = true
	var body := _exit_body
	_show_door_hint(false)
	if _exit_door_sprite != null:
		_exit_door_sprite.visible = true
	_freeze_body(body, true)
	_show_win_panel()
	game_won.emit(body)


func _show_win_panel() -> void:
	var c := PixelCanvas.new(124, 52)
	c.rect(0, 0, 124, 52, PURPLE_DK)
	c.outline(0, 0, 124, 52, INK)
	c.outline(2, 2, 120, 48, ORANGE)
	c.text_center("VOCE VENCEU!", 62, 8, YELLOW, 2)
	c.text_center("A PORTA FOI ABERTA", 62, 26, WHITE)
	c.text_center("R - JOGAR DE NOVO", 62, 38, STEEL)
	_win_layer = CanvasLayer.new()
	_win_layer.layer = 30
	add_child(_win_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_layer.add_child(dim)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(c.img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var vp := get_viewport().get_visible_rect().size
	var sc := clampi(int(vp.x / 160.0), 1, PX)
	spr.scale = Vector2(sc, sc)
	spr.position = vp / 2.0
	_win_layer.add_child(spr)


# ===========================================================================
# Decoração da escadaria direita (cópia espelhada da esquerda)
# ===========================================================================
func _emblem(c: PixelCanvas, cx: int, cy: int) -> void:
	var shape := [Vector2i(0, 0), Vector2i(-8, -6), Vector2i(-16, -2), Vector2i(-12, 3), Vector2i(-6, 1),
		Vector2i(0, 6), Vector2i(6, 1), Vector2i(12, 3), Vector2i(16, -2), Vector2i(8, -6)]
	var shadow: Array = []
	var main: Array = []
	for p in shape:
		shadow.append(Vector2i(cx + p.x + 1, cy + p.y + 2))
		main.append(Vector2i(cx + p.x, cy + p.y + 1))
	c.poly(shadow, Color("2a1530"))
	c.poly(main, Color("4a1f3d"))
	c.text_center("FATEC", cx, cy - 1, Color("e6e6f0"))


func _art_right_stair_decor(c: PixelCanvas) -> void:
	var m := ART_W
	_spider(c, m - 22, _ceil_y("1") + 22, 1, INK, 18)
	_spider(c, m - 18, _ceil_y("G") + 30, 1, INK, 24)
	_spider(c, m - 11, 20, 1, INK, 12)
	c.sprite(ZOMBIE, PAL, m - 11 - 9, _fy("G") - 15, true)
	c.sprite(SCARECROW, PAL, m - 12 - 9, _fy("2") - 14, true)
	_emblem(c, m - 40, _fy("1") - 38)


# ===========================================================================
# API pública
# ===========================================================================
func get_spawn(spawn_name: String) -> Vector2:
	return to_global(SPAWNS.get(spawn_name, SPAWNS["entrada"]))


## Área total do mapa (inclui o espaço extra das laterais), em coordenadas locais.
## Útil para limites de câmera: limit_left = bounds.position.x, limit_right = bounds.end.x
func get_map_bounds() -> Rect2:
	return Rect2(-EXTRA, 0.0, MAP_SIZE.x + EXTRA * 2.0, MAP_SIZE.y)


func teleport_to_floor(body: Node2D, floor_id: String) -> void:
	var target := to_global(Vector2(ELEV_X, FLOORS[floor_id]))
	var feet := _body_feet(body)
	body.global_position = target + (body.global_position - feet)
	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO


# ===========================================================================
# Helpers
# ===========================================================================
func _fy(fid: String) -> int:
	return roundi(float(FLOORS[fid]) / PX)


func _ceil_y(fid: String) -> int:
	return roundi(float(CEILS[fid]) / PX)


func _tex_rows(rows: Array, pal: Dictionary = PAL) -> ImageTexture:
	var wd := 0
	for r in rows:
		wd = maxi(wd, (r as String).length())
	var cv := PixelCanvas.new(wd, rows.size())
	cv.sprite(rows, pal, 0, 0)
	return ImageTexture.create_from_image(cv.img)


func _make_sprite(tex: Texture2D, pos: Vector2, parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2(PX, PX)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	parent.add_child(s)
	return s


func _add_solid(parent: Node, rect: Rect2, one_way := false) -> CollisionShape2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.one_way_collision = one_way
	body.add_child(cs)
	parent.add_child(body)
	return cs


func _add_zone(parent: Node, zone_name: String, rect: Rect2) -> Area2D:
	var a := Area2D.new()
	a.name = zone_name
	a.position = rect.get_center()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	a.add_child(cs)
	parent.add_child(a)
	return a


# ===========================================================================
# Física: lajes, paredes, rampas
# ===========================================================================
func _build_collisions() -> void:
	var holder := Node2D.new()
	holder.name = "Collisions"
	add_child(holder)

	# As paredes externas recuaram EXTRA para cada lado (espaço vazio novo).
	# Tudo o mais (escadas, lajes internas) fica nas mesmas coordenadas de antes.
	var solids: Array[Rect2] = [
		Rect2(-EXTRA, 0, LEFT, MAP_SIZE.y),
		Rect2(R_WALL + EXTRA, 0, MAP_SIZE.x - R_WALL, MAP_SIZE.y),
		Rect2(-EXTRA, 0, MAP_SIZE.x + EXTRA * 2.0, TOP),
		Rect2(LEFT - EXTRA, Y_G, R_WALL - LEFT + EXTRA * 2.0, MAP_SIZE.y - Y_G),
	]
	for fid in ["1", "2", "3"]:
		var y: float = FLOORS[fid]
		solids.append(Rect2(STAIR_X1, y, RIGHT - STAIR_X1, SLAB_H))
		# trecho sobre a escada: dá para subir pelas rampas por baixo (agora também cobre o espaço extra)
		_stair_slabs.append(_add_solid(holder, Rect2(LEFT - EXTRA, y, STAIR_X1 - LEFT + EXTRA, SLAB_H), true))
		# escadaria direita (espelhada)
		_stair_slabs.append(_add_solid(holder, Rect2(R_STAIR_X1, y, R_WALL - R_STAIR_X1 + EXTRA, SLAB_H), true))
	for r in solids:
		_add_solid(holder, r)

	# Escadas em zigue-zague (rampas de ~42°, dentro do padrão de 45° do Godot)
	var ramps := [
		[Vector2(STAIR_X0, Y_G), Vector2(STAIR_X1, Y_1)],
		[Vector2(STAIR_X1, Y_1), Vector2(STAIR_X0, Y_2)],
		[Vector2(STAIR_X0, Y_2), Vector2(STAIR_X1, Y_3)],
		# escadaria direita (espelho)
		[Vector2(R_STAIR_X0, Y_G), Vector2(R_STAIR_X1, Y_1)],
		[Vector2(R_STAIR_X1, Y_1), Vector2(R_STAIR_X0, Y_2)],
		[Vector2(R_STAIR_X0, Y_2), Vector2(R_STAIR_X1, Y_3)],
	]
	for r in ramps:
		var a: Vector2 = r[0]
		var b: Vector2 = r[1]
		var body := StaticBody2D.new()
		var cp := CollisionPolygon2D.new()
		cp.polygon = PackedVector2Array([a, b, b + Vector2(0, 8), a + Vector2(0, 8)])
		cp.disabled = true  # ligada/desligada por _update_stairs()
		body.add_child(cp)
		holder.add_child(body)
		# a = ponta de baixo ("lo"), b = ponta de cima ("up")
		_ramps.append({"cp": cp, "lo": a, "up": b, "engaged": false})


func _build_zones() -> void:
	var zones := Node2D.new()
	zones.name = "Zones"
	add_child(zones)

	for d in DOORS:
		var fy: float = FLOORS[d["f"]]
		var id: String = d["id"]
		var z := _add_zone(zones, id, Rect2(float(d["x"]) - 28.0, fy - 92.0, 56.0, 92.0))
		z.body_entered.connect(func(body: Node2D) -> void: door_entered.emit(id, body))
		if id == WIN_DOOR_ID:
			z.body_entered.connect(_on_exit_enter)
			z.body_exited.connect(_on_exit_exit)
		elif id == "diretoria":
			z.body_entered.connect(_on_directoria_enter)
			z.body_exited.connect(_on_directoria_exit)

	for fid in FLOORS:
		var fy2: float = FLOORS[fid]
		var id2: String = fid
		var ez := _add_zone(zones, "Elevador_" + fid, Rect2(ELEV_X - 48.0, fy2 - 124.0, 96.0, 124.0))
		ez.body_entered.connect(func(body: Node2D) -> void:
			elevator_entered.emit(id2, body)
			_on_elevator_enter(id2, body)
		)
		ez.body_exited.connect(func(body: Node2D) -> void:
			elevator_exited.emit(id2, body)
			_on_elevator_exit(id2, body)
		)

	# servidor no 2º andar, à direita do elevador
	var server_zone := _add_zone(zones, "ServidorRede", Rect2(1080.0, FLOORS["2"] - 132.0, 160.0, 132.0))
	server_zone.body_entered.connect(_on_server_enter)
	server_zone.body_exited.connect(_on_server_exit)

	# Um monitor em cada andar, atrás da escada esquerda:
	# 3º andar = primeiro dígito, 2º = segundo, 1º = terceiro.
	var monitor_floors := ["3", "2", "1"]
	for i in monitor_floors.size():
		var monitor_floor: String = monitor_floors[i]
		var monitor_zone := _add_zone(
			zones,
			"MonitorSenha_" + monitor_floor,
			Rect2(20.0, FLOORS[monitor_floor] - 104.0, 100.0, 104.0)
		)
		var digit_index := i
		monitor_zone.body_entered.connect(func(body: Node2D) -> void: _on_monitor_enter(digit_index, body))
		monitor_zone.body_exited.connect(func(body: Node2D) -> void: _on_monitor_exit(digit_index, body))

	# zonas das escadarias (ligam o passe-livre das rampas enquanto o jogador está nelas)
	# agora incluem o espaço extra das laterais
	var sz_l := _add_zone(zones, "EscadaEsq", Rect2(LEFT - EXTRA, TOP, STAIR_X1 + 40.0 - LEFT + EXTRA, MAP_SIZE.y - TOP))
	var sz_r := _add_zone(zones, "EscadaDir", Rect2(R_STAIR_X1 - 40.0, TOP, R_WALL - R_STAIR_X1 + 40.0 + EXTRA, MAP_SIZE.y - TOP))
	for sz in [sz_l, sz_r]:
		sz.body_entered.connect(_on_stair_enter)
		sz.body_exited.connect(_on_stair_exit)


# ===========================================================================
# Arte estática
# ===========================================================================
func _render_static_art() -> void:
	var c := PixelCanvas.new(ART_W, ART_H)
	_art_background(c)
	_art_structure(c)
	_art_stairs(c)
	_art_ground(c)
	_art_floor1_like(c, "1")
	_art_floor2(c)
	_art_floor1_like(c, "3")
	_art_doors(c)
	_art_elevator(c)
	_art_extras(c)

	# acrescenta o espaço extra nas laterais (o desenho original não muda de lugar)
	var full := _extend_art(c)

	var spr := Sprite2D.new()
	spr.name = "PixelArt"
	spr.texture = ImageTexture.create_from_image(full.img)
	spr.centered = false
	spr.position = Vector2(-EXTRA, 0.0)
	spr.scale = Vector2(PX, PX)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = -10
	add_child(spr)


# Cria uma imagem EXTRA_ART pixels mais larga de cada lado. O miolo da arte original
# (de A_LEFT até A_R_WALL) é copiado intacto; as paredes externas antigas viram
# espaço interno (tijolos do mesmo estilo + lajes) e as paredes novas ficam nas pontas.
func _extend_art(old: PixelCanvas) -> PixelCanvas:
	var e := EXTRA_ART
	var w2 := ART_W + e * 2
	var f := PixelCanvas.new(w2, ART_H)
	var rwall_w := ART_W - A_R_WALL

	# teto e paredes externas novas
	f.slab(0, 0, w2, 4, SLAB, SLAB_HI, SLAB_DK)
	f.bricks(0, 4, A_LEFT, ART_H - 4, BRICK2, MORTAR, 5)
	f.bricks(w2 - rwall_w, 4, rwall_w, ART_H - 4, BRICK2, MORTAR, 9)

	# fundo de tijolos igual ao das caixas de escada (mesma grade e mesma semente, deslocada em e)
	# a faixa desenhada passa um pouco para dentro da área copiada; a cópia abaixo cobre o excesso
	for fid in FLOORS:
		var top := _ceil_y(fid)
		var h := _fy(fid) - top
		f.bricks(A_LEFT, top, e + 7, h, BRICK1, MORTAR, 11 - e)
		f.bricks(A_RIGHT + e, top, (A_R_WALL - A_RIGHT) + e, h, BRICK1, MORTAR, 11 - e)
		# laje do andar nas duas faixas novas
		var sy := _fy(fid)
		f.slab(A_LEFT, sy, e, 6, SLAB, SLAB_HI, SLAB_DK)
		f.slab(A_R_WALL + e, sy, e, 6, SLAB, SLAB_HI, SLAB_DK)

	# miolo original, na mesma posição relativa (deslocado em e pixels de arte)
	f.img.blit_rect(old.img, Rect2i(A_LEFT, 0, A_R_WALL - A_LEFT, ART_H), Vector2i(A_LEFT + e, 0))
	return f


func _wall(c: PixelCanvas, x: int, y: int, w: int, h: int) -> void:
	c.rect(x, y, w, h, WALL)
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var n := c.hash2(xx, yy)
			if n < 0.05:
				c.px(xx, yy, WALL_SH)
			elif n > 0.985:
				c.px(xx, yy, WALL_HI)
	c.rect(x, y + h - 9, w, 9, STRIPE)
	c.hline(x, y + h - 9, w, STRIPE_HI)
	c.hline(x, y + h - 1, w, STRIPE_DK)
	c.rect(x, y + 3, w, 2, PIPE)
	c.hline(x, y + 3, w, PIPE_HI)


func _art_background(c: PixelCanvas) -> void:
	c.rect(0, 0, ART_W, ART_H, SKY)
	for fid in FLOORS:
		var top := _ceil_y(fid)
		var bottom := _fy(fid)
		var h := bottom - top
		c.bricks(A_LEFT, top, A_STAIR1 - A_LEFT, h, BRICK1, MORTAR, 11)
		_wall(c, A_STAIR1, top, A_SHAFT_L - A_STAIR1, h)
		c.bricks(A_SHAFT_L, top, A_SHAFT_R - A_SHAFT_L, h, BRICK2, MORTAR, 23)
		c.rect(A_SHAFT_L + 9, top, 28, h, Color("1c1612"))
		if fid == "2":
			c.bricks(A_SHAFT_R, top, A_RIGHT - A_SHAFT_R, h, BRICK1, MORTAR, 37)
		else:
			_wall(c, A_SHAFT_R, top, A_RIGHT - A_SHAFT_R, h)
		# caixa da escadaria direita (espelho da esquerda)
		c.bricks(A_RIGHT, top, A_R_WALL - A_RIGHT, h, BRICK1, MORTAR, 11)


func _art_structure(c: PixelCanvas) -> void:
	c.slab(0, 0, ART_W, 4, SLAB, SLAB_HI, SLAB_DK)
	c.bricks(0, 4, A_LEFT, ART_H - 4, BRICK2, MORTAR, 5)
	c.bricks(A_R_WALL, 4, ART_W - A_R_WALL, ART_H - 4, BRICK2, MORTAR, 9)
	c.slab(A_LEFT, 240, A_R_WALL - A_LEFT, ART_H - 240, SLAB, SLAB_HI, SLAB_DK)
	for fid in ["1", "2", "3"]:
		c.slab(A_LEFT, _fy(fid), A_R_WALL - A_LEFT, 6, SLAB, SLAB_HI, SLAB_DK)


func _art_stairs(c: PixelCanvas) -> void:
	var ramps := [
		[Vector2i(A_STAIR0, 240), Vector2i(A_STAIR1, 180)],
		[Vector2i(A_STAIR1, 180), Vector2i(A_STAIR0, 120)],
		[Vector2i(A_STAIR0, 120), Vector2i(A_STAIR1, 60)],
		# escadaria direita (espelho)
		[Vector2i(A_R_STAIR0, 240), Vector2i(A_RIGHT, 180)],
		[Vector2i(A_RIGHT, 180), Vector2i(A_R_STAIR0, 120)],
		[Vector2i(A_R_STAIR0, 120), Vector2i(A_RIGHT, 60)],
	]
	var n := 15
	for r in ramps:
		var a: Vector2i = r[0]
		var b: Vector2i = r[1]
		for i in range(n):
			var x0 := a.x + roundi(float(b.x - a.x) * i / n)
			var x1 := a.x + roundi(float(b.x - a.x) * (i + 1) / n)
			var y0 := a.y + roundi(float(b.y - a.y) * i / n)
			var lx := mini(x0, x1)
			var sw := absi(x1 - x0) + 1
			c.rect(lx, y0, sw, 1, WOOD_HI)
			c.rect(lx, y0 + 1, sw, 2, WOOD)
			c.rect(lx, y0 + 3, sw, 1, WOOD_DK)
		c.line(a.x, a.y + 4, b.x, b.y + 4, WOOD_DK)
		# corrimão
		c.line(a.x, a.y - 12, b.x, b.y - 12, STEEL_DK)
		for i in range(0, n + 1, 3):
			var qx := a.x + roundi(float(b.x - a.x) * i / n)
			var qy := a.y + roundi(float(b.y - a.y) * i / n)
			c.vline(qx, qy - 12, 12, STEEL_DK)


# ---- helpers de objetos ----------------------------------------------------
func _sign(c: PixelCanvas, r: Rect2i, txt: String, bg: Color, fg: Color) -> void:
	c.rect(r.position.x, r.position.y, r.size.x, r.size.y, bg)
	c.outline(r.position.x, r.position.y, r.size.x, r.size.y, INK)
	var th := txt.split("\n").size() * 6 - 1
	c.text_center(txt, r.position.x + r.size.x / 2, r.position.y + (r.size.y - th) / 2, fg)


func _desk(c: PixelCanvas, cx: int, fy: int) -> void:
	c.rect(cx - 7, fy - 9, 14, 2, Color("3a3f4a"))
	c.hline(cx - 7, fy - 9, 14, Color("5a6070"))
	c.vline(cx - 6, fy - 7, 7, Color("2b2f36"))
	c.vline(cx + 5, fy - 7, 7, Color("2b2f36"))
	c.rect(cx - 4, fy - 15, 8, 6, INK)
	c.rect(cx - 3, fy - 14, 6, 4, CYAN)
	c.hline(cx - 3, fy - 14, 6, Color("8fd8f0"))
	c.rect(cx - 1, fy - 10, 2, 1, INK)
	# cadeira
	c.rect(cx + 8, fy - 13, 1, 6, Color("20304a"))
	c.rect(cx + 6, fy - 7, 4, 1, Color("20304a"))
	c.vline(cx + 8, fy - 6, 5, Color("20304a"))
	c.hline(cx + 6, fy - 1, 5, Color("20304a"))


func _monitor(c: PixelCanvas, x: int, y: int, w: int, h: int, col: Color) -> void:
	c.rect(x, y, w, h, INK)
	c.rect(x + 1, y + 1, w - 2, h - 2, col)
	c.hline(x + 1, y + 1, w - 2, col.lightened(0.25))


func _pumpkin(c: PixelCanvas, cx: int, by: int, r: int) -> void:
	var ry := int(r * 0.8)
	var cy := by - ry
	c.ellipse(cx, cy, r, ry, ORANGE)
	c.vline(cx - r / 2, cy - ry + 1, ry * 2 - 1, ORANGE_DK)
	c.vline(cx + r / 2, cy - ry + 1, ry * 2 - 1, ORANGE_DK)
	c.hline(cx - r / 3, cy - ry + 1, r / 2, ORANGE.lightened(0.3))
	c.rect(cx - 1, cy - ry - 2, 2, 3, GREEN)
	if r < 8:
		c.px(cx - 2, cy - 1, YELLOW)
		c.px(cx + 1, cy - 1, YELLOW)
		c.hline(cx - 2, cy + 1, 4, YELLOW)
	else:
		var k := float(r) / 12.0
		var e := func(v: float) -> int: return roundi(v * k)
		c.poly([Vector2i(cx - e.call(8.0), cy - e.call(1.0)), Vector2i(cx - e.call(2.0), cy - e.call(1.0)), Vector2i(cx - e.call(5.0), cy - e.call(7.0))], YELLOW)
		c.poly([Vector2i(cx + e.call(2.0), cy - e.call(1.0)), Vector2i(cx + e.call(8.0), cy - e.call(1.0)), Vector2i(cx + e.call(5.0), cy - e.call(7.0))], YELLOW)
		c.poly([
			Vector2i(cx - e.call(8.0), cy + e.call(2.0)), Vector2i(cx - e.call(5.0), cy + e.call(6.0)),
			Vector2i(cx - e.call(2.0), cy + e.call(3.0)), Vector2i(cx + e.call(2.0), cy + e.call(6.0)),
			Vector2i(cx + e.call(5.0), cy + e.call(3.0)), Vector2i(cx + e.call(8.0), cy + e.call(2.0)),
			Vector2i(cx + e.call(5.0), cy + e.call(8.0)), Vector2i(cx - e.call(5.0), cy + e.call(8.0)),
		], YELLOW)


func _bunting(c: PixelCanvas, x0: int, x1: int, y: int) -> void:
	var span := x1 - x0
	var prev := Vector2i(x0, y)
	for i in range(1, 21):
		var t := i / 20.0
		var p := Vector2i(x0 + roundi(t * span), y + roundi(sin(t * PI) * 4.0))
		c.line(prev.x, prev.y, p.x, p.y, INK)
		prev = p
	for i in range(1, 10):
		var t2 := i / 10.0
		var fx := x0 + roundi(t2 * span)
		var fyy := y + roundi(sin(t2 * PI) * 4.0)
		var col := PURPLE if i % 2 == 0 else ORANGE
		c.poly([Vector2i(fx - 2, fyy + 1), Vector2i(fx + 2, fyy + 1), Vector2i(fx, fyy + 5)], col)


func _web(c: PixelCanvas, x: int, y: int, sx: int, sy: int, size: int) -> void:
	var col := Color(0.92, 0.92, 1.0, 0.6)
	var rays := 5
	for i in rays:
		var ang := (PI / 2.0) * i / (rays - 1)
		c.line(x, y, x + sx * roundi(cos(ang) * size), y + sy * roundi(sin(ang) * size), col)
	for k in range(1, 4):
		var rad := size * k / 3
		var prev := Vector2i.ZERO
		for i in rays:
			var ang2 := (PI / 2.0) * i / (rays - 1)
			var p := Vector2i(x + sx * roundi(cos(ang2) * rad), y + sy * roundi(sin(ang2) * rad))
			if i > 0:
				c.line(prev.x, prev.y, p.x, p.y, col)
			prev = p


func _spider(c: PixelCanvas, x: int, y: int, s: int, body: Color, thread: int = 0) -> void:
	# (x, y) = centro do corpo
	if thread > 0:
		c.vline(x, y - thread, thread, Color(0.9, 0.9, 1.0, 0.6))
	for i in 4:
		for sx in [-1, 1]:
			var knee := Vector2i(x + sx * (3 + i * 2) * s / 2, y - (3 - i) * s / 2)
			var foot := Vector2i(x + sx * (5 + i * 2) * s / 2, y + (3 + i) * s / 2)
			c.line(x, y, knee.x, knee.y, body)
			c.line(knee.x, knee.y, foot.x, foot.y, body)
	c.ellipse(x, y, 2 * s, roundi(1.5 * s), body)
	c.disc(x - 2 * s, y - s, maxi(s, 1), body)
	if s >= 3:
		c.ellipse(x + s, y, s, s, Color("e6e0ee"))
		c.px(x - 2 * s - 1, y - s - 1, Color("ff3030"))
		c.px(x - 2 * s + 1, y - s - 1, Color("ff3030"))


func _night_window(c: PixelCanvas, x: int, y: int, w: int, h: int, seed_: int, with_bat: bool) -> void:
	c.rect(x, y, w, h, Color("0d1633"))
	for i in 14:
		c.px(x + 1 + int(c.hash2(i + seed_, 3) * (w - 2)), y + 1 + int(c.hash2(i, seed_) * (h * 0.5)), Color("c8d0ff"))
	c.disc(x + w - 9, y + 7, 3, Color("f4e8b0"))
	if with_bat:
		c.sprite(BAT_FRAMES[0], PAL, x + w - 14, y + 4)
	var bx := x + 1
	var k := 0
	while bx < x + w - 2:
		var bw := 5 + int(c.hash2(k, seed_) * 6)
		var bh := 5 + int(c.hash2(seed_, k) * (h * 0.5))
		bw = mini(bw, x + w - 1 - bx)
		c.rect(bx, y + h - bh, bw, bh, Color("171f3d"))
		for wy in range(y + h - bh + 2, y + h - 1, 3):
			for wx in range(bx + 1, bx + bw - 1, 2):
				if c.hash2(wx, wy + seed_) > 0.55:
					c.px(wx, wy, Color("f4d27a"))
		bx += bw + 1
		k += 1
	c.outline(x, y, w, h, INK)
	c.vline(x + w / 2, y, h, INK)
	c.hline(x, y + h - 1, w, INK)


# ---- térreo ------------------------------------------------------------------
func _art_ground(c: PixelCanvas) -> void:
	var fy := _fy("G")
	# entrada principal
	c.rect(107, fy - 29, 53, 29, Color("1e1b2b"))
	for i in 4:
		c.rect(114 + i * 3, fy - 6 - i * 3, 32 - i * 6, 3, Color("3a3a4c"))
		c.hline(114 + i * 3, fy - 6 - i * 3, 32 - i * 6, Color("55556b"))
	c.outline(107, fy - 29, 53, 29, INK)
	_sign(c, Rect2i(99, fy - 53, 71, 13), "ENTRADA PRINCIPAL\nFATEC CAMPINAS", Color("e8e8e8"), INK)
	_sign(c, Rect2i(105, fy - 39, 61, 9), "FELIZ HALLOWEEN", Color("201a1a"), Color("ff8a1f"))
	# recepção da Game Jam
	_sign(c, Rect2i(285, fy - 36, 47, 13), "RECEPÇÃO DE\nGAME JAM", Color("1a1410"), YELLOW)
	c.rect(287, fy - 15, 39, 15, Color("14101a"))
	c.hline(287, fy - 15, 39, Color("3a3050"))
	_monitor(c, 313, fy - 21, 7, 6, CYAN)
	# folhas e doces
	for cxl in [104, 171]:
		for i in 42:
			var xx: int = cxl - 12 + int(c.hash2(i, cxl) * 24)
			var yy := fy - 1 - int(c.hash2(cxl, i) * 3)
			var cols := [Color("c8641a"), Color("8a4a1a"), Color("e8a030"), Color("6a2a8a"), Color("d03050")]
			c.px(xx, yy, cols[int(c.hash2(i, i + cxl) * cols.size())])
	# personagens
	c.sprite(ZOMBIE, PAL, 11, fy - 15)
	var statue_pal := PAL.duplicate()
	statue_pal["G"] = Color("9a9a98")
	statue_pal["b"] = Color("7a7a7e")
	c.sprite(ZOMBIE, statue_pal, 82, fy - 15, true)
	c.rect(80, fy - 1, 13, 1, SLAB_DK)


# ---- andares 1 e 3 (parecidos) ---------------------------------------------
func _art_floor1_like(c: PixelCanvas, fid: String) -> void:
	var fy := _fy(fid)
	var seed_ := 5 if fid == "1" else 17
	_bunting(c, 80, 150, fy - 47)
	# mural de avisos
	c.rect(101, fy - 28, 14, 12, Color("3a6b4a"))
	c.outline(101, fy - 28, 14, 12, WOOD)
	for i in 4:
		c.rect(103 + (i % 2) * 6, fy - 26 + (i / 2) * 5, 4, 4, Color("e8e4d4"))
	# janela noturna + mesas
	_night_window(c, 247, fy - 39, 70, 25, seed_, fid == "3")
	var desks := [270, 287, 304] if fid == "1" else [270, 296]
	for dx in desks:
		_desk(c, dx, fy)
	# rack de servidor
	c.rect(325, fy - 25, 11, 25, Color("8a949c"))
	c.outline(325, fy - 25, 11, 25, INK)
	for i in 5:
		c.rect(327, fy - 23 + i * 4, 7, 3, Color("3a4148"))
		c.px(333, fy - 22 + i * 4, Color("5cff7a"))
	# Monitor da senha atrás da escada esquerda em cada andar.
	if fid == "1" or fid == "2" or fid == "3":
		_monitor(c, 7, fy - 38, 12, 9, CYAN)
	if fid == "1":
		# brasão FATEC (morcego)
		var cx := 40
		var cy := fy - 38
		var shape := [Vector2i(0, 0), Vector2i(-8, -6), Vector2i(-16, -2), Vector2i(-12, 3), Vector2i(-6, 1),
			Vector2i(0, 6), Vector2i(6, 1), Vector2i(12, 3), Vector2i(16, -2), Vector2i(8, -6)]
		var shadow: Array = []
		var main: Array = []
		for p in shape:
			shadow.append(Vector2i(cx + p.x * 1 + 1, cy + p.y + 2))
			main.append(Vector2i(cx + p.x, cy + p.y + 1))
		c.poly(shadow, Color("2a1530"))
		c.poly(main, Color("4a1f3d"))
		c.text_center("FATEC", cx, cy - 1, Color("e6e6f0"))
	else:
		# faixa da Game Jam
		_sign(c, Rect2i(250, 7, 85, 14), "GAME JAM 2026\nO RETORNO DO VAMPIRO", PURPLE_DK, Color("ffb347"))


# ---- andar 2 (Lab Max) -------------------------------------------------------
func _art_floor2(c: PixelCanvas) -> void:
	var fy := _fy("2")
	# Monitor da senha em destaque, atrás do lance da escada esquerda.
	_monitor(c, 7, fy - 38, 12, 9, CYAN)
	# telão e monitores do Lab Max
	_sign(c, Rect2i(103, fy - 34, 40, 22), "FATEC\nHALLOWEEN\nGAME JAM", Color("2b1b4a"), YELLOW)
	for i in 2:
		for j in 2:
			_monitor(c, 85 + i * 8, fy - 36 + j * 8, 7, 6, BLUE if j == 0 else CYAN)
			_monitor(c, 146 + i * 8, fy - 36 + j * 8, 7, 6, BLUE if j == 0 else CYAN)
	for dx in [92, 112, 132, 152]:
		_desk(c, dx, fy)
	# sala de vidro com servidores (ala direita)
	c.rect(279, fy - 31, 28, 31, Color("c9d6e0"))
	for i in 3:
		c.rect(282 + i * 8, fy - 24, 6, 24, Color("6c737a"))
		c.outline(282 + i * 8, fy - 24, 6, 24, INK)
		for j in 4:
			c.px(284 + i * 8, fy - 21 + j * 5, Color("5cff7a"))
	c.outline(279, fy - 31, 28, 31, INK)
	c.vline(293, fy - 31, 31, INK)
	# decoração
	c.sprite(SCARECROW, PAL, 12, fy - 14)
	_spider(c, 322, fy - 12, 3, Color("5b3a8c"))
	_spider(c, 245, fy - 40, 1, INK, 16)
	_spider(c, 335, fy - 36, 1, INK, 10)


# ---- portas -----------------------------------------------------------------
# Porta aberta: vão escuro (ou iluminado, se "hole" for passado) + folha de madeira aberta
func _draw_open_door(c: PixelCanvas, x: int, y: int, hole: Color = INK) -> void:
	c.rect(x, y, 13, 23, hole)
	c.poly([Vector2i(x + 13, y), Vector2i(x + 19, y + 2), Vector2i(x + 19, y + 23), Vector2i(x + 13, y + 23)], WOOD)
	c.vline(x + 13, y, 23, WOOD_HI)
	c.outline(x, y, 13, 23, WOOD_DK)


func _art_doors(c: PixelCanvas) -> void:
	for d in DOORS:
		var fy := _fy(d["f"])
		var cx := roundi(float(d["x"]) / PX)
		var x := cx - 6
		var y := fy - 23
		if d["open"]:
			_draw_open_door(c, x, y)
		else:
			c.rect(x, y, 13, 23, WOOD)
			c.outline(x, y, 13, 23, WOOD_DK)
			c.rect(x + 3, y + 3, 7, 9, Color("5a8fb0"))
			c.outline(x + 3, y + 3, 7, 9, WOOD_DK)
			c.hline(x + 4, y + 4, 3, Color("a8d0e4"))
			c.rect(x + 3, y + 15, 7, 5, WOOD_HI)
			c.px(x + 10, y + 13, YELLOW)
		var label: String = d["label"]
		if label != "":
			var tw := c.text_width(label) + 4
			var plate_x := cx - tw / 2
			c.rect(plate_x, y - 8, tw, 7, WHITE)
			c.outline(plate_x, y - 8, tw, 7, INK)
			c.text(label, plate_x + 2, y - 7, INK)


# ---- elevador ------------------------------------------------------------------
func _art_elevator(c: PixelCanvas) -> void:
	for fid in FLOORS:
		var fy := _fy(fid)
		var x := A_ELEV - 12
		var y := fy - 31
		if fid == "2":
			c.rect(x, y, 24, 31, INK)
			c.rect(x, y, 3, 31, STEEL)
			c.rect(x + 21, y, 3, 31, STEEL)
			c.disc(A_ELEV, fy - 20, 2, Color("1a1a2e"))
			c.rect(A_ELEV - 3, fy - 17, 6, 17, Color("1a1a2e"))
			c.px(A_ELEV - 1, fy - 21, Color("ff3030"))
			c.px(A_ELEV + 1, fy - 21, Color("ff3030"))
		else:
			c.rect(x, y, 24, 31, STEEL)
			c.rect(x + 2, y + 2, 20, 27, GLASS if fid == "G" else Color("b8c4cc"))
			c.hline(x + 2, y + 2, 20, WHITE)
			c.vline(A_ELEV, y, 31, STEEL_DK)
			if fid == "G":
				c.sprite(SKULL, PAL, A_ELEV - 3, fy - 24)
		c.outline(x, y, 24, 31, INK)
		# placa do andar
		c.rect(A_ELEV - 4, y - 8, 9, 7, INK)
		c.text_center(fid, A_ELEV, y - 7, WHITE)
		# botoeira
		c.rect(x + 28, fy - 23, 3, 7, Color("3d5a3d"))
		c.px(x + 29, fy - 21, Color("ff5050"))


# ---- teias e detalhes finais ----------------------------------------------
func _art_extras(c: PixelCanvas) -> void:
	for fid in FLOORS:
		var top := _ceil_y(fid)
		_web(c, A_LEFT, top, 1, 1, 12)
		_web(c, A_SHAFT_L, top, -1, 1, 9)
		_web(c, A_R_WALL, top, -1, 1, 12)
	_web(c, A_STAIR1, _fy("1") + 6, -1, 1, 14)
	_web(c, A_RIGHT, _fy("1") + 6, 1, 1, 14)
	# abóboras
	for p in PUMPKINS:
		_pumpkin(c, roundi(float(p["x"]) / PX), _fy(p["f"]), p["r"])
	# aranhas pendentes na caixa de escada
	_spider(c, 22, _ceil_y("1") + 22, 1, INK, 18)
	_spider(c, 18, _ceil_y("G") + 30, 1, INK, 24)
	_spider(c, 11, 20, 1, INK, 12)
	if mirror_stair_decor:
		_art_right_stair_decor(c)


# ===========================================================================
# Sprites animados
# ===========================================================================
func _build_animated() -> void:
	var layer := Node2D.new()
	layer.name = "Animated"
	layer.z_index = 5
	add_child(layer)

	for rows in TORCH_FRAMES:
		_torch_tex.append(_tex_rows(rows))
	for rows in BAT_FRAMES:
		_bat_tex.append(_tex_rows(rows))
	var ghost_tex := _tex_rows(GHOST)

	for fid in TORCH_X:
		for x in TORCH_X[fid]:
			var s := _make_sprite(_torch_tex[0], Vector2(float(x) - 14.0, float(FLOORS[fid]) - 120.0), layer)
			_torches.append(s)

	for g in GHOSTS:
		var gy: float = float(FLOORS[g[0]]) - float(g[2]) - 48.0
		var gs := _make_sprite(ghost_tex, Vector2(float(g[1]) - 18.0, gy), layer)
		_ghosts.append(gs)
		_ghost_y.append(gy)

	for b in BAT_SPOTS:
		var pos := Vector2(float(b[1]) - 18.0, float(FLOORS[b[0]]) - float(b[2]) - 20.0)
		var bs := _make_sprite(_bat_tex[0], pos, layer)
		_bats.append(bs)
		_bat_pos.append(pos)


func _build_spawns() -> void:
	var holder := Node2D.new()
	holder.name = "Spawns"
	add_child(holder)
	for key in SPAWNS:
		var m := Marker2D.new()
		m.name = key
		m.position = SPAWNS[key]
		m.add_to_group("spawn")
		holder.add_child(m)


# ===========================================================================
# Iluminação (brilho em degraus, combina com pixel art)
# ===========================================================================
func _build_lighting() -> void:
	if not use_lighting:
		return
	var cm := CanvasModulate.new()
	cm.color = ambient_color
	add_child(cm)
	var tex := _light_texture()

	for fid in TORCH_X:
		for x in TORCH_X[fid]:
			_add_light(tex, Vector2(float(x), float(FLOORS[fid]) - 100.0), 1.4)
	for p in PUMPKINS:
		var r: int = p["r"]
		_add_light(tex, Vector2(float(p["x"]), float(FLOORS[p["f"]]) - r * PX), 2.4 if r > 8 else 0.8)


func _add_light(tex: Texture2D, pos: Vector2, light_scale: float) -> void:
	var l := PointLight2D.new()
	l.texture = tex
	l.position = pos
	l.color = Color(1.0, 0.62, 0.25)
	l.texture_scale = light_scale
	add_child(l)
	_lights.append(l)


func _light_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	return t

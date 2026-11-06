extends Control

signal vector_changed(value: Vector2)

var input_vector := Vector2.ZERO
var knob_position := Vector2.ZERO
var active_touch := -1
var base_radius := 62.0
var knob_radius := 25.0

func _ready() -> void:
	custom_minimum_size = Vector2(150.0, 150.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_update_vector(event.position)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			input_vector = Vector2.ZERO
			knob_position = Vector2.ZERO
			vector_changed.emit(input_vector)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_vector(event.position)

func _update_vector(position: Vector2) -> void:
	var center := size * 0.5
	var offset := position - center
	knob_position = offset.limit_length(base_radius)
	input_vector = Vector2(knob_position.x / base_radius, knob_position.y / base_radius)
	vector_changed.emit(input_vector)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, Color(0.08, 0.09, 0.08, 0.48))
	draw_arc(center, base_radius, 0.0, TAU, 48, Color(0.85, 0.82, 0.72, 0.8), 3.0)
	draw_circle(center + knob_position, knob_radius, Color(0.72, 0.68, 0.55, 0.88))

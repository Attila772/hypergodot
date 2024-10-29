extends Node2D

var edges = []
var dragging = false
var drag_offset = Vector2.ZERO
var offset_circles = []
var node_id = "name"
var circle_usage = {} # Edge instance to circle index
signal node_drag_started(node)
signal node_drag_ended(node)
var NodeMenu = load("res://NodeMenu.tscn")

func _set_node_id(value : String):
	node_id = value
	var label = get_node("Label")
	label.text = node_id

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = get_viewport().get_mouse_position()
				var mouse_pos2 = get_global_mouse_position() # Adjusted line
				if get_rect().has_point(mouse_pos2):
					dragging = true
					drag_offset = mouse_pos - get_position()
					emit_signal("node_drag_started", self)
					modulate = Color(1, 2, 1, 0.7)
			else:
				if dragging:
					emit_signal("node_drag_ended", self)
					modulate = Color(1, 1, 1, 1)
					dragging = false
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var mouse_pos = get_viewport().get_mouse_position()
				var mouse_pos2 = get_global_mouse_position() # Adjusted line
				if get_rect().has_point(mouse_pos2):
					modulate = Color(1, 2, 1, 0.7)
					var NodeMenuInstance = NodeMenu.instantiate()
					NodeMenuInstance.position = position
					NodeMenuInstance.node = self
					get_parent().add_child(NodeMenuInstance)
			else:
				modulate = Color(1, 1, 1, 1)
				pass


func get_rect() -> Rect2:
	var scale_factor = (scale.x + scale.y) / 2
	var size = 50 * scale_factor  # Assuming the original size is 50x50
	var area = Rect2(-size/2, -size/2, size, size)
	area.position += position
	return area

func _process(delta):
	if dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		set_position(mouse_pos - drag_offset)

var centrality_score = 0
func _draw():
	pass
	
func update_size(size_scale: float, new_centrality_score: float):
	scale = Vector2(size_scale, size_scale)
	centrality_score = new_centrality_score
	make_offset_circles()  # Now this will use the updated scale

func make_offset_circles():
	offset_circles.clear()
	var circle_count = edges.size()
	var scale_factor = (scale.x + scale.y) / 2
	var base_radius = 25 * scale_factor
	var radius_increment = 10 * scale_factor
	
	for i in range(circle_count):
		var radius = base_radius + i * radius_increment
		offset_circles.append(radius)
	
	queue_redraw()




func _ready():

	add_to_group("nodes")
	make_offset_circles()

	pass

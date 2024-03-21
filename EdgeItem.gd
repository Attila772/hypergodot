extends Control
var edge = null

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("ColorRect2").color = Color(edge.color)
	get_node("Label").text = name
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var color_rect = get_node("ColorRect2")
			var mouse_pos2 = get_global_mouse_position() # Adjusted line
			if color_rect.get_global_rect().has_point(mouse_pos2):
				var color_picker = ColorPicker.new()
				get_parent().get_parent().add_child(color_picker)
				color_picker.position = position + Vector2(250,0)
				color_picker.connect("color_changed",_on_color_changed)
				
				
func _on_color_changed(new_color):
	# Assuming 'edge' is a valid reference to your edge object
	edge.color = new_color
	edge.queue_redraw()
	# Update the ColorRect2's color
	get_node("ColorRect2").color = new_color

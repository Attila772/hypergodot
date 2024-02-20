extends Camera2D
# Customize these values as needed
var zoom_speed: float = 0.01
var min_zoom: float = 0.5
var max_zoom: float = 2.0
var dragging: bool = false
var drag_last_position: Vector2

func _ready():
	# Initial setup if needed
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				drag_last_position = event.global_position
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var zoom_direction = 0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_direction = 1
			else:
				zoom_direction = -1

			zoom += Vector2(zoom_speed, zoom_speed) * zoom_direction
			# Clamp the zoom value
			zoom.x = clamp(zoom.x, min_zoom, max_zoom)
			zoom.y = clamp(zoom.y, min_zoom, max_zoom)
			zoom += Vector2(zoom_speed, zoom_speed) * zoom_direction
			# Clamp the zoom value to ensure it's within the min and max thresholds
			zoom.x = clamp(zoom.x, min_zoom, max_zoom)
			zoom.y = clamp(zoom.y, min_zoom, max_zoom)
	
	elif event is InputEventMouseMotion and dragging:
		# Calculate the drag movement
		var drag_current_position = event.global_position
		var drag_delta = drag_last_position - drag_current_position
		# Move the camera based on the drag
		position += drag_delta
		drag_last_position = drag_current_position

extends Camera2D
# Customize these values as needed
var zoom_speed: float = 0.01
var min_zoom: float = 0.5
var max_zoom: float = 2.0
var dragging: bool = false
var drag_last_position: Vector2

func _ready():
	var dir = DirAccess.open("user://")
	dir.make_dir("screenshots")
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


func _on_button_button_up() -> void:
	get_parent().get_node("CanvasLayer2").get_node("Button").visible = false
	# Enable high-quality mode
	Global.high_quality = true
	queue_redraw()
	await RenderingServer.frame_post_draw  # Wait for the high-quality redraw

	# Capture the screenshot
	var image = get_viewport().get_texture().get_image()
	
	# Determine the save path
	var config = ConfigFile.new()
	var err = config.load("res://conf.cfg")
	var save_path = "user://screenshots/"  # Default save path
	
	if err == OK:
		var custom_path = config.get_value("graph_settings", "screenshot_path", "")
		if custom_path != "":
			save_path = custom_path  # Use the custom path if defined in the config file
		else:
			print("No valid screenshot_path in conf.cfg. Using default path.")
	else:
		print("Error loading conf.cfg. Using default path.")
	
	# Ensure the directory exists
	if DirAccess.dir_exists_absolute(save_path) == false:
		var create_result = DirAccess.make_dir_recursive_absolute(save_path)
		if create_result != OK:
			print("Failed to create directory:", save_path)
			save_path = "user://screenshots/"
			DirAccess.make_dir_recursive_absolute(save_path)
	
	# Determine the screenshot file name
	var dir = DirAccess.open(save_path)
	var count = 0
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():  # Count only files
				count += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open directory:", save_path)
	
	# Save the screenshot
	var screenshot_file = save_path + "/ss" + str(count) + ".png"
	var save_result = image.save_png(screenshot_file)
	if save_result == OK:
		print("Screenshot saved to:", screenshot_file)
	else:
		print("Failed to save screenshot to:", screenshot_file)
	
	# Revert back to normal mode
	Global.high_quality = false
	get_parent().get_node("CanvasLayer2").get_node("Button").visible = true

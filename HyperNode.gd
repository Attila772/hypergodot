extends Node2D

var edges = []
var dragging = false
var drag_offset = Vector2.ZERO
var offset_circles = []
var node_id = "name"
var circle_usage = {} # Edge instance to circle index
signal node_drag_started(node)
signal node_drag_ended(node)
var drawing_scale = Vector2(1, 1)  # Default scale
var radius_global = 0
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
	centrality_score = new_centrality_score
	
	# Load the config file
	var config = ConfigFile.new()
	var err = config.load("res://conf.cfg")
	if err != OK:
		print("Error loading conf.cfg: ", err)
		return

	# Parse the expression
	var expression_text = config.get_value("graph_settings", "node_radius_expression", "10 + 40 * (centrality / total_nodes)")
	var expression = Expression.new()
	var parse_error = expression.parse(expression_text, ["centrality", "total_nodes"])

	if parse_error != OK:
		print("Error parsing node radius expression: ", parse_error)
		return

	# Execute the expression
	var radius = expression.execute([centrality_score, Global.total_nodes])
	if radius == null:
		print("Error executing node radius expression.")
		return
	radius_global = radius
	# Apply the calculated radius
	scale = Vector2(radius / 25, radius / 25)  # Assuming the base radius is 25
	drawing_scale = scale
	make_offset_circles()

func make_offset_circles():
	offset_circles.clear()

	# Calculate the base radius dynamically based on the node's current drawing scale
	var node_radius = 25 * ((drawing_scale.x + drawing_scale.y) / 2)  # Adjust 25 to match your base radius
	
	var cumulative_radius = node_radius  # Start with the node's outer boundary

	var edge_widths = []
	for edge_id in edges.keys():
		var edge_support = edges[edge_id]
		var edge_width = pow(edge_support, 0.35)  # Function to calculate edge width based on support
		edge_widths.append(edge_width)

	for i in range(edge_widths.size()):
		var edge_width = edge_widths[i]
		# Add half the previous and current edge widths to ensure proper spacing
		if i == 0:
			cumulative_radius += edge_width / 2
		else:
			cumulative_radius += (edge_widths[i - 1] / 2) + (edge_width / 2)

		offset_circles.append(cumulative_radius)  # Store the radius for this edge

	queue_redraw()  # Ensure the node is redrawn with updated circles




func _ready():

	add_to_group("nodes")
	make_offset_circles()

	pass

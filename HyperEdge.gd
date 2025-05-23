extends Node2D

var nodes: Dictionary
var color: Color
var width = 5
var dragging = false
var group = ""
var point_count = 50

func _ready():
	pass

func _process(delta):
	if dragging:
		queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true  # Start dragging
		else:
			dragging = false  # Stop dragging
			queue_redraw()  # Optionally, queue a redraw when you stop dragging
			
func _draw():
	var points = []
	for node_id in nodes:
		var node = get_node_from_group(node_id)
		
		if node:
			var center = node.position
			var radius = nodes[node_id]
			var actual_node_radius = node.radius_global
			radius += actual_node_radius
			radius -=30
			
			var config = ConfigFile.new()
			var err = config.load("res://conf.cfg")
			if err == OK:
				point_count = config.get_value("graph_settings", "point_count", 2.0)
			if Global.high_quality:
				point_count = 300
			points += generate_circle_points(center, radius,point_count)  # Generate circle points
			# Draw each point as a small circle for visibility
			#for point in points:
			#	draw_circle(point, 2, Color(1, 0, 0))  # Red color, radius 2
	
	# Compute the convex hull of the points
	var hull = andrew_monotone_chain(points)
	if hull.size() > 0 and hull[0] != hull[hull.size() - 1]:
		hull.append(hull[0])  # Close the hull
	

	var group_index = Global.get_group_index(group)  # Get the group index from the global dictionary
	
	# Iterate over the hull points and draw lines between them based on the group
	for i in range(hull.size() - 1):
		match group_index:
			1:
				# Draw solid line for group 1 (e.g., 2021)
				draw_line(hull[i], hull[i + 1], color, width)
			2:
				# Draw dashed line for group 2 (e.g., 2022)
				draw_dashed_line(hull[i], hull[i + 1], color, width, 10.0)
			_:
				# Default behavior (solid line for other groups)
				draw_line(hull[i], hull[i + 1], color, width)


func update_position():
	queue_redraw()  # This will trigger a redraw with updated node positions and sizes

func generate_circle_points(center, radius, point_count):
	var points = []
	for i in range(point_count):
		var angle = 2 * PI * i / point_count
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

func orientation(p, q, r):
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	return 0 if val == 0 else (1 if val > 0 else 2)

func get_node_from_group(node_id) -> Node2D:
	var nodes_group = get_tree().get_nodes_in_group("nodes")
	for node in nodes_group:
		if str(node.name) == str(node_id):
			return node
	return null

func find_lowest_point(points):
	var lowest = points[0]
	for point in points:
		if point.y < lowest.y or (point.y == lowest.y and point.x < lowest.x):
			lowest = point
	return lowest


func andrew_monotone_chain(points):
	if points.size() < 3:
		return points
	# Sort points 
	points.sort_custom(func(a, b):
		return a.x < b.x if a.x != b.x else a.y < b.y
	)
	# Lower hull
	var lower = []
	for p in points:
		while lower.size() >= 2 and cross(lower[lower.size() - 2], lower[lower.size() - 1], p) <= 0:
			lower.pop_back()
		lower.append(p)
	# Upper hull
	var upper = []
	for i in range(points.size() - 1, -1, -1):
		var p = points[i]
		while upper.size() >= 2 and cross(upper[upper.size() - 2], upper[upper.size() - 1], p) <= 0:
			upper.pop_back()
		upper.append(p)
	# Concatenate the hulls
	# The first and last points in lower will be the same as the last two points in upper,
	# so we pop them from the result
	lower.pop_back()
	upper.pop_back()
	return lower + upper

func cross(o, a, b):
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
	
	

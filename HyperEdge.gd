extends Node2D

var nodes: Dictionary
var color: Color
var width = 5
var dragging = false
var group = ""
var point_count = 50
var is_dirty = true
var cached_hull = []
var cached_node_positions = {}

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
	# Only recalculate if dirty or nodes have moved
	if is_dirty or has_nodes_moved():
		recalculate_edge()
		is_dirty = false
	
	# Draw the cached hull
	draw_cached_hull()


func update_position():
	queue_redraw()  # This will trigger a redraw with updated node positions and sizes

func mark_dirty():
	is_dirty = true
	queue_redraw()

func has_nodes_moved() -> bool:
	for node_id in nodes:
		var node = get_node_from_group(node_id)
		if node and cached_node_positions.has(node_id):
			if node.position != cached_node_positions[node_id]:
				return true
	return false

func recalculate_edge():
	var points = []
	cached_node_positions.clear()
	
	for node_id in nodes:
		var node = get_node_from_group(node_id)
		if node:
			cached_node_positions[node_id] = node.position
			var center = node.position
			var radius = nodes[node_id]
			var actual_node_radius = node.radius_global
			radius += actual_node_radius
			radius -= 30
			
			var config = ConfigFile.new()
			var err = config.load("res://conf.cfg")
			if err == OK:
				point_count = config.get_value("graph_settings", "point_count", 2.0)
			if Global.high_quality:
				point_count = 300
			points += generate_circle_points(center, radius, point_count)
	
	cached_hull = andrew_monotone_chain(points)
	if cached_hull.size() > 0 and cached_hull[0] != cached_hull[cached_hull.size() - 1]:
		cached_hull.append(cached_hull[0])

func draw_cached_hull():
	var group_index = Global.get_group_index(group)
	for i in range(cached_hull.size() - 1):
		match group_index:
			1:
				draw_line(cached_hull[i], cached_hull[i + 1], color, width)
			2:
				draw_dashed_line(cached_hull[i], cached_hull[i + 1], color, width, 10.0)
			_:
				draw_line(cached_hull[i], cached_hull[i + 1], color, width)

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
	# so we drop them from the result
	lower.pop_back()
	upper.pop_back()
	return lower + upper

func cross(o, a, b):
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
	
	

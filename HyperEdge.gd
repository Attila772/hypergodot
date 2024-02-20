extends Node2D

var nodes: Dictionary
var color: Color
var width =  5
var dragging = false
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
                points += generate_circle_points(center, radius, 20) # 8 points per circle for approximation
                #for point in points:
                #    draw_circle(point, 2, Color(1, 0, 0, 1)) # Draw each point as a small circle
            
                    
        var hull = gift_wrapping(points)
        #for point in hull:
         #       draw_circle(point, 2, Color(1, 0, 0, 1)) # Draw each point as a small circle
        if hull.size() > 0 and hull[0] != hull[hull.size() - 1]:
            hull.append(hull[0])
        for i in range(hull.size() - 1):
            draw_line(hull[i], hull[i + 1], color, width)  # Change '2' to your desired width
        
var p0
    
func generate_circle_points(center, radius, point_count):
    var points = []
    for i in range(point_count):
        var angle = 2 * PI * i / point_count
        points.append(center + Vector2(cos(angle), sin(angle)) * radius)
    return points
    
func orientation(p, q, r):
    var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    return 0 if val == 0 else (1 if val > 0 else 2)

func gift_wrapping(points):
    if points.size() < 3:
        return []
    var hull = []
    var l = 0
    for i in range(1, points.size()):
        if points[i].x < points[l].x:
            l = i
    var p = l
    var q
    while true:
       
        q = (p + 1) % points.size()
        for r in range(points.size()):
            if orientation(points[p], points[q], points[r]) == 2:
                q = r
            elif orientation(points[p], points[q], points[r]) == 0:
                if points[p].distance_to(points[r]) > points[p].distance_to(points[q]):
                    q = r
        hull.append(points[p])
        p = q
        if p == l:
            break
    return hull


func get_node_from_group(node_id) -> Node2D:
        var nodes_group = get_tree().get_nodes_in_group("nodes")
        for node in nodes_group:
            if str(node.name) == str(node_id):
                return node
        return null

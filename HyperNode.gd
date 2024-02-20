extends Node2D

var edges = []
var dragging = false
var drag_offset = Vector2.ZERO
var offset_circles = []
var node_id = "name"
var circle_usage = {} # Edge instance to circle index
signal node_drag_started(node)
signal node_drag_ended(node)

func _set_node_id(value : String):
    node_id = value
    var label = get_node("Label")
    label.text = node_id

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                var mouse_pos = get_viewport().get_mouse_position()
                if get_rect().has_point(mouse_pos):
                    dragging = true
                    drag_offset = mouse_pos - get_position()
                    emit_signal("node_drag_started", self)
                    modulate = Color(1, 2, 1, 0.7)
            else:
                if dragging:
                    emit_signal("node_drag_ended", self)
                    modulate = Color(1, 1, 1, 1)
                    dragging = false


func get_rect() -> Rect2:
    var area = Rect2(-25, -25, 50, 50)
    area.position.x = position.x + area.position.x
    area.position.y = position.y + area.position.y
    return  area

func _process(delta):
    if dragging:
        var mouse_pos = get_viewport().get_mouse_position()
        set_position(mouse_pos - drag_offset)


func _draw():
    #randomize() # Initialize the random number generator
    #for radius in offset_circles:
    #	draw_circle(Vector2(), radius, Color(randf(), randf(), randf(), 0.5)) # Draw semi-transparent circles with random colors
    pass

# This function should use the edges array, and construct as many circles around the node, with a small offset in the radius, that will be used
# to connect the edges to the node, and prevent the edges from overlapping the node and other edges
func make_offset_circles():
    offset_circles.clear() # Reset previous data
    var circle_count = edges.size()
    var base_radius = 25 # Starting radius for the smallest circle

    for i in range(circle_count):
        var radius = base_radius + i * 5 # Increase radius for each subsequent circle
        offset_circles.append(radius) # Store only the radius, as center is the node's position

    queue_redraw() 




func _ready():

    add_to_group("nodes")
    make_offset_circles()

    pass

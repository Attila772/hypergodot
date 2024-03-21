extends Node2D

var node = null
var node_pos = null
var EdgeMenu = load("res://EdgeMenu.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(node.edges)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func get_rect() -> Rect2:
	var area = Rect2(-1, -25, 250, 200)
	area.position.x = position.x + area.position.x
	area.position.y = position.y + area.position.y
	return  area
					

func extract_index_from_name(name: String) -> int:
	var index = name.split(":")[0].to_int()
	return index


func only_self_edges_visible():
	var edges = get_tree().get_nodes_in_group("edges")
	for edge in edges:
		var edge_index = extract_index_from_name(edge.name)
		edge.visible = edge_index in node.edges
	pass # Replace with function body.


func _on_all_edges_pressed():
	var edges = get_tree().get_nodes_in_group("edges")
	for edge in edges:
		edge.visible = true
	pass # Replace with function body.


func _on_edge_color_pressed():
	var EdgeMenuInstance = EdgeMenu.instantiate()
	EdgeMenuInstance.node = node
	EdgeMenuInstance.position = position + Vector2(250,0)
	get_parent().add_child(EdgeMenuInstance)
	pass # Replace with function body.


func _on_button_pressed():
	get_parent().remove_child(self)
	pass # Replace with function body.

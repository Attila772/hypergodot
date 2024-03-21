extends Node2D
var node = null
var EdgeItem = load("res://EdgeItem.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var self_edges  = null
	var edges = get_tree().get_nodes_in_group("edges")
	print(node.edges)
	var offset = 40
	for edge in edges:
		
		var edge_index = extract_index_from_name(edge.name)
		if(edge_index in node.edges and edge.visible):
			
			var EdgeItemInstance = EdgeItem.instantiate()
			EdgeItemInstance.edge = edge
			EdgeItemInstance.position.y += offset
			EdgeItemInstance.name = edge.name
			offset += 30
			get_node("Panel").size.y += 30
			get_node("VBoxContainer").add_child(EdgeItemInstance)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func extract_index_from_name(name: String) -> int:
	var index = name.split(":")[0].to_int()
	return index



	
func get_rect() -> Rect2:
	var area = Rect2(0, 0, 400, 500)
	area.position.x = position.x + area.position.x
	area.position.y = position.y + area.position.y
	
	return  area


func _on_button_pressed():
	get_parent().remove_child(self)
	pass # Replace with function body.

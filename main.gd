extends Node2D


var edges : Dictionary
var nodes : Dictionary
class NodeData:
	var id = 0 # Node identifier
	var edges = [] # Array to hold edge identifiers (based on line number or custom ID)
	var support = 0 # Support value
	
	func _to_string():
		return "Edges: " + str(edges) + ", Support: " + str(support)
		
		
		
func create_nodes(nodes: Dictionary):
	var scene = load("HyperNode.tscn")
	var row = 1
	var column = 1
	var spacing = Vector2(100, 100)
	var per_row = 10
	for id in nodes.keys():
		var node_instance = scene.instantiate()
		node_instance.node_id = id
		node_instance.name = str(id)
		node_instance.position = Vector2(column * spacing.x, row * spacing.y)
		node_instance._set_node_id(str(id))
		node_instance.edges = nodes[id].edges
	
		add_child(node_instance)
		
		column += 1
		if column >= per_row:
			column = 0
			row += 1

func populate_edge_data():
	var hyperedge_scene = load("res://HyperEdge.tscn")
	for node_id in nodes:
		var node_edges = nodes[node_id].edges
		print(nodes)
		var circle_ref = get_node(str(node_id)) # Assuming this gets a node instance with 'offset_circles' available
		var offset_circles = circle_ref.offset_circles # List of radii for offset circles
		for edge_index in range(node_edges.size()):
			var edge_id = node_edges[edge_index]
			if not edges.has(edge_id):
				edges[edge_id] = {"nodes": [], "radii": []}
						
			if edge_index < offset_circles.size(): # Ensure there's a corresponding circle
				var radius = offset_circles[edge_index]
				edges[edge_id]["nodes"].append(node_id)
				edges[edge_id]["radii"].append(radius)
			else:
				print("Error: Node %s has more edges (%s) than offset circles provided." % [node_id, node_edges.size()])
  
	for edge_id in edges:
			var hyperedge_instance = hyperedge_scene.instantiate()
			var edge_data = edges[edge_id]
			var node_radii_pairs = {}
			for i in range(edge_data["nodes"].size()):
				var nodeid = edge_data["nodes"][i]
				var radius = edge_data["radii"][i]
				node_radii_pairs[nodeid] = radius
			hyperedge_instance.nodes = node_radii_pairs
			
			var color = Color(randf(), randf(), randf(), 0.5)  # Generate a random color
			hyperedge_instance.color = color
			add_child(hyperedge_instance)
		   
			
		
		



func _ready():
	nodes = read_file("patterns.txt")
	create_nodes(nodes)
	populate_edge_data()
	pass # Replace with function body.

func read_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var nodes = {} # Dictionary to hold all nodes
	var edge_id = 0 # Unique identifier for each edge, can use line number as well
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.find("#SUP:") == -1:
			continue # Skip this line
		var parts = line.split(" #SUP: ")
		var node_ids = parts[0].split(" ")
		var support = int(parts[1])
		
		# Process each node ID in the line
		for node_id in node_ids:
			var id = node_id
			if not nodes.has(id):
				nodes[id] = NodeData.new()
			# Always append the edge_id to the node's edges array
			nodes[id].edges.append(edge_id)
			# Update the support value
			nodes[id].support = max(nodes[id].support, support)
		
		edge_id += 1 # Increment edge ID for the next line

	file.close()
	return nodes



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

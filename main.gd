extends Node2D


var edges : Dictionary
var nodes : Dictionary
class NodeData:
	var id = 0 # Node identifier
	var edges = {} # Array to hold edge identifiers (based on line number or custom ID)
	

		
		
		
func create_nodes(nodes: Dictionary):
	var scene = load("res://HyperNode.tscn")
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
		
		# Set the edges property for the node
		node_instance.edges = nodes[id].edges
	
		# Add the node instance to the scene
		add_child(node_instance)
		
		# Increment column and row for positioning nodes
		column += 1
		if column >= per_row:
			column = 0
			row += 1


func populate_edge_data(file_data):
	var hyperedge_scene = load("res://HyperEdge.tscn")
	var nodes = file_data["nodes"]  # Retrieve nodes from the file data
	var edges = file_data["edges"]  # Retrieve edges from the file data

	var group_names = []
	for edge_id in edges:
		var group_name = edges[edge_id]["group"]
		if group_name not in group_names:
			group_names.append(group_name)
	Global.initialize_groups(group_names)

	# Step 1: Build a per-node mapping of edge IDs to radii
	var node_edge_radius_map = {}  # Dictionary mapping node_id to {edge_id: radius}
	for node_id in nodes:
		var node_edges = nodes[node_id].edges
		var circle_ref = get_node(str(node_id))  # Get node instance with 'offset_circles'
		var offset_circles = circle_ref.offset_circles  # List of radii for offset circles

		var edge_ids = node_edges.keys()
		var edge_radius_map = {}

		# Ensure there are enough radii for each edge
		if offset_circles.size() < edge_ids.size():
			print("Error: Node %s has more edges (%s) than offset circles provided." % [node_id, edge_ids.size()])
			continue  # Skip this node if radii are insufficient

		# Map each edge_id to its corresponding radius for this node
		for i in range(edge_ids.size()):
			var edge_id = edge_ids[i]
			var radius = offset_circles[i]
			edge_radius_map[edge_id] = radius

		node_edge_radius_map[node_id] = edge_radius_map

	# Step 2: Build edges data using node_edge_radius_map
	for edge_id in edges:
		var edge_nodes = edges[edge_id]["nodes"]  # Nodes connected by this edge
		var edge_radii = []
		var edge_node_ids = []

		for node_id in edge_nodes:
			if node_edge_radius_map.has(node_id):
				var edge_radius_map = node_edge_radius_map[node_id]
				if edge_radius_map.has(edge_id):
					var radius = edge_radius_map[edge_id]
					edge_node_ids.append(node_id)
					edge_radii.append(radius)
				else:
					print("Error: Edge radius not found for node %s and edge %s" % [node_id, edge_id])
			else:
				print("Error: Node %s not found in node_edge_radius_map" % node_id)

		# Update edges[edge_id] with aligned nodes and radii
		edges[edge_id]["nodes"] = edge_node_ids
		edges[edge_id]["radii"] = edge_radii

	# Step 3: Instantiate hyperedges and visualize them
	for edge_id in edges:
		var hyperedge_instance = hyperedge_scene.instantiate()
		var edge_data = edges[edge_id]
		var node_radii_pairs = {}

		# Ensure nodes and radii arrays are aligned
		if edge_data["nodes"].size() != edge_data["radii"].size():
			print("Error: Mismatch between nodes and radii sizes for edge", edge_id)
			continue  # Skip this edge if there's a mismatch

		# Map each node to its radius
		for i in range(edge_data["nodes"].size()):
			var nodeid = edge_data["nodes"][i]
			var radius = edge_data["radii"][i]
			node_radii_pairs[nodeid] = radius

		# Assign the nodes and radii to the hyperedge instance
		hyperedge_instance.nodes = node_radii_pairs

		# Assign a color based on the group
		var color = Color(randf(), randf(), randf(), 0.3)  # Generate a random color
		hyperedge_instance.color = color

		# Set the group name to the hyperedge instance for future use
		hyperedge_instance.group = edge_data["group"]

		hyperedge_instance.add_to_group("edges")
		hyperedge_instance.name = str(edge_id)

		# Set the width of the hyperedge based on the support value
		hyperedge_instance.width = pow(edges[edge_id]["support"], 0.35)

		# Add the hyperedge instance to the scene tree
		add_child(hyperedge_instance)


			

func _ready():
	# Read the file and get both nodes and edges
	var file_data = read_file("patterns.txt")
	# Extract nodes and edges from the file data
	var nodes = file_data["nodes"]
	var edges = file_data["edges"]
	create_nodes(nodes)
	populate_edge_data(file_data)
	apply_force_directed_layout(10, 150.0, 900.0)
	calculate_centrality_and_resize_nodes(file_data)
	#apply_hyperedge_constrained_layout()
	#apply_circular_layout(500)
	pass # Replace with function body.


func read_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var nodes = {} # Dictionary to hold all nodes
	var edges = {} # Dictionary to hold all edges
	var edge_id = 0 # Unique identifier for each edge
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.find("#SUP:") == -1:
			continue # Skip this line if no support value
		
		var parts = line.split(" #SUP: ")
		var node_ids = parts[0].split(" ") # Nodes involved in this edge
		
		# Extract support and group
		var supp_group_info = parts[1].split(" #GROUP ")
		var support = int(supp_group_info[0])
		var group = supp_group_info[1]
		
		# Process each node ID in the line
		for node_id in node_ids:
			if not nodes.has(node_id):
				nodes[node_id] = NodeData.new() # Assuming NodeData is a class for node info
				
			# Add this edge to the node's edge list
			nodes[node_id].edges[edge_id] = support
		
		# Store edge information with group and support in edges dictionary
		edges[edge_id] = {
			"nodes": node_ids,
			"support": support,
			"radii" : [],
			"group": group
		}
		
		edge_id += 1 # Increment edge ID for the next line

	file.close()

	# Return both nodes and edges in a single dictionary
	return {"nodes": nodes, "edges": edges}



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func apply_hyperedge_constrained_layout():
	var node_positions = {} # Dictionary to store node positions temporarily
	var edge_bounds = {} # Dictionary to store edge bounds (min and max positions)
	
	# Initialize node positions
	for node in get_children():
		if node.is_in_group("nodes"): # Assuming your nodes are added to a "nodes" group
			node_positions[node.node_id] = node.position
	
	# Calculate edge bounds based on nodes in the edge
	for edge_id in edges:
		var edge_nodes = edges[edge_id]["nodes"]
		var min_x = INF
		var min_y = INF
		var max_x = -INF
		var max_y = -INF
		
		for node_id in edge_nodes:
			var pos = node_positions[node_id]
			min_x = min(min_x, pos.x)
			min_y = min(min_y, pos.y)
			max_x = max(max_x, pos.x)
			max_y = max(max_y, pos.y)
		
		edge_bounds[edge_id] = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	
	# Reposition nodes to ensure they are outside of edges they don't belong to
	for node_id in node_positions.keys():
		var node_pos = node_positions[node_id]
		for edge_id in edges:
			var edge_nodes = edges[edge_id]["nodes"]
			if node_id not in edge_nodes:
				var bounds = edge_bounds[edge_id]
				if bounds.has_point(node_pos):
					# Move the node outside the edge bounds
					var direction = (node_pos - bounds.position).normalized()
					node_positions[node_id] = bounds.position + bounds.size * direction
	
	# Update actual node positions
	for node in get_children():
		if node.is_in_group("nodes"):
			node.position = node_positions[node.node_id]
	
	
func apply_force_directed_layout(iterations: int, repulsion_force: float, spring_length: float):
	var node_positions = {} # Dictionary to store node positions temporarily
	var forces = {} # Dictionary to store forces applied on nodes
	
	for node in get_children():
		if node.is_in_group("nodes"): # Assuming your nodes are added to a "nodes" group
			node_positions[node.node_id] = node.position
			forces[node.node_id] = Vector2()


	for i in range(iterations):
		# Calculate repulsive forces
		for id_1 in node_positions.keys():
			for id_2 in node_positions.keys():
				if id_1 != id_2:
					var delta = node_positions[id_1] - node_positions[id_2]
					var distance = delta.length()
					if distance > 0: # Avoid division by zero
						var repulsive_force = repulsion_force / distance
						forces[id_1] += delta.normalized() * repulsive_force

		# Calculate spring forces (attractive forces) based on edges
		for edge_id in edges:
			for node_id in edges[edge_id]["nodes"]:
				for other_node_id in edges[edge_id]["nodes"]:
					if node_id != other_node_id:
						var delta = node_positions[node_id] - node_positions[other_node_id]
						var distance = delta.length() - spring_length
						var spring_force = -distance # Assuming a simple linear spring
						forces[node_id] += delta.normalized() * spring_force

		# Apply forces to node positions
		for node_id in node_positions.keys():
			node_positions[node_id] += forces[node_id]/20
			forces[node_id] = Vector2() # Reset forces for the next iteration

	# Update actual node positions
	for node in get_children():
		if node.is_in_group("nodes"):
			node.position = node_positions[node.node_id]
			
			
			
			

func apply_circular_layout(radius: float):
	var center = get_viewport_rect().size / 2
	var nodes = [] # List to store nodes
	for child in get_children():
		if child.is_in_group("nodes"):
			nodes.append(child)
	var node_count = nodes.size()
	var angle_step = 2 * PI / node_count
	for i in range(node_count):
		var node = nodes[i] # Get the node from the filtered list
		var angle = i * angle_step
		var x = center.x + radius * cos(angle)
		var y = center.y + radius * sin(angle)
		node.position = Vector2(x, y)
		
		
func calculate_centrality_and_resize_nodes(file_data):
	var nodes = file_data["nodes"]
	var max_centrality = 0
	var centrality_scores = {}
	
	# Calculate centrality (degree centrality in this case)

	for node_id in nodes:
		var degree = nodes[node_id].edges.size()
		centrality_scores[node_id] = degree
		max_centrality = max(max_centrality, degree)

	# Resize nodes based on centrality
	for node_id in nodes:
		var node_instance = get_node(str(node_id))
		if node_instance:
			var normalized_centrality = float(centrality_scores[node_id]) / max_centrality
			var size_scale = lerp(0.5, 2.0, normalized_centrality)
			node_instance.update_size(size_scale, normalized_centrality)
	
	# Now update all edge positions
	for edge in get_tree().get_nodes_in_group("edges"):
		edge.update_position()
		
		
		

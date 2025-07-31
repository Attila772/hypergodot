extends Node2D


var edges : Dictionary
var nodes : Dictionary
var node_to_edges = {}  # node_id -> [edge_instances]
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
		
		# Connect the position change signal
		node_instance.connect("node_position_changed", _on_node_position_changed)
	
		# Add the node instance to the scene
		add_child(node_instance)
		
		# Increment column and row for positioning nodes
		column += 1
		if column >= per_row:
			column = 0
			row += 1

func _on_node_position_changed(node):
	# Only mark edges that are connected to this node as dirty
	if node_to_edges.has(node.node_id):
		for edge_instance in node_to_edges[node.node_id]:
			if edge_instance and edge_instance.has_method("mark_dirty"):
				edge_instance.mark_dirty()

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
		var color = Color(randf(), randf(), randf(), 0.4)  # Generate a random color
		hyperedge_instance.color = color

		# Set the group name to the hyperedge instance for future use
		hyperedge_instance.group = edge_data["group"]

		hyperedge_instance.add_to_group("edges")
		hyperedge_instance.name = str(edge_id)
		var config = ConfigFile.new()
		var expression = Expression.new()
		var err = config.load("res://conf.cfg")
		var expression_text = config.get_value("graph_settings", "edge_width_expression")
	
		var error = expression.parse(expression_text, ["support", "node_count", "total_nodes"])

		if error != OK:
			$AcceptDialog.window_title = "Error"
			$AcceptDialog.dialog_text = "The expression cannot be parsed: " + error
			$AcceptDialog.get_ok().text = "Close"
			$AcceptDialog.popup_centered()
		# Set the width of the hyperedge based on the support value
		var result = expression.execute([edges[edge_id]["support"], edge_data["nodes"].size(), nodes.size()] )
		if result == null: 
			$AcceptDialog.title = "Error"
			$AcceptDialog.dialog_text = "The expression cannot be parsed:  Error" + str(error)
			$AcceptDialog.ok_button_text = "Close"
			$AcceptDialog.popup_centered()
			return 1.0
		hyperedge_instance.width = result

		# Add the hyperedge instance to the scene tree
		add_child(hyperedge_instance)
		
		# Build node-to-edges mapping
		for node_id in edge_data["nodes"]:
			if not node_to_edges.has(node_id):
				node_to_edges[node_id] = []
			node_to_edges[node_id].append(hyperedge_instance)
	
	Global.edges = edges



func _ready():
	# Read the file and get both nodes and edges
	var file_data = read_file("patterns.txt")
	# Extract nodes and edges from the file data
	var nodes = file_data["nodes"]
	var edges = file_data["edges"]
	create_nodes(nodes)
	populate_edge_data(file_data)

	# Load layout configuration from conf.cfg
	var config = ConfigFile.new()
	var err = config.load("res://conf.cfg")

	if err != OK:
		print("Error loading conf.cfg: ", err)
		return

	var layout = config.get_value("graph_settings", "layout", "")
	var parameters = config.get_value("graph_settings", "parameters", [])

	match layout:
		"force-directed":
			if parameters.size() == 3:
				apply_force_directed_layout(parameters[0], parameters[1], parameters[2])
				print("Applied force-directed layout with parameters: ", parameters)
			else:
				print("Invalid parameters for force-directed layout: ", parameters)
		"circular":
			if parameters.size() == 1:
				apply_circular_layout(parameters[0])
				print("Applied circular layout with parameter: ", parameters[0])
			else:
				print("Invalid parameters for circular layout: ", parameters)
		"radial":
			if parameters.size() == 1:
				apply_radial_layout(parameters[0],file_data)
				print("Applied radial layout with radius step: ", parameters[0])
			else:
				print("Invalid parameters for radial layout: ", parameters)
		_:
			print("Unknown layout type: ", layout)

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
		if line.find("#WEIGHT:") == -1:
			continue # Skip this line if no support value
		
		var parts = line.split(" #WEIGHT: ")
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
	var node_positions = {} # Szótár a csomópontok pozícióinak ideiglenes tárolására
	var forces = {}         # Szótár a csomópontokra ható erők tárolására
	
	var all_nodes = []
	for child in get_children():
		if child.is_in_group("nodes"):
			all_nodes.append(child)

	if all_nodes.is_empty():
		print("Nincsenek csomópontok az elrendezéshez.")
		return

	# Kezdeti pozíciók és erők inicializálása
	for node in all_nodes:
		node_positions[node.node_id] = node.position
		forces[node.node_id] = Vector2.ZERO

	# Iteratív erőszimuláció
	for i in range(iterations):
		# --- 1. Vonzóerők számítása (ÚJ, SÚLYPONT-ALAPÚ LOGIKA) ---
		var edge_centers = {} # Szótár a hiperélek középpontjainak tárolására

		# Először minden hiperél középpontját kiszámoljuk
		for edge_id in edges:
			var edge_data = edges[edge_id]
			var center_pos = Vector2.ZERO
			var node_count_in_edge = edge_data["nodes"].size()
			
			if node_count_in_edge > 0:
				for node_id in edge_data["nodes"]:
					if node_positions.has(node_id):
						center_pos += node_positions[node_id]
				center_pos /= node_count_in_edge
				edge_centers[edge_id] = center_pos

		# Most alkalmazzuk a vonzóerőt a csomópontokra a középpontok felé
		for edge_id in edges:
			var edge_data = edges[edge_id]
			if not edge_centers.has(edge_id):
				continue

			var center = edge_centers[edge_id]
			for node_id in edge_data["nodes"]:
				if forces.has(node_id):
					var delta = center - node_positions[node_id]
					var distance = delta.length()
					
					# A Hooke-törvényhez hasonló rugóerő
					# A spring_length most a csomópont és a hiperél-középpont ideális távolsága
					var displacement = distance - spring_length
					var spring_force_magnitude = displacement * 0.1 # A 0.1 egy "rugóállandó", finomhangolható
					
					if distance > 0:
						forces[node_id] += delta.normalized() * spring_force_magnitude

		# --- 2. Taszítóerők számítása (VÁLTOZATLAN LOGIKA) ---
		for j in range(all_nodes.size()):
			for k in range(j + 1, all_nodes.size()):
				var node1_id = all_nodes[j].node_id
				var node2_id = all_nodes[k].node_id

				var delta = node_positions[node1_id] - node_positions[node2_id]
				var distance = delta.length()
				
				if distance > 0: # Elkerüljük a nullával való osztást
					# Az erő a távolság négyzetével fordítottan arányos a realisztikusabb hatásért
					var repulsive_force_magnitude = repulsion_force / (distance * distance)
					var force_vector = delta.normalized() * repulsive_force_magnitude
					
					forces[node1_id] += force_vector
					forces[node2_id] -= force_vector # Egyenlő és ellentétes erő

		# --- 3. Erők alkalmazása és pozíciók frissítése ---
		var damping = 0.9 # Csillapítás, hogy a rendszer stabilizálódjon és ne "robbanjon szét"
		for node_id in node_positions.keys():
			node_positions[node_id] += forces[node_id] * damping
			forces[node_id] = Vector2.ZERO # Erők nullázása a következő iterációhoz

	# Végleges pozíciók beállítása a szimuláció után
	for node in all_nodes:
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
	Global.total_nodes = nodes.size()  # Store total node count in a global variable

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
			node_instance.update_size(normalized_centrality, normalized_centrality)


func apply_radial_layout(radius_step: float, file_data):
	# A csomópontokat egy egyszerű listában gyűjtjük, a circular_layout mintájára.
	var all_node_instances = []
	for child in get_children():
		if child.is_in_group("nodes"):
			all_node_instances.append(child)

	if all_node_instances.is_empty():
		print("Hiba: Nincsenek csomópontok a radiális elrendezéshez.")
		return

	# A gráf szerkezetének beolvasása a fájlból a megbízhatóság érdekében.

	var nodes_data = file_data["nodes"]
	var edges_data = file_data["edges"]
	print(nodes_data)
	if nodes_data.is_empty() or edges_data.is_empty():
		print("Hiba: A fájlból beolvasott gráf adatok üresek.")
		return

	# --- 1. A legcentrálisabb csomópont megkeresése ---
	var central_node_id = ""
	var max_degree = -1
	for node_id in nodes_data:
		var degree = nodes_data[node_id].edges.size()
		if degree > max_degree:
			max_degree = degree
			central_node_id = node_id

	if central_node_id == "":
		print("Nem található központi csomópont.")
		return

	# --- 2. Szélességi bejárás (BFS) a távolságokhoz ---
	var levels = {} # node_id -> távolság a centrumtól
	var queue = [[central_node_id, 0]]
	var visited = {central_node_id: true}
	levels[central_node_id] = 0

	var adjacency_list = {}
	for edge_data in edges_data.values():
		var edge_node_list = edge_data["nodes"]
		for i in range(edge_node_list.size()):
			var node_id = edge_node_list[i]
			if not adjacency_list.has(node_id):
				adjacency_list[node_id] = []
			for j in range(edge_node_list.size()):
				if i != j:
					var other_node_id = edge_node_list[j]
					if other_node_id not in adjacency_list[node_id]:
						adjacency_list[node_id].append(other_node_id)
	
	var head = 0
	while head < queue.size():
		var current_pair = queue[head]
		head += 1
		var current_id = current_pair[0]
		var current_level = current_pair[1]

		if adjacency_list.has(current_id):
			for neighbor_id in adjacency_list[current_id]:
				if not visited.has(neighbor_id):
					visited[neighbor_id] = true
					levels[neighbor_id] = current_level + 1
					queue.append([neighbor_id, current_level + 1])

	# Csomópont objektumok csoportosítása szintenként
	var nodes_by_level = {}
	for node_instance in all_node_instances:
		var level = levels.get(node_instance.node_id, -1)
		if not nodes_by_level.has(level):
			nodes_by_level[level] = []
		nodes_by_level[level].append(node_instance)

	# --- 3. Pozíciók kiosztása ---
	var center = get_viewport_rect().size / 2
	
	# A központi csomópont középre kerül
	if nodes_by_level.has(0) and not nodes_by_level[0].is_empty():
		nodes_by_level[0][0].position = center

	# A többi csomópont a körökre
	for level in nodes_by_level:
		if level <= 0:
			continue
			
		var nodes_on_this_level = nodes_by_level[level]
		var node_count = nodes_on_this_level.size()
		if node_count == 0:
			continue
			
		var radius = level * radius_step
		var angle_step = (2 * PI) / node_count

		for i in range(node_count):
			var node = nodes_on_this_level[i] # Itt már közvetlenül a node objektumot használjuk
			var angle = i * angle_step
			var x = center.x + radius * cos(angle)
			var y = center.y + radius * sin(angle)
			node.position = Vector2(x, y)

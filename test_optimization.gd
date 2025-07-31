extends Node

# Test script to verify selective edge recalculation optimization
# This script can be attached to a test scene to verify the optimization works

var test_results = []

func _ready():
	print("Starting edge recalculation optimization test...")
	await get_tree().process_frame  # Wait for scene to be fully loaded
	run_optimization_test()

func run_optimization_test():
	print("=== Edge Recalculation Optimization Test ===")
	
	# Get all nodes and edges
	var all_nodes = get_tree().get_nodes_in_group("nodes")
	var all_edges = get_tree().get_nodes_in_group("edges")
	
	if all_nodes.is_empty() or all_edges.is_empty():
		print("ERROR: No nodes or edges found in the scene!")
		return
	
	print("Found %d nodes and %d edges" % [all_nodes.size(), all_edges.size()])
	
	# Test 1: Initial state - all edges should be dirty
	print("\n--- Test 1: Initial State ---")
	var dirty_count = count_dirty_edges(all_edges)
	print("Dirty edges at start: %d/%d" % [dirty_count, all_edges.size()])
	
	# Force a redraw to clear dirty flags
	for edge in all_edges:
		edge.queue_redraw()
	await get_tree().process_frame
	
	# Test 2: After initial draw - no edges should be dirty
	print("\n--- Test 2: After Initial Draw ---")
	dirty_count = count_dirty_edges(all_edges)
	print("Dirty edges after initial draw: %d/%d" % [dirty_count, all_edges.size()])
	
	# Test 3: Move one node and check which edges become dirty
	if all_nodes.size() > 0:
		print("\n--- Test 3: Moving Single Node ---")
		var test_node = all_nodes[0]
		var original_position = test_node.position
		
		print("Moving node: %s from %s" % [test_node.node_id, original_position])
		
		# Move the node
		test_node.position += Vector2(50, 50)
		test_node.emit_signal("node_position_changed", test_node)
		
		await get_tree().process_frame
		
		# Count dirty edges
		dirty_count = count_dirty_edges(all_edges)
		print("Dirty edges after moving node %s: %d/%d" % [test_node.node_id, dirty_count, all_edges.size()])
		
		# Check which specific edges are dirty
		var dirty_edges = get_dirty_edges(all_edges)
		print("Dirty edge IDs: %s" % [dirty_edges])
		
		# Verify that only edges connected to the moved node are dirty
		var expected_dirty_edges = get_edges_connected_to_node(test_node.node_id)
		print("Expected dirty edges for node %s: %s" % [test_node.node_id, expected_dirty_edges])
		
		# Restore original position
		test_node.position = original_position
		test_node.emit_signal("node_position_changed", test_node)
	
	print("\n=== Test Complete ===")
	print("Optimization appears to be working if:")
	print("1. Initial dirty count equals total edges")
	print("2. After draw, dirty count is 0")
	print("3. After moving one node, only connected edges are dirty")

func count_dirty_edges(edges: Array) -> int:
	var count = 0
	for edge in edges:
		if edge.has_method("is_dirty") and edge.is_dirty:
			count += 1
		elif edge.has_property("is_dirty") and edge.is_dirty:
			count += 1
	return count

func get_dirty_edges(edges: Array) -> Array:
	var dirty_edges = []
	for edge in edges:
		if edge.has_method("is_dirty") and edge.is_dirty:
			dirty_edges.append(edge.name)
		elif edge.has_property("is_dirty") and edge.is_dirty:
			dirty_edges.append(edge.name)
	return dirty_edges

func get_edges_connected_to_node(node_id: String) -> Array:
	var connected_edges = []
	var main_node = get_node("/root/Main")  # Adjust path as needed
	
	if main_node and main_node.has_method("get") and main_node.node_to_edges.has(node_id):
		for edge in main_node.node_to_edges[node_id]:
			connected_edges.append(edge.name)
	
	return connected_edges
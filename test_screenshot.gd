extends Node

# Test script to verify screenshot functionality
func _ready():
	print("=== Screenshot Functionality Test ===")
	
	# Wait a moment for the scene to load
	await get_tree().create_timer(1.0).timeout
	
	# Test 1: Check if Global.high_quality starts as false
	print("Test 1 - Initial high_quality state: ", Global.high_quality)
	assert(Global.high_quality == false, "Global.high_quality should start as false")
	
	# Test 2: Check if edges exist and have the mark_dirty method
	var edges = get_tree().get_nodes_in_group("edges")
	print("Test 2 - Number of edges found: ", edges.size())
	
	if edges.size() > 0:
		var first_edge = edges[0]
		print("Test 2 - First edge has mark_dirty method: ", first_edge.has_method("mark_dirty"))
		
		# Test 3: Check initial point_count
		if first_edge.has_method("get") and "point_count" in first_edge:
			print("Test 3 - Initial point_count: ", first_edge.point_count)
		
		# Test 4: Simulate high quality mode
		print("Test 4 - Simulating high quality mode...")
		Global.high_quality = true
		first_edge.mark_dirty()
		
		# Wait for redraw
		await get_tree().process_frame
		await get_tree().process_frame
		
		print("Test 4 - Point count after high quality: ", first_edge.point_count)
		
		# Test 5: Revert to normal mode
		print("Test 5 - Reverting to normal mode...")
		Global.high_quality = false
		first_edge.mark_dirty()
		
		await get_tree().process_frame
		await get_tree().process_frame
		
		print("Test 5 - Point count after revert: ", first_edge.point_count)
	
	print("=== Test Complete ===")
	
	# Clean up - remove this test node
	queue_free()
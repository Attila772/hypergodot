extends Node

var group_dictionary = {}
var group_count = 0
var high_quality = false
var total_nodes = 0
var edges = null

# Function to initialize the groups from a list of group names
func initialize_groups(group_names: Array):
	group_dictionary.clear()
	group_count = 0
	
	# Add each group name with an index (1-based)
	for group_name in group_names:
		group_count += 1
		group_dictionary[group_name] = group_count

# Function to get the index of a group name
func get_group_index(group_name: String) -> int:
	if group_name in group_dictionary:
		return group_dictionary[group_name]
	return -1 # Return -1 if the group is not found

# Function to get group name by index (if needed later)
func get_group_name(group_index: int) -> String:
	for name in group_dictionary:
		if group_dictionary[name] == group_index:
			return name
	return ""

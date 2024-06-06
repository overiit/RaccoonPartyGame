extends Node

var lastVehileId = 1000000000

func findNodeOfType(parent: Node, type):
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
		var grandchild = findNodeOfType(child, type)
		if grandchild != null:
			return grandchild
	return null

func findNodeOfTypeInNextLayer(parent: Node, type):
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
	return null

extends Node

var _lastEntityId = 1000000000

func genEntityId():
	_lastEntityId += 1
	return _lastEntityId

func findNodeOfType(parent: Node, type):
	if is_instance_of(parent, type):
		return parent
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

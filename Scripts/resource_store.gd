# ResourceStore.gd
class_name ResourceStore
extends RefCounted

# Resources dictionary can look like this:
#"resources": {
  #"visible": { "Story points": 3.0 },
  #"hidden": { "reincarnation_ready": 1.0 },
  #"permanent": { "Ascension Tokens": 1 }
#}
# Resource caps may look like this:
#"resource_caps": {
  #"visible": { "Story points": 100.0 },
  #"hidden": { "reincarnation_ready": 10.0 },
  #"permanent": { "Ascension Tokens": 10.0 }
#}
var resources: Dictionary = {} # Keep track of each resource amount by using name and value
var caps: Dictionary = {} # Base capacity per resource

# When this initializes
func _init(caps_data: Dictionary = {}) -> void:
	caps = caps_data

func add(group: String, key: String, amount: float) -> bool:
	if amount <= 0:
		return false

	# Initialize group if missing
	if not resources.has(group):
		resources[group] = {}

	var current = resources[group].get(key, 0.0)
	var max_cap = caps.get(group, {}).get(key, 0.0)

	if max_cap > 0.0 and current >= max_cap:
		return false

	var new_value = current + amount
	resources[group][key] = min(new_value, max_cap) if max_cap > 0.0 else new_value

	SignalBroker.resources_updated.emit(self)
	return true

func remove(group: String, key: String, amount: float) -> void:
	if resources.has(group) and resources[group].has(key):
		resources[group][key] = max(resources[group][key] - amount, 0.0)
		prune_zeros()
		SignalBroker.resources_updated.emit(self)

func set_value(group: String, key: String, amount: float) -> void:
	if not resources.has(group):
		resources[group] = {}
	resources[group][key] = max(amount, 0.0)
	prune_zeros()
	SignalBroker.resources_updated.emit(self)

func get_value(group: String, key: String) -> float:
	if resources.has(group):
		return resources[group].get(key, 0.0)
	return 0.0

# Returns true if the resources contain enough of each to fulfill the requirements
func has_all(requirements: Dictionary) -> bool:
	for group in requirements.keys():
		for key in requirements[group].keys():
			if get_value(group, key) < requirements[group][key]:
				return false
	return true

# Subtracts all the requirments from the resources and returns true on success
func consume(requirements: Dictionary) -> bool:
	if not has_all(requirements):
		return false

	for group in requirements.keys():
		for key in requirements[group].keys():
			resources[group][key] = max(
				resources[group].get(key, 0.0) - requirements[group][key],
				0.0
			)
	prune_zeros()
	SignalBroker.resources_updated.emit(self)
	return true

# Check if all resources in the provided dictionary are at capacity
func are_all_at_capacity(requirements: Dictionary) -> bool:
	for group in requirements.keys():
		for key in requirements[group].keys():
			if not is_at_capacity(group, key):
				return false
	return true

# Returns true if the resource specified by key is at capacity
func is_at_capacity(group: String, key: String) -> bool:
	if not caps.has(group):
		return false
	var max_cap = caps[group].get(key, 0.0)
	if max_cap <= 0.0:
		return false
	return get_value(group, key) >= max_cap

# Removes keys from the dictionary if the value is 0.0
func prune_zeros() -> void:
	for group in resources.keys():
		var to_remove: Array = []
		for key in resources[group].keys():
			if resources[group][key] == 0.0:
				to_remove.append(key)
		for key in to_remove:
			resources[group].erase(key)

# Resets all resource values to 0, except the "permanent" group
func reset() -> void:
	for group in resources.keys():
		if group == "permanent":
			continue  # Skip resetting permanent group

		for key in resources[group].keys():
			resources[group][key] = 0.0

	prune_zeros()
	SignalBroker.resources_updated.emit(self)

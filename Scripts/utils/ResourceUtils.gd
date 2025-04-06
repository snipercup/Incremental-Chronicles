# ResourceUtils.gd
extends Node
class_name ResourceUtils


# ------------------------------------------------------------------------------
# Utility Function Documentation: filter_requirements_by_type
# ------------------------------------------------------------------------------

# Returns a new requirements dictionary filtered by the specified type.
# 
# Example:
#   filter_requirements_by_type(requirements, "appear")
#   → Will return only keys that contain an "appear" rule
#
# Requirements Format Example:
#   "requirements": {
#     "visible": {
#       "Story points": { "consume": 50.0 },
#       "Resolve": { "appear": { "min": 1.0 } }
#     },
#     "hidden": {
#       "village_access": { "appear": { "min": 1.0 } },
#       "courage": { "consume": 10.0 }
#     }
#   }
#
# Behavior:
# - The result will include only rules matching the specified type (e.g. "consume" or "appear")
# - It will exclude any other types present in the original rules
# - It duplicates the group structure ("visible", "hidden", etc.) as needed

# -------------------------
# Example 1 — Filter "appear"
# -------------------------
# Input:
# {
#   "visible": {
#     "Story points": { "consume": 50.0 },
#     "Resolve": { "appear": { "min": 1.0 } }
#   },
#   "hidden": {
#     "village_access": { "appear": { "min": 1.0 } },
#     "courage": { "consume": 10.0 }
#   }
# }

# Result:
# {
#   "visible": {
#     "Resolve": { "appear": { "min": 1.0 } }
#   },
#   "hidden": {
#     "village_access": { "appear": { "min": 1.0 } }
#   }
# }

# -------------------------
# Example 2 — Filter "consume"
# -------------------------
# Input:
# {
#   "visible": {
#     "Story points": { "consume": 50.0 },
#     "Resolve": { "appear": { "min": 1.0 } }
#   },
#   "hidden": {
#     "village_access": { "appear": { "min": 1.0 } },
#     "courage": { "consume": 10.0 }
#   }
# }

# Result:
# {
#   "visible": {
#     "Story points": { "consume": 50.0 }
#   },
#   "hidden": {
#     "courage": { "consume": 10.0 }
#   }
# }
# ------------------------------------------------------------------------------
static func filter_requirements_by_type(requirements: Dictionary, requirement_type: String) -> Dictionary:
	var result: Dictionary = {}

	for group in requirements.keys(): # Example: "visible"
		for key in requirements[group].keys(): # Example: "Story points"
			var rule = requirements[group][key] # Example: {"consume": 50.0}

			if typeof(rule) == TYPE_DICTIONARY and rule.has(requirement_type): # Example: "consume"
				if not result.has(group): # Example: "visible"
					result[group] = {}
				# Example: result["visible"]["Story points"] = { "consume": 50 }
				# Example: result["hidden"]["village_access"] = { "appear": {"min": 1.0} }
				# Result will include only rules matching the specified type (e.g. "consume" or "appear"), 
				# and will exclude any other types present in the original rules.
				result[group][key] = { requirement_type: rule[requirement_type] }
	return result

# ✅ Returns a formatted label string for a requirement with optional current/max values
static func format_requirement_label(
	resource_name: String,
	needed: float,
	current: float = -1,
	max_value: float = -1,
	group: String = "visible",
	type: String = "consume"
) -> String:
	var icon := ""
	match group:
		"visible": icon = "⏳"
		"permanent": icon = "♾️"
		"hidden": icon = "🫥"
		_: icon = ""

	var prefix := ""
	if type == "appear":
		if max_value > 0 and max_value < INF:
			return "[%s %d–%d] %s (%d)" % [icon, int(needed), int(max_value), resource_name, int(current)]
		else:
			return "[%s %d+] %s (%d)" % [icon, int(needed), resource_name, int(current)]

	if max_value > 0:
		return "[%s %d] %s (%d/%d)" % [icon, int(needed), resource_name, int(current), int(max_value)]
	elif current >= 0:
		return "[%s %d] %s (%d)" % [icon, int(needed), resource_name, int(current)]
	else:
		return "[%s %d] %s" % [icon, int(needed), resource_name]

# ✅ Returns a formatted label string for a reward
static func format_reward_label(resource_name: String, amount: float, group: String = "visible") -> String:
	var icon := ""
	match group:
		"visible": icon = "⏳"
		"permanent": icon = "♾️"
		"hidden": icon = "🫥"
		"regeneration": icon = "⏫"
		"capacity": icon = "📈"
		_: ""

	return "%s %s: %d" % [icon, resource_name, int(amount)]

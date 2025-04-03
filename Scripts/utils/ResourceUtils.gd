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

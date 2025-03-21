class_name StoryAction
extends RefCounted

# Properties with default values
var stars: int = 1 : set = set_stars, get = get_stars
var story_point_requirement: int = 0 : set = set_story_point_requirement, get = get_story_point_requirement
var story_points: int = 1 : set = set_story_points, get = get_story_points
var story_text: String = "" : set = set_story_text, get = get_story_text
var system_prompt: String = "you are a story writing assistant" : set = set_system_prompt, get = get_system_prompt
var say: String = "return exactly one action" : set = set_say, get = get_say
var area: StoryArea

# Setters and Getters
func set_stars(value: int) -> void:
	stars = clamp(value, 1, 5)  # Ensure stars are between 1 and 5

func get_stars() -> int:
	return stars

func set_story_point_requirement(value: int) -> void:
	story_point_requirement = max(value, 0)  # Ensure non-negative

func get_story_point_requirement() -> int:
	return story_point_requirement

func set_story_points(value: int) -> void:
	story_points = max(value, 0)  # Ensure non-negative

func get_story_points() -> int:
	return story_points

func set_story_text(value: String) -> void:
	story_text = value

func get_story_text() -> String:
	return story_text

func set_system_prompt(value: String) -> void:
	system_prompt = value

func get_system_prompt() -> String:
	# Get the area description from the associated area
	var area_description: String = area.get_description() if area else "an unknown place"
	print_debug("returning area description: " + area_description)
	# Replace the placeholder with the actual area description
	return "You are an action generator. Your job is to create short actions (up to 5 words). " +\
		   "Each action should be short and engaging that reflects the possibilities in the area. " +\
		   "Describe an activity in the following setting: %s. " % area_description +\
		   "The action should feel natural, varied, and influenced by the location, its landmarks, and its inhabitants."


func set_say(value: String) -> void:
	say = value

func get_say() -> String:
	return say

# Function to return all properties as a dictionary
func get_properties() -> Dictionary:
	return {
		"stars": stars,
		"story_point_requirement": story_point_requirement,
		"story_points": story_points,
		"story_text": story_text,
		"system_prompt": system_prompt,
		"say": say
	}

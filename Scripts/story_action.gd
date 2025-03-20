class_name StoryAction
extends RefCounted

# Properties with default values
var stars: int = 1 : set = set_stars, get = get_stars
var story_point_requirement: int = 0 : set = set_story_point_requirement, get = get_story_point_requirement
var story_points: int = 1 : set = set_story_points, get = get_story_points
var story_text: String = "" : set = set_story_text, get = get_story_text

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

# Function to return all properties as a dictionary
func get_properties() -> Dictionary:
	return {
		"stars": stars,
		"story_point_requirement": story_point_requirement,
		"story_points": story_points,
		"story_text": story_text
	}

extends Node

# When the active action in the action list ui is updated
@warning_ignore("unused_signal")
signal active_action_updated(myaction: StoryAction)

# When an action has been activated in the action list (button was pressed)
@warning_ignore("unused_signal")
signal action_activated(myaction: StoryAction)

# When an action has been done and a reward is granted
@warning_ignore("unused_signal")
signal action_rewarded(myaction: StoryAction)

# When an action has changed state
@warning_ignore("unused_signal")
signal action_state_changed(myaction: StoryAction)

# When an action will be removed
@warning_ignore("unused_signal")
signal action_removed(myaction: Control)

# When an area will be removed
@warning_ignore("unused_signal")
signal area_removed(myarea: StoryArea)

# Signal to emit when visibility changes
@warning_ignore("unused_signal")
signal area_visibility_changed(area: StoryArea)

# Signal to emit when hidden resources are updated
@warning_ignore("unused_signal")
signal hidden_resources_updated(resource_manager: Label)
# Signal to emit when resources are updated
@warning_ignore("unused_signal")
signal resources_updated(resource_manager: Label)

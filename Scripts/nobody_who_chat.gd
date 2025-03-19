extends NobodyWhoChat

func _ready():
	start_worker()


func _on_button_button_up() -> void:
	# say something
	say("Hi there! Who are you?")

	# wait for the response
	var response = await response_finished
	print("Got response: " + response)

	# in this example we just use the `response_finished` signal to get the complete response
	# in real-world-use you definitely want to connect `response_updated`, which gives one word at a time
	# the whole interaction feels *much* smoother if you stream the response out word-by-word.

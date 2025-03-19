extends NobodyWhoChat

signal action_generated(action: String)

func _ready():
	start_worker()


func generate_action() -> void:
	start_worker()
	var mysampler: NobodyWhoSampler = sampler
	mysampler.seed = randi()  # Set seed to a random integer
	# say something
	say("What can I do in this village?")

	# wait for the response
	var response = await response_finished
	print("Got response: " + response)
	action_generated.emit(response)

	# in this example we just use the `response_finished` signal to get the complete response
	# in real-world-use you definitely want to connect `response_updated`, which gives one word at a time
	# the whole interaction feels *much* smoother if you stream the response out word-by-word.

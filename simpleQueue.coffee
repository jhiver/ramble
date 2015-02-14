# Simple Throttling library.
# Takes an async-style function, returns a Promise object.

Promise = require 'promise' # This is to make up for Javascript poor syntax :-)
Queue = []                  # This is our "TODO LIST"
Heartbeat = 100             # This is our interval, set to 100ms not to exceed 600 requests per minute
Started = false             # Is our interval started?
Interval = null             # Interval object, need to keep it somewhere to be able to clear


# stop()
# ------
# Stops watching / running the queue.
stop = ->
	clearInterval Interval if Interval
	started = false


# stop()
# ------
# Starts running / watching the queue.
start = ->
	return if Started
	Interval = setInterval ->
		return unless Queue.length
		args = Queue.shift()
		reject = args.pop()
		resolve = args.pop()
		action = args.shift()
		if args and args.length
			action args..., (err, res) ->
				if err then return reject err
				return resolve res
		else
			action (err, res) ->
				if err then return reject err
				return resolve res
	, Heartbeat
	Started = true


# queue = (action, arguments....)
# -------------------------------
# action is expected to be an Asynchronous method that takes some optional
# arguments, and a classical (err, res) callback at the end.
# queue returns a promise object to wrap around the action function.
append = (action, args...) ->
	return new Promise (resolve, reject) ->
		Queue.push [action, args..., resolve, reject]


# make ourselves visible to the world.
module.exports.append = append
module.exports.stop   = stop
module.exports.start  = start
module.exports.setHeartbeat = (num) ->
	stop()
	Heartbeat = num
	start()


# let's run this simple test if we're not being used as a module
if not module.parent
	TOTAL_DONE = 0

	# let's start the queue.
	module.exports.setHeartbeat 50

	# this function prints whatever is passed as arguments and
	# calls back with an uppercase string as result after a short
	# random time.
	delayedConsoleLog = (args..., callback) ->
		setTimeout ->
			console.log args...
			callback null, args.join(" ").toUpperCase()
		, 1000*Math.random()

	# let's queue 100 
	for i in [1..100]
		p = queue delayedConsoleLog, "foo", i
		p.then (res) ->
			console.error result: res
			TOTAL_DONE++
			process.exit(0) if TOTAL_DONE is 100


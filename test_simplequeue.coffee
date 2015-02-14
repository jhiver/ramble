# import module
queue = require './simpleQueue.coffee'

# 50ms interval, i.e. 20 ops/sec
queue.setHeartbeat 50 

doSomething = (args..., callback) ->
	setTimeout ->
		console.log args...
		callback null, args.join(" ").toUpperCase()
	, 1000*Math.random()

for i in [1..1000]
  queue
    .append doSomething, "an argument", i
    .then (result) -> console.log result: result
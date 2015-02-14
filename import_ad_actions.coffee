readline = require 'linebyline'
restler  = require 'restler'
queue    = require '../shared/simpleQueue.coffee'
queue.setHeartbeat 10
queue.start()


esInsert = (doc, callback) ->
	url = 'http://localhost:9200/' + doc.date + '/ad_actions/'
	r = restler.postJson url, doc
	r.on 'complete', (result, response) ->
		if String(response.statusCode).match /^2/
			return callback null, result._id
		else
			return callback "something odd happened..."
			console.error response.statusCode
			console.error response.headers
			console.error result


rl = readline 'ad_actions.tsv'
rl.on 'line', (line) ->
	array     = line.split /\s+/
	advert_id = Number array.shift()
	date      = String array.shift()
	action    = String array.shift()
	value     = Number array.shift()
	cost      = Number array.shift()
	doc = advert_id: advert_id, date: date, action: action, value: value, cost: cost
	url = 'http://localhost:9200/ads_' + date + '/ad_actions'

	p = queue.append esInsert, doc
	p.then (id) ->
		console.log "inserted " + id
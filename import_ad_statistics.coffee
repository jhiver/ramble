readline = require 'linebyline'
restler  = require 'restler'
queue    = require '../shared/simpleQueue.coffee'
queue.setHeartbeat 10
queue.start()


esInsert = (doc, callback) ->
	url = 'http://localhost:9200/' + doc.date + '/ad_statistics/'
	r = restler.postJson url, doc
	r.on 'complete', (result, response) ->
		if String(response.statusCode).match /^2/
			return callback null, result._id
		else
			return callback "something odd happened..."
			console.error response.statusCode
			console.error response.headers
			console.error result


rl = readline 'ad_statistics.tsv'
rl.on 'line', (line) ->
	array     = line.split /\s+/
	advert_id = Number array.shift()
	date      = String array.shift()
	prints    = Number array.shift()
	clicks    = Number array.shift()
	cost      = Number array.shift()
	doc = advert_id: advert_id, date: date, prints: prints, clicks: clicks, cost: cost
	url = 'http://localhost:9200/ads_' + date + '/ad_statistics'

	p = queue.append esInsert, doc
	p.then (id) ->
		console.log "inserted " + id
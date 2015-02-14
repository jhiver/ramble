readline = require 'linebyline'
restler  = require 'restler'
queue    = require '../shared/simpleQueue.coffee'
queue.setHeartbeat 10
queue.start()


DOCS_TO_IMPORT = 0


esInsert = (doc, callback) ->
	DOCS_TO_IMPORT++
	url = 'http://localhost:9200/' + doc.date + '/adverts/'

	r = restler.postJson url, doc

	r.on 'complete', (result, response) ->
		setTimeout ->
			DOCS_TO_IMPORT--
		, 2000
		if String(response.statusCode).match /^2/
			return callback null, result._id
		else
			return callback "something odd happened..."
			console.error response.statusCode
			console.error response.headers
			console.error result


import_actions = (done) ->
	rl = readline 'ad_actions.tsv'
	rl.on 'end', done
	rl.on 'line', (line) ->
		array     = line.split /\s+/
		advert_id = Number array.shift()
		date      = String array.shift()
		action    = String array.shift()
		value     = Number array.shift()
		cost      = Number array.shift()
		doc = advert_id: advert_id, date: date, action: action, value: value, cost: cost
		url = 'http://localhost:9200/ads_' + date + '/ad_actions'

		queue
			.append esInsert, doc
			.then (id) -> console.log "inserted " + id


import_statistics = (done) ->
	rl = readline 'ad_statistics.tsv'
	rl.on 'end', done
	rl.on 'line', (line) ->
		array     = line.split /\s+/
		advert_id = Number array.shift()
		date      = String array.shift()
		prints    = Number array.shift()
		clicks    = Number array.shift()
		cost      = Number array.shift()

		queue
			.append esInsert, { advert_id: advert_id, date: date, action: 'impressions', value: prints, cost: cost }
			.then (id) -> console.log "inserted " + id

		queue
			.append esInsert, { advert_id: advert_id, date: date, action: 'clicks', value: clicks, cost: cost }
			.then (id) -> console.log "inserted " + id



import_actions ->
	import_statistics ->
		setInterval ->
			if DOCS_TO_IMPORT
				console.log DOCS_TO_IMPORT, " documents to go"
			else
				console.log 'ALL IMPORTED'
				process.exit (0)
		, 1000
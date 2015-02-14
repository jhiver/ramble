Let's do stuff
===========

Queuing
----------

simpleQueue.coffee contains a generic throttling implementation that makes use of the promise library.

Current implementation is rather naive, i.e. if you want to limit your sending rate to 600 operations per minute, you set the "heartbeat" parameter to 100ms.

A better implementation would be to enable burstable limits, i.e. for instance be able to say "don't exceed 600 requests / minute and no more than 100 / 10 seconds".

But in the absence of further specification, I believe the best approach is the most naive one. Let's not optimize prematurely.

How to use - from coffeescript: see simpleQueue.coffee

	# import module
	queue = require './simpleQueue.coffee'

	# 50ms interval, i.e. 20 ops/sec
	queue.setHeartbeat 50 

	# queue stuff with:
	# queue.append function, arg1, arg2, ...
	# function should take a callback(err,res) style
	# call back as its last argument.
	for i in [1..1000]
	  queue
	    .append doSomething, i
	    .then (result) -> console.log result: result


Thinking outside the box
------------------------------

In this case, we have the following tables:

	Table: ad_statistics
	Field	Type	Example value
	ad_id	INT	1
	date	DATE	2013-09-01
	impressions	BIGINT	4123915
	clicks	BIGINT	25190
	spent	BIGINT	8291

	Table: ad_actions
	Field	Type	Example value
	ad_id	INT	1
	date	DATE	2013-09-01
	action	VARCHAR	mobile_app_install
	count	BIGINT	50
	value	BIGINT	3900

But ad_statistics can be expressed as actions. "impressions" can be considered an action. And "clicks" can be considered an action. So we'll unify everything with the following schema:

	Table: advert
	ad_id	INT
	date	DATE
	action	VARCHAR
	value	BIGINT
	cost	BIGINT

Which means the following example:

	1	2013-09-30	804668	12553	1497

Can be expressed as two actions:

	ad_id: 1
	date: 2013-09-30
	action: "views"
	value: 804668
	cost: 1497

and

	ad_id: 1
	date: 2013-09-30
	action: "clicks"
	value: 12553
	cost: 1497

If we wanted pure read speed on SQL, we would make a giant read table, with the following columns (ad_id, date, cost), PLUS we would add one column per "action", i.e. one column for view, one column for clicks, one column for video views, one for likes, etc. etc. Doing so would enable us to get rid of JOIN operations and allow for fast table scans and grouping operations, at the expense of data normalization.

That's the usual "let's denormalize from our 3NF to get extra speed". Unfortunately, this leads to data duplication and possible inconsistencies, not even mentioning the ALTER table hell when new attributes appear.

I'd rather keep the database as a properly normalized "center of truth", and use another more appropriate tool for big data / analytics. Here I chose Elasticsearch, which is well known for its speed and data aggregation / analytics capabilities.

There is a (slow) import script that will import everything into ES (could be heavily optimized using the bulk API...). We could store one index per day or even one index per ad, this all depends on how you want / need data to be stored on your cluster nodes. Here i've chosen one index per day.

Statistics are performed using nested aggregations. Basically we first group by ad_id, then by add_action, then use the statistics aggregator of the value and cost document fields which gives me all the information i need in a single query without having to hit MySQL.

Some extra filtering arguments can be applied. See ad_actions.esq for a sample ElasticSearch query.
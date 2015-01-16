

Meteor.publishArray = (options) ->
	{name, collection, data, refreshTime, refreshHandle} = options
	subscriptions = {}
	
	if refreshHandle?
		refreshHandle.refresh = ->
			console.log "manually referesh #{name}"
			for id, subscription of subscriptions
				subscription.refresh()

	Meteor.publish name, (params) ->
		pub = @
		ids = {}
		refreshTimeoutHandle = null
		hasStopped = false

		refresh = ->
			console.log "refreshing #{name}"

			currentIds = {}
			try

				results = data.call pub, params

			catch error
				console.log error
				results = []


			if results?
				for result in results
					id = result._id
					currentIds[id] = true # mimic set
					unless ids[id]?
						ids[id] = true # mimic set
						pub.added collection, id, result
					else
						pub.changed collection, id, result
				for id of ids
					unless currentIds[id]?

						pub.removed collection, id
						delete ids[id]
			pub.ready()

		autoRefresh = ->
			refresh()
			if refreshTime? and not hasStopped
				refreshTimeoutHandle = Meteor.setTimeout autoRefresh, refreshTime

		Meteor.defer autoRefresh

		# attach a handle
		subscriptions[pub._subscriptionId] = 
			refresh: refresh

		@onStop =>
			console.log "stopping #{name}"
			hasStopped = yes
			if refreshTimeoutHandle?
				Meteor.clearTimeout refreshTimeoutHandle
			delete subscriptions[pub._subscriptionId]


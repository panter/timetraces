

Meteor.publishRestApi = (options) ->
	{name, collection, apiCall, refreshTime} = options

	Meteor.publish name, (params) ->
		pub = @
		ids = {}
		refresh = ->
			console.log "refreshing #{name}"
			currentIds = {}
			results = apiCall.call pub, params
			
			if results? && results.length > 0
				for result in results
					id = result._id
					currentIds[id] = true # mimic set
					unless ids[id]?
						ids[id] = true # mimic set
					pub.added collection, id, result
				for id of ids
					unless currentIds[id]?
						pub.removed collection, id
			pub.ready()
			
		Meteor.defer refresh
		refreshHandle = Meteor.setInterval refresh, refreshTime || 10000
		
		@onStop ->
			console.log "on stop"
			Meteor.clearInterval refreshHandle

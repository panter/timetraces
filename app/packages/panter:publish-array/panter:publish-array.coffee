

Meteor.publishArray = (options) ->
	{name, collection, data, refreshTime} = options

	Meteor.publish name, (params) ->
		pub = @
		ids = {}
		refresh = ->
			console.log "refreshing #{name}"
			currentIds = {}
			try
				results = data.call pub, params
			catch error
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
			
		Meteor.defer refresh
		if refreshTime?
			refreshHandle = Meteor.setInterval refresh, refreshTime
		
		@onStop =>
			console.log "on stop", name
			if refreshHandle?
				Meteor.clearInterval refreshHandle

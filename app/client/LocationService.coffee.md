## LocationService.coffe.md

This object enables one user to login to a location-service running at [location.macrozone.ch](location.macrozone.ch)
and subscribe to it. It will receive Locations of the user in the Locationservie.Locations-collection.

First, startup the connection to the server and initialize an empty collection:

	connection = null
	loggedIn = no		
	Meteor.startup ->
		connection = DDP.connect "location.macrozone.ch"
		LocationService.Locations = new Meteor.Collection "Locations", connection

Wherever the saved locationServiceUser changes (or is initially set), refresh the login to the service:

		Meteor.autorun ->
			user = UserSettings.get "locationServiceUser"
			if not loggedIn and user?.token?
				LocationService.refresh user.token

Expose the LocationService with its methods globally (singleton):

	@LocationService = 
		subscribe: (name, params) ->
			connection.subscribe name, params
		login: (email, password, callback) ->
			console.log "login in"
			params =
					user: email: email
					password: password
			connection?.call "login", params, (error, user) ->
				loggedIn = yes
				UserSettings.set "locationServiceUser", user
		refresh: (token) ->
			console.log "refreshing"
			connection?.call "login", resume: token, (error, user) ->
				loggedIn = yes
				UserSettings.set "locationServiceUser", user
		logout: ->
			connection?.call "logout"
			UserSettings.set "locationServiceUser", null
			console.log "login out"
			loggedIn = no
		fetchFor: (from, to) ->
			@Locations.find({tst: {$gte:from, $lte: to }}, {sort: tst: -1}).fetch()
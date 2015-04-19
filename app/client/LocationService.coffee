connection = null
loggedIn = no		
Meteor.startup ->
	connection = DDP.connect "location.macrozone.ch"
	LocationService.Locations = new Meteor.Collection "Locations", connection
	Meteor.autorun ->
		user = UserSettings.get "locationServiceUser"
		if not loggedIn and user?.token?
			LocationService.refresh user.token


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
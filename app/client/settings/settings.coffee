
Router.route 'settings', 
	waitOn: share.SubscriptionService.defaults
	data: ->
		redmineProjects: ->RedmineProjects.find().map (project) ->
			label: project.name
			value: project._id
		calendars: -> Calendars.find().map (calendar) ->
			label: calendar.summary
			value: calendar._id
		settings: -> 
			if Meteor.user()?
				doc = UserSettingsStore.findOne()

Template.settings_locationService.helpers
	loggedIn: ->
		UserSettings.get("locationServiceUser")?.tokenExpires?.getTime() > new Date().getTime()
	expires: -> moment(UserSettings.get("locationServiceUser")?.tokenExpires).calendar()

Template.settings_locationService.events
	'click .btn-login': (event, template) ->
		
	
		email = template.$("[name='email']").val()
		password = template.$("[name='password']").val()
		LocationService.login email, password, (error, user) ->
			if error?
				alert error.message
			else
				template.$("[name='email']").val ""
				template.$("[name='password']").val ""

	'click .btn-logout': ->
		LocationService.logout()
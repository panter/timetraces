
Router.route 'settings', 
	waitOn: share.defaultSubscriptions
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
				


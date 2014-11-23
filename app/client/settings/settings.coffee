
Router.route 'settings', 
	subscriptions: ->[Meteor.subscribe "calendarList", Meteor.subscribe "redmineProjects"]
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
				


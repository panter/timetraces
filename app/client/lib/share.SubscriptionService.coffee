



share.SubscriptionService = 
	defaults: ->
		subscriptions = [] 

		subscriptions.push Meteor.subscribe "calendarList"
		subscriptions.push Meteor.subscribe "redmineProjects"
		subscriptions.push Meteor.subscribe "projects"
		#subscriptions.push Meteor.subscribe "project_states"
		subscriptions.push Meteor.subscribe "allTasks"
		
		return subscriptions
	events: (firstMoment, lastMoment) ->
		subscriptions = [] 
		subscriptions.push Meteor.subscribe "githubEvents" # todo: add from-to
		subscriptions.push Meteor.subscribe "time_entries", 
			employee_usernames: UserSettings.get "controllrUsername"
			date_from: firstMoment.format()
		
		subscriptions.push LocationService.subscribe "myLocations", from: firstMoment.toDate(), to: lastMoment.toDate()
		for calendarId in UserSettings.getListSetting(UserSettings.PROPERTY_CALENDARS)
			subscriptions.push Meteor.subscribe "latestCalendarEvents", 
				calendarId: calendarId
				singleEvents: true
				timeMax: lastMoment.format()
				timeMin: firstMoment.format()
				orderBy: "startTime"
		
		for projectId in UserSettings.getListSetting("redmineProjects")
			subscriptions.push Meteor.subscribe "redmineIssues", 
				project_id: projectId
				updated_on: encodeURIComponent("><")+firstMoment.format("YYYY-MM-DD")+"|"+lastMoment.format("YYYY-MM-DD")
		return subscriptions


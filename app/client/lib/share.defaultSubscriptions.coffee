

share.defaultSubscriptions = ->
	subscriptions = [] 
	firstMoment = moment().startOf("day").subtract(UserSettings.get("numberOfDays", 7), "days")
	lastMoment = moment().endOf("day")
	subscriptions.push Meteor.subscribe "modifiedEvents", timeMax: lastMoment.format(), timeMin: firstMoment.format()
	subscriptions.push Meteor.subscribe "calendarList"
	subscriptions.push Meteor.subscribe "redmineProjects"
	subscriptions.push Meteor.subscribe "projects"
	subscriptions.push Meteor.subscribe "project_states"
	subscriptions.push Meteor.subscribe "allTasks"
	subscriptions.push Meteor.subscribe "githubEvents"
	subscriptions.push Meteor.subscribe "time_entries", 
		employee_usernames: UserSettings.get "controllrUsername"
		date_from: firstMoment.format()
	for calendar in Calendars.find(_id: $in: UserSettings.getListSetting(UserSettings.PROPERTY_CALENDARS)).fetch()
		subscriptions.push Meteor.subscribe "latestCalendarEvents", 
			calendarId: calendar._id
			singleEvents: true
			timeMax: lastMoment.format()
			timeMin: firstMoment.format()
			orderBy: "startTime"
	
	for project in RedmineProjects.find(_id: $in: UserSettings.getListSetting("redmineProjects")).fetch()
		subscriptions.push Meteor.subscribe "redmineIssues", 
			project_id: project._id
			updated_on: encodeURIComponent(">=")+firstMoment.format("YYYY-MM-DD")
	subscriptions
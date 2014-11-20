NUMBER_OF_WEEKS = 2
Accounts.ui.config
	requestOfflineToken: google: true
  
	requestPermissions: 
		google: ['https://www.googleapis.com/auth/calendar']

Router.configure layoutTemplate: 'layout'

@Calendars = new Meteor.Collection "Calendars"
@Projects = new Meteor.Collection "Projects"
@Tasks = new Meteor.Collection "Tasks"
@ProjectStates = new Meteor.Collection "ProjectStates"
@Events = new Meteor.Collection "Events"
@RedmineProjects = new Meteor.Collection "RedmineProjects"
@RedmineIssues = new Meteor.Collection "RedmineIssues"


defaultSubscriptions = ->
	subscriptions = [] 
	subscriptions.push Meteor.subscribe "savedEvents"
	subscriptions.push Meteor.subscribe "calendarList"
	subscriptions.push Meteor.subscribe "redmineProjects"
	for calendar in Calendars.find(_id: $in: UserSettings.getListSetting(UserSettings.PROPERTY_CALENDARS)).fetch()
		subscriptions.push Meteor.subscribe "latestCalendarEvents", 
			calendarId: calendar._id
			singleEvents: true
			timeMax: moment().format()
			timeMin: moment().subtract(NUMBER_OF_WEEKS, "weeks").format()
			orderBy: "startTime"
	for project in RedmineProjects.find(_id: $in: UserSettings.getListSetting(UserSettings.PROPERTY_REDMINE_PROJECTS)).fetch()
		subscriptions.push Meteor.subscribe "redmineIssues", 
			project_id: project._id
			updated_on: encodeURIComponent(">=")+moment().subtract(NUMBER_OF_WEEKS, "weeks").format("YYYY-MM-DD")
	subscriptions

Router.map ->
	@route 'calendarTest'
	@route 'settings', 
		subscriptions: defaultSubscriptions
	@route 'eventList', 
		subscriptions: defaultSubscriptions	

	@route 'home', path: "/"
	@route 'postForm',
		subscriptions: -> [
			Meteor.subscribe "projects"
			Meteor.subscribe "project_states"
			Meteor.subscribe "allTasks"
		]
	

Template.registerHelper "equals", (a, b) ->
	a == b
Template.registerHelper "duration", (date1, date2, value="minutes") ->
	value = "minutes"
	moment(date1).twix(date2).humanizeLength()
Template.registerHelper "calendarFormat", (date, date2) -> 
	console.log date, date2
	if date2?
		moment(date).twix(date2).format()
	else
		moment(date).calendar()

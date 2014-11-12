Accounts.ui.config
	requestPermissions: 
		google: ['https://www.googleapis.com/auth/calendar']

Router.configure layoutTemplate: 'layout'

@Calendars = new Meteor.Collection "Calendars"
@Projects = new Meteor.Collection "Projects"
@Tasks = new Meteor.Collection "Tasks"
@ProjectStates = new Meteor.Collection "ProjectStates"


Router.map ->
	@route 'calendarTest'
	@route 'calendarList', 
		subscriptions: -> Meteor.subscribe "calendarList"
	@route 'home', path: "/"
	@route 'postForm',
		subscriptions: -> [
			Meteor.subscribe "projects"
			Meteor.subscribe "project_states"
			Meteor.subscribe "allTasks"
		]
	



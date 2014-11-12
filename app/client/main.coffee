Accounts.ui.config
	requestPermissions: 
		google: ['https://www.googleapis.com/auth/calendar']

Router.configure layoutTemplate: 'layout'

Router.map ->
	@route 'calendarTest'
	@route 'home', path: "/"
	@route 'postForm',
		subscriptions: -> [
			Meteor.subscribe "projects"
			Meteor.subscribe "project_states"
		]
	


Projects = new Meteor.Collection null



Accounts.ui.config
	requestOfflineToken: google: true
  
	requestPermissions: 
		google: ['https://www.googleapis.com/auth/calendar']



@Calendars = new Meteor.Collection "Calendars"
@Projects = new Meteor.Collection "Projects"
@Tasks = new Meteor.Collection "Tasks"
@ProjectStates = new Meteor.Collection "ProjectStates"
@Events = new Meteor.Collection "Events"
@RedmineProjects = new Meteor.Collection "RedmineProjects"
@RedmineIssues = new Meteor.Collection "RedmineIssues" # remove?
@TimeEntries = new Meteor.Collection "TimeEntries"



Router.configure 

	layoutTemplate: 'layout'
	loadingTemplate: 'loading'


Router.map ->
	
	

	@route 'home', path: "/"
	

Template.registerHelper "equals", (a, b) ->
	a == b
Template.registerHelper "duration", (date1, date2, value="minutes") ->
	value = "minutes"
	moment(date1).twix(date2).humanizeLength()
Template.registerHelper "calendarFormat", (date, date2) -> 
	
	if date2?
		moment(date).twix(date2).format()
	else
		moment(date).calendar()

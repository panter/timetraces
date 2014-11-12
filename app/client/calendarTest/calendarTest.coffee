Template.calendarTest.helpers
	currentCalendar: ->Session.get "currentCalendar"
	loggingIn: -> Meteor.loggingIn()

Template.calendarTestList.helpers
	calendars: -> 
		GCalendar.CalendarData().get()

Template.calendarTestList.events
	'click li': ->

		Session.set "currentCalendar", @id

Template.calendarTestEventList.helpers
	events: -> 

		GCalendar.EventData Session.get "currentCalendar"
		.get()

Template.calendarTestEventList.events
	'click .btn-update': ->
		GCalendar.EventData(@calendarId).update()


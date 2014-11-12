


eventData = {}

BaseData = class
	constructor: () ->
		@dep = new Tracker.Dependency
		@data = null
	get: ->
		@dep.depend()
		unless @data?
			@update()
		@data

	update: =>
		@apiCall()
		.then (data) =>
			@data = data.items
			@dep.changed()
		.done()


CalendarData = class extends BaseData
	
	apiCall:-> GoogleCalendarApi.getCalendarList()

EventData = class extends BaseData
	constructor: (@calendarId) ->
		
		super()
	apiCall: ->
		GoogleCalendarApi.getEvents @calendarId

	
calendarData = null


@GCalendar = 
	CalendarData: ->
		unless calendarData?
			calendarData = new CalendarData
		calendarData
	EventData: (calendarId) ->

		unless eventData[calendarId]?
			eventData[calendarId] = new EventData calendarId
		
		eventData[calendarId]


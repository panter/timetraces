@GoogleCalendarApi = 
	getCalendarList: ->
		GoogleApi.get 'calendar/v3/users/me/calendarList'
	getEvents: (calendarId) ->
		GoogleApi.get "calendar/v3/calendars/#{calendarId}/events"



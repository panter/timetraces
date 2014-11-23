
pixelPerMinute = 1
dayHeight = 1440 * pixelPerMinute

listHeight = 120

NUMBER_OF_WEEKS = 2

Router.route 'eventList', 
	subscriptions: ->
		subscriptions = [] 
		subscriptions.push Meteor.subscribe "savedEvents"
		subscriptions.push Meteor.subscribe "calendarList"
		subscriptions.push Meteor.subscribe "redmineProjects"
		subscriptions.push Meteor.subscribe "time_entries",
			employee_usernames: UserSettings.get "controllrUsername"
			date_from: moment().subtract(NUMBER_OF_WEEKS, "weeks").format()
		for calendar in Calendars.find(_id: $in: UserSettings.getListSetting(UserSettings.PROPERTY_CALENDARS)).fetch()
			subscriptions.push Meteor.subscribe "latestCalendarEvents", 
				calendarId: calendar._id
				singleEvents: true
				timeMax: moment().format()
				timeMin: moment().subtract(NUMBER_OF_WEEKS, "weeks").format()
				orderBy: "startTime"
		
		for project in RedmineProjects.find(_id: $in: UserSettings.getListSetting("redmineProjects")).fetch()
			console.log project
			subscriptions.push Meteor.subscribe "redmineIssues", 
				project_id: project._id
				updated_on: encodeURIComponent(">=")+moment().subtract(NUMBER_OF_WEEKS, "weeks").format("YYYY-MM-DD")
		subscriptions	

Template.eventList.helpers
	viewMode: -> UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE

	days: ->
		

		newestMoment = moment().endOf("day")
		oldestMoment = moment().subtract(NUMBER_OF_WEEKS, "weeks").startOf("day")
		console.log newestMoment.format(), oldestMoment.format()
		days = []
		while(oldestMoment.valueOf()< newestMoment.valueOf())
			days.push moment(newestMoment)
			newestMoment.subtract 1, "d"
		days



getPreferedStartOfDay = (dayMoment) ->
	newMoment = moment dayMoment
	preference = UserSettings.get UserSettings.PROPERTY_START_OF_DAY
	if preference?
		[hour, minute] = preference.split ":"
		if hour? and minute?
			return newMoment.set("hour", hour).set("minute", minute)
	return newMoment.startOf "day"

getStartOfEvent = (event) ->

	eventDate = event.end
	eventMoment = moment eventDate
	if event.start?
		event.start
	else
		previousEvent = Events.findOne {end: $lt: eventDate}, sort: "end": -1
		unless previousEvent?
			return
		lastEventDate = previousEvent.end
		lastEventMoment = moment lastEventDate
		# do not go befor start of the day
		if moment(lastEventMoment).startOf("day").isSame(moment(eventMoment).startOf("day"))
			lastEventMoment.toDate()
		else


			preferedStartOfDay = getPreferedStartOfDay(eventMoment).toDate()
			# check if this date is before the end of the day
			if preferedStartOfDay.getTime() > event.end.getTime()
				startMoment = moment eventMoment
				
				startMoment.subtract 1, "hours"
				startMoment.toDate()
			else
				preferedStartOfDay


mergeEvents = (event, toMerge) ->
	
	event.bulletPoints = event.bulletPoints.concat toMerge.bulletPoints
	if toMerge.start.getTime() < event.start.getTime()
		event.start = toMerge.start
	if toMerge.end.getTime() > event.end.getTime()
		event.end = toMerge.end
	
getSanitizedEvents = ->
	end = @toDate()
	start = moment(@).startOf("day").toDate()
	preferedStartTime = getPreferedStartOfDay(@).toDate()
	
	events = []
	
	lastEvent = null
	Events.find({end: {$gte: start, $lt: end}}, sort: "end": 1).forEach (doc) =>
		start = getStartOfEvent doc
		doc.start = start
		
		minMinutes = UserSettings.get UserSettings.PROPERTY_MINIMUM_MERGE_TIME
		mergeOverlapping = true
		
		if minMinutes > 0 and lastEvent? and ((moment(doc.end).diff(doc.start, "minutes") < minMinutes))
			mergeEvents lastEvent, doc
		
		else if mergeOverlapping and lastEvent? and lastEvent.end.getTime() > start.getTime()
			
			mergeEvents lastEvent, doc

			console.log moment(start).diff(lastEvent?.start, "minutes")
		else 
			if start? and lastEvent? and start.getTime() > lastEvent.end.getTime() and start.getTime() > preferedStartTime.getTime()
				# gap, add a fake doc
				
				events.push 
					_id: "before_#{doc._id}"
					isGap: true
					bulletPoints: ["gap"]
					start: lastEvent.end
					end: start
					index: events.length
			lastEvent = doc
			doc.index = events.length
			events.push doc
	
	events.reverse()

getSanitizedTimeEntries = ->
	
	entries = []
	
	
	TimeEntries.find({day: moment(@).format("YYYY-MM-DD")}, sort: "start": 1).forEach (doc) ->
		doc.index = entries.length
		entries.push doc
	entries
	

Template.eventList_oneDay.helpers
	height: ->
		if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
			count = getSanitizedEvents.apply(@).length
			if count > 0 then count * listHeight else "auto" 
		else
			dayHeight
	events: getSanitizedEvents
	timeEntries: getSanitizedTimeEntries

	


# sanitize event startDate
getSavedEvent = (id) ->
	SavedEvents.findOne userId: Meteor.userId(), eventId: id


bottomHelper = ->
	if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		listHeight * @index
	else
		mnt = moment getStartOfEvent @

		midnight = moment(mnt).startOf "day"
		mnt.diff(midnight, "minutes") * pixelPerMinute

heightHelper = ->
	if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		listHeight
	else
		duration = (new Date @end).getTime() - (new Date getStartOfEvent @).getTime()
		duration/60000 * pixelPerMinute
Template.eventList_oneEvent.helpers
	
	start: ->
		getStartOfEvent @

	declined: ->
		savedEvent = getSavedEvent @_id
		savedEvent?.state is "declined"
	acknowledged: ->
		savedEvent = getSavedEvent @_id
		savedEvent?.state is "acknowledged"
	bottom: bottomHelper
		
	height: heightHelper

Template.eventList_oneTimeEntry.helpers 
	bottom: bottomHelper
		
	height: heightHelper

Template.eventList_oneEvent.rendered = ->
	addDrag @firstNode


Template.eventList_oneEvent.events
	'click': ->
		#disabled
		return true
		savedEvent = getSavedEvent @_id
		unless savedEvent?
			newEvent = _.clone @
			newEvent.userId =  Meteor.userId()
			newEvent.eventId = @_id
			newEvent.state =  "acknowledged"
			delete newEvent._id

			SavedEvents.insert newEvent
		else
			# toggle state
			if savedEvent.state == "acknowledged"
				newState = "declined"
			else
				newState = "acknowledged"
			SavedEvents.update {_id: savedEvent._id}, $set: state: newState


pixelPerMinute = 1.5
dayHeight = 1440 * pixelPerMinute

listHeight = 120



Router.route 'eventList', 
	subscriptions: ->
		subscriptions = [] 
		subscriptions.push Meteor.subscribe "savedEvents"
		subscriptions.push Meteor.subscribe "calendarList"
		subscriptions.push Meteor.subscribe "redmineProjects"
		subscriptions.push Meteor.subscribe "projects"
		subscriptions.push Meteor.subscribe "project_states"
		subscriptions.push Meteor.subscribe "allTasks"
		subscriptions.push Meteor.subscribe "githubEvents"
		subscriptions.push Meteor.subscribe "time_entries",
			employee_usernames: UserSettings.get "controllrUsername"
			date_from: moment().startOf("day").subtract(UserSettings.get("numberOfWeeks", 2), "weeks").format()
		for calendar in Calendars.find(_id: $in: UserSettings.getListSetting(UserSettings.PROPERTY_CALENDARS)).fetch()
			subscriptions.push Meteor.subscribe "latestCalendarEvents", 
				calendarId: calendar._id
				singleEvents: true
				timeMax: moment().endOf("day").format()
				timeMin: moment().startOf("day").subtract(UserSettings.get("numberOfWeeks", 2), "weeks").format()
				orderBy: "startTime"
		
		for project in RedmineProjects.find(_id: $in: UserSettings.getListSetting("redmineProjects")).fetch()
			subscriptions.push Meteor.subscribe "redmineIssues", 
				project_id: project._id
				updated_on: encodeURIComponent(">=")+moment().startOf("day").subtract(UserSettings.get("numberOfWeeks", 2), "weeks").format("YYYY-MM-DD")
		subscriptions

	data: ->
		if @ready()
			viewMode: -> UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
			days: ->
				newestMoment = moment().endOf("day")
				oldestMoment = moment().subtract(UserSettings.get("numberOfWeeks", 2), "weeks").startOf("day")
				
				days = []
				while(oldestMoment.valueOf()< newestMoment.valueOf())
					dayMoment = moment newestMoment
					events = getSanitizedEvents dayMoment
					timeEntries = getSanitizedTimeEntries dayMoment
					both = events.concat timeEntries
					first = _.min both, (entry) -> entry.start.getTime()
					last = _.max both, (entry) -> entry.end.getTime()
			
					days.push 
						dayMoment: dayMoment
						dayEvents: events
						timeEntries: timeEntries
						firstMoment: moment first.start
						lastMoment: moment last.end
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


getLastEventDate = (eventDate) ->
	previousEvent = Events.findOne {end: $lt: eventDate}, sort: "end": -1
	previousTimeEntry = TimeEntries.findOne {day: moment(eventDate).format("YYYY-MM-DD"), end: $lt: eventDate}, sort: "end": -1

	
	if previousTimeEntry? and previousEvent?
		# get closer one
		if previousTimeEntry.end.getTime() > previousEvent.end.getTime()
			lastEventDate = previousTimeEntry.end
		else
			lastEventDate = previousEvent.end
	else if previousTimeEntry?
		lastEventDate = previousTimeEntry.end
	else if previousEvent?
		lastEventDate = previousEvent.end
	else 
		return 

getStartOfEvent = (event) ->

	eventDate = event.end
	eventMoment = moment eventDate
	if event.start?
		event.start
	else
		lastEventDate = getLastEventDate eventDate
		lastTimeEntryByStart = TimeEntries.findOne {day: moment(eventDate).format("YYYY-MM-DD"), start: $lt: eventDate}, sort: "start": -1
		if lastTimeEntryByStart? and lastTimeEntryByStart.start.getTime() > lastEventDate.getTime()
			lastEventDate = lastTimeEntryByStart.start
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
	
getSanitizedEvents = (dayMoment)->
	end = dayMoment.toDate()
	start = moment(dayMoment).startOf("day").toDate()
	preferedStartTime = getPreferedStartOfDay(dayMoment).toDate()
	
	events = []
	
	lastEvent = null
	Events.find({end: {$gte: start, $lt: end}}, sort: "end": 1).forEach (doc) =>
		start = getStartOfEvent doc
		doc.start = start
		
		minMinutes = UserSettings.get UserSettings.PROPERTY_MINIMUM_MERGE_TIME
		

		
		if minMinutes > 0 and lastEvent? and lastEvent.source is doc.source and((moment(doc.end).diff(doc.start, "minutes") < minMinutes))
			mergeEvents lastEvent, doc
		
		else if lastEvent? and lastEvent.source is doc.source and lastEvent.end.getTime() > start.getTime()
			
			mergeEvents lastEvent, doc

		else 
			
			lastEventDate = getLastEventDate doc.end


			if start? events.length > 0 and lastEventDate? and start.getTime() > lastEventDate.getTime() and start.getTime() > preferedStartTime.getTime()
				# gap, add a fake doc
				
				events.push 
					_id: "before_#{doc._id}"
					isGap: true
					bulletPoints: ["gap"]
					start: lastEventDate
					end: start
					index: events.length
			lastEvent = doc
			doc.index = events.length
			events.push doc
	
	events.reverse()

getSanitizedTimeEntries = (dayMoment)->
	
	entries = []

	TimeEntries.find({day: moment(dayMoment).format("YYYY-MM-DD")}, sort: "start": 1).forEach (doc) ->
		doc.index = entries.length
		entries.push doc
	entries




#Template.eventList_oneDay.rendered = ->
#	@$(".fixedsticky").fixedsticky()

Template.eventList_oneDay.helpers
	height: ->
		if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
			count = Math.max @dayEvents.length, @timeEntries.length
		

			if count > 0 then count * listHeight else "auto" 
		else
			
			
			if @firstMoment? and @lastMoment?
				duration = @lastMoment.toDate().getTime() - @firstMoment.toDate().getTime()
				duration/60000 * pixelPerMinute
			else
				0

	




bottomHelper = ->
	if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		listHeight * @index
	else
		
		dayData = Template.parentData(1)
		mnt = moment getStartOfEvent @
		mnt.diff(dayData.firstMoment, "minutes") * pixelPerMinute
	
heightHelper = ->
	if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		listHeight
	else
		duration = (new Date @end).getTime() - (new Date getStartOfEvent @).getTime()
		duration/60000 * pixelPerMinute

Template.eventList_oneEvent.helpers	
	bottom: bottomHelper
	height: heightHelper

Template.eventList_oneTimeEntry.helpers 
	bottom: bottomHelper
	height: heightHelper


Template.eventList_oneEvent.events
	'click': (event, template)->
		Session.set "currentEvent", template.data
		Router.go "newTimeEntry"


Template.eventList_oneTimeEntry.events
	'click': ->
		Router.go "editTimeEntry", timeEntryId: @_id















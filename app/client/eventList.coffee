
pixelPerMinute = 1.5
dayHeight = 1440 * pixelPerMinute

listHeight = 120

Router.route 'eventList',
	path: "/" 
	yieldRegions: 
		eventList_navigation: to: "headerNavigation"
	subscriptions: ->
		subscriptions = share.SubscriptionService.defaults()
		firstMoment = moment().startOf("day").subtract(UserSettings.get("numberOfDays", 7), "days")
		lastMoment = moment().endOf("day")
		subscriptions = subscriptions.concat share.SubscriptionService.events firstMoment, lastMoment
		return subscriptions
	data: ->

		viewMode: -> UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		days: ->
			newestMoment = moment().endOf("day")
			oldestMoment = moment().subtract(UserSettings.get("numberOfDays", 7), "days").startOf("day")

			days = []
			while(oldestMoment.valueOf()< newestMoment.valueOf())
				dayMoment = moment newestMoment
				
				events = getAllEventsOfDay dayMoment
				timeEntries = getAllTimeEntriesOfDay dayMoment
				both = events.concat timeEntries
				first = _.min both, (entry) -> entry.start.getTime()
				last = _.max both, (entry) -> entry.end.getTime()
				shortestEvent = _.min both, (entry) -> entry.end?.getTime() - entry.start?.getTime()

				days.push 
					dayMoment: dayMoment
					dayEvents: events
					timeEntries: timeEntries
					firstMoment: moment first.start
					lastMoment: moment last.end
					shortestEvent: shortestEvent
				newestMoment.subtract 1, "d"
			days



getAllEventsOfDay = (dayMoment)->
	originalEvents = getRawEventsOfDay dayMoment
	events = []

	lastEvent = null
	
	for event in originalEvents
		# sanitize start date
		event.start = getStartOfEvent originalEvents, event
		# find a possible project for the event
		event.project = findProject event
		
		# check if event should be merged with lastEvent (if any)
		shouldMerge = ->
			minMinutes = UserSettings.get UserSettings.PROPERTY_MINIMUM_MERGE_TIME
			return no unless lastEvent?
			return no unless lastEvent.project? or event.project?
			return no unless lastEvent.project?._id is event.project?._id
			return yes if minMinutes? and moment(event.end).diff(event.start, "minutes") < minMinutes
			return yes if lastEvent.end.getTime() > event.start.getTime() # overlapping
			return no # everything else
		
		if shouldMerge()
			mergeEvents lastEvent, event
		else 
			lastEventDate = getLastEventOrTimeEntryEndTime originalEvents, event.end
			preferedStartTime = getPreferedStartOfDay(dayMoment).toDate()

			if events.length > 0 and lastEventDate? and event.start.getTime() > lastEventDate.getTime() and event.start.getTime() > preferedStartTime.getTime()
				# gap, add a fake event
				
				events.push 
					_id: "before_#{event._id}"
					isGap: true
					bulletPoints: ["gap"]
					start: lastEventDate
					end: event.start
					index: events.length
			lastEvent = event
			event.index = events.length
			events.push event
	
	events.reverse()

getRawEventsOfDay = (dayMoment) ->
	end = dayMoment.toDate()
	start = moment(dayMoment).startOf("day").toDate()
	events = Events.find({end: {$gte: start, $lt: end}}, sort: "end": 1).fetch()

	appendLocationEvents events, start, end
	return _.sortBy events, (event) -> - event.end.getTime()

appendLocationEvents = (events, start, end) ->

	MIN_DISTANCE = UserSettings.get "locationServiceMinDistance", 0
	lastLocation = null
	addToEvents = (location) ->
		if location.geo? 
				text = "#{location.geo.city ? ''}, #{location.geo.streetName ? ''} #{location.geo.streetNumber ? ''}"
		else
			text = "#{location.lat}, #{location.lon}" 
		events.push 
			_id: "location_#{location.tst.getTime()}"
			end: location.tst
			sources: [type: "location"]
			bulletPoints: [text]

	for location in LocationService.fetchFor start, end
		unless lastLocation?
			addToEvents location
		else
			a = {longitude: location.lon, latitude: location.lat}
			b = {longitude: lastLocation.lon, latitude: lastLocation.lat}
			distance =  geolib.getDistance a, b
			addToEvents location if distance >= MIN_DISTANCE
		lastLocation = location

mergeEvents = (event, toMerge) ->
	event.sources = _.unique (event.sources.concat toMerge.sources), (item) -> JSON.stringify item
	event.bulletPoints = _.unique event.bulletPoints.concat toMerge.bulletPoints
	if toMerge.start.getTime() < event.start.getTime()
		event.start = toMerge.start
	if toMerge.end.getTime() > event.end.getTime()
		event.end = toMerge.end

findProject = (event) ->
	if event?
		traces = _.pluck event.sources, "label"
		traces = traces.concat event.bulletPoints
		for trace in traces
			if trace?
				# first: take the mapping from the settings
				trace = trace.toLowerCase()
				projectMap = UserSettings.get("projectMap")
				if projectMap?
					for index, map of projectMap
						if trace.indexOf(map?.keyword?.toLowerCase()) > -1
							project = Projects.findOne map?.projectId
							return project if project?
				# second: check if a project shortname is in the traces
				for word in trace.split /[\s/]+/
					project = Projects.findOne shortname: word
					return project if project?
findTaskID = (event) ->
	sourceTaskMap = 
		redmine: "Development"
		github: "Development"
		calendar: "Internal Meeting"

	for keyword, taskName of sourceTaskMap
		if _.pluck(event?.sources, "label").join(" ").toLowerCase().indexOf(keyword) >= 0
			task = Tasks.findOne project_id: Session.get("currentProjectId"), name: taskName
			return task._id if task?

getPreferedStartOfDay = (dayMoment) ->
	newMoment = moment dayMoment
	preference = UserSettings.get UserSettings.PROPERTY_START_OF_DAY
	if preference?
		[hour, minute] = preference.split ":"
		if hour? and minute?
			return newMoment.set("hour", hour).set("minute", minute)
	return newMoment.startOf "day"

getStartOfEvent = (events, event) ->
	eventDate = event.end
	eventMoment = moment eventDate
	if event.start?
		return event.start
	else

		lastEventDate = getLastEventOrTimeEntryEndTime events, eventDate
		
		# do not go befor start of the day
		if lastEventDate? and moment(lastEventDate).startOf("day").isSame(moment(eventMoment).startOf("day"))
			lastEventDate
		else
			# seems to be first event, 
			preferedStartOfDay = getPreferedStartOfDay(eventMoment).toDate()
			# check if this date is before the end of the day
			if preferedStartOfDay.getTime() > event.end.getTime()
				startMoment = moment eventMoment
				
				startMoment.subtract 1, "hours"
				startMoment.toDate()
			else
				preferedStartOfDay		

getLastEventOrTimeEntryEndTime = (events, eventDate) ->
	day = moment(eventDate).format("YYYY-MM-DD")
	endTime = (event) ->
		event.end.getTime()
	eventsFiltered = _(events).filter((event) -> endTime(event) < eventDate.getTime())
	candidates = [
		_.max(eventsFiltered, endTime)?.end
		TimeEntries.findOne({day: day, end: $lt: eventDate}, sort: "end": -1)?.end
		TimeEntries.findOne({day: day, start: $lt: eventDate}, sort: "start": -1)?.end
	]
	
	lastDate = _.max candidates, (date) ->
		if date? then date.getTime() else 0

	return lastDate


getAllTimeEntriesOfDay = (dayMoment)->
	entries = []
	TimeEntries.find({day: moment(dayMoment).format("YYYY-MM-DD")}, sort: "start": 1).forEach (doc) ->
		doc.index = entries.length
		entries.push doc
	entries


Template.eventList_oneDay.events
	'click .btn-add-entry': (event, template)->
		editTimeEntry 
			new: yes
			day: template.data.dayMoment.toDate()
			user_id: UserSettings.get "controllrUserId"
			start: getPreferedStartOfDay(template.data.dayMoment).format "HH:mm"



Template.eventList_oneDay.helpers
	totalHoursTracked: ->
		minutes = _.reduce @timeEntries, (sum, entry) ->
			return sum + new Date(entry.end).getTime()/60000 - new Date(entry.start).getTime()/60000
		, 0
		trackedMoment = moment.duration minutes, "minutes"
		"#{trackedMoment.hours()}:#{trackedMoment.minutes()}"

	height: ->
		if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
			count = Math.max @dayEvents.length, @timeEntries.length


			if count > 0 then count * listHeight else "auto"
		else
			if @shortestEvent?

				shortestDuration = @shortestEvent.end?.getTime() - @shortestEvent.start?.getTime()
			if @firstMoment? and @lastMoment?
				duration = @lastMoment.toDate().getTime() - @firstMoment.toDate().getTime()
				duration/60000 * pixelPerMinute
			else
				0

	

Template.eventList_oneDay_timeGrid.helpers
	offset: ->
		dayMoment = moment(@dayMoment).startOf "day"
		duration = @firstMoment?.toDate().getTime() - dayMoment?.toDate().getTime()
		return -duration/60000 * pixelPerMinute
	entries: ->
		gridMoment = moment(@dayMoment).startOf "day"
		intervalInHours = 6
		entries =  for i in [1..(24/intervalInHours)-1]
			aMoment = gridMoment.add intervalInHours, "hours"
			label: aMoment.format "HH:mm"
			bottom: pixelPerMinute*intervalInHours*60*i

		# add entry for the prefered start of day
		#startOfDay = getPreferedStartOfDay()
		#entries.push 
		#	aMoment: startOfDay
		#	label: "Start of Day"
		#	bottom: pixelPerMinute*(@dayMoment.toDate().getTime() - startOfDay.toDate().getTime())/60000
		return entries

bottomHelper = ->
	if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		listHeight * @index
	else
		dayData = Template.parentData(1)
		mnt = moment @start
		Math.ceil mnt.diff(dayData.firstMoment, "minutes") * pixelPerMinute
	
heightHelper = ->
	if "list" is UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
		listHeight
	else
		duration = (new Date @end).getTime() - (new Date @start).getTime()
		Math.floor  duration/60000 * pixelPerMinute


Template.eventList_oneEvent.helpers	
	bottom: bottomHelper
	height: heightHelper

Template.eventList_oneEvent.events
	'click': (event, template)->
		editTimeEntry transformEventToTimeEntry template.data

Template.eventList_oneTimeEntry.helpers 
	bottom: bottomHelper
	height: heightHelper

Template.eventList_oneTimeEntry.events
	'click': ->
		editTimeEntry sanitizeStartEndTime TimeEntries.findOne @_id




transformEventToTimeEntry = (event)->
	if event.project?._id?
		Session.set "currentProjectId", event.project._id.toString()

	description: event.bulletPoints?.map((point) -> "- #{point}").join "\n"
	project_id: Session.get "currentProjectId"
	task_id: findTaskID event
	user_id: UserSettings.get "controllrUserId"
	start: sanitizeTime event.start
	end: sanitizeTime event.end
	day: moment(event.start).toDate()
	new: true




editTimeEntry = (timeEntry) ->
	Session.set "timeEntryToEdit", timeEntry
	if timeEntry?.project_id?
		Session.set "currentProjectId", timeEntry.project_id
	if timeEntry?.task_id?
		Session.set "currentTaskId", timeEntry.task_id
	$("#eventList_editDialog").modal "show"



sanitizeStartEndTime = (timeEntry) ->
	if timeEntry?
		timeEntry.start = sanitizeTime timeEntry.start
		timeEntry.end = sanitizeTime timeEntry.end
		timeEntry
sanitizeTime = (date) ->
	moment(date).format "HH:mm"








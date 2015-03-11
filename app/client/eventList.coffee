
pixelPerMinute = 1.5
dayHeight = 1440 * pixelPerMinute

listHeight = 120



Router.route 'eventList',
	path: "/" 
	waitOn: ->
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
				
				events = getSanitizedEvents dayMoment
				timeEntries = getSanitizedTimeEntries dayMoment
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



editTimeEntry = (timeEntry) ->
	Session.set "timeEntryToEdit", timeEntry
	
	$("#eventList_editDialog").modal "show"

findTaskID = (event) ->

	sourceTaskMap = 
		redmine: "Development"
		github: "Development"
		calendar: "Internal Meeting"


	for keyword, taskName of sourceTaskMap
		if event?.sources?.join(" ").toLowerCase().indexOf(keyword) >= 0
			task = Tasks.findOne project_id: Session.get("currentProjectId"), name: taskName
			return parseInt task._id, 10 if task?






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

		if lastTimeEntryByStart? and (not lastEventDate? or lastTimeEntryByStart.start.getTime() > lastEventDate.getTime())
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
	event.sources = _.unique event.sources.concat toMerge.sources
	event.bulletPoints = _.unique event.bulletPoints.concat toMerge.bulletPoints
	if toMerge.start.getTime() < event.start.getTime()
		event.start = toMerge.start
	if toMerge.end.getTime() > event.end.getTime()
		event.end = toMerge.end

findProject = (event) ->
	traces = event?.sources
	traces = traces.concat event?.bulletPoints
	
	for trace in traces
		# first: take the mapping from the settings
		trace = trace.toLowerCase()
		projectMap = UserSettings.get("projectMap")
		if projectMap?
			for map in projectMap
				if trace.indexOf(map?.keyword?.toLowerCase()) > -1
					project = Projects.findOne map?.projectId
					return project if project?
		# second: check if a project shortname is in the traces
		for word in trace.split /[\s/]+/
			project = Projects.findOne shortname: word
			return project if project?
	

getSanitizedEvents = (dayMoment)->
	end = dayMoment.toDate()
	start = moment(dayMoment).startOf("day").toDate()
	preferedStartTime = getPreferedStartOfDay(dayMoment).toDate()
	
	events = []
	
	lastEvent = null
	Events.find({end: {$gte: start, $lt: end}}, sort: "end": 1).forEach (doc) =>
		start = getStartOfEvent doc
		doc.start = start
		doc.project = findProject doc
		minMinutes = UserSettings.get UserSettings.PROPERTY_MINIMUM_MERGE_TIME
		

		shouldMerge = ->

			return no unless lastEvent?
			return no unless lastEvent.project? or doc.project?
			return no unless lastEvent.project?._id is doc.project?._id
			return yes if minMinutes? and moment(doc.end).diff(doc.start, "minutes") < minMinutes
			return yes if lastEvent.end.getTime() > start.getTime() # overlapping
			return no # everything else
		
		if shouldMerge()
			mergeEvents lastEvent, doc
		else 
			
			lastEventDate = getLastEventDate doc.end


			if start? and events.length > 0 and lastEventDate? and start.getTime() > lastEventDate.getTime() and start.getTime() > preferedStartTime.getTime()
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


Template.eventList_oneDay.events
	'click .btn-add-entry': (event, template)->
	
		editTimeEntry 
			new: yes
			day: template.data.dayMoment.toDate()
			user_id: UserSettings.get "controllrUserId"
			start: getPreferedStartOfDay(template.data.dayMoment).format "HH:mm"


#Template.eventList_oneDay.rendered = ->
#	@$(".fixedsticky").fixedsticky()

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



sanitizeTime = (date) ->
	moment(date).format "HH:mm"

sanitizeStartEndTime = (timeEntry) ->
	if timeEntry?
		timeEntry.start = sanitizeTime timeEntry.start
		timeEntry.end = sanitizeTime timeEntry.end
		timeEntry

transformEventToTimeEntry = (event)->
	

	if event.project?._id?
		Session.set "currentProjectId", parseInt event.project._id, 10
	taskId = findTaskID event


	
	description: event.bulletPoints?.map((point) -> "- #{point}").join "\n"
	project_id: Session.get "currentProjectId"
	task_id: taskId
	user_id: UserSettings.get "controllrUserId"
	start: sanitizeTime event.start
	end: sanitizeTime event.end
	day: moment(event.start).toDate()
	new: true



Template.eventList_oneEvent.events
	'click': (event, template)->
		editTimeEntry transformEventToTimeEntry template.data



Template.eventList_oneTimeEntry.events
	'click': ->
		#Router.go "editTimeEntry", timeEntryId: @_id
		editTimeEntry sanitizeStartEndTime TimeEntries.findOne @_id













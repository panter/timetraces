
pixelPerMinute = 1
dayHeight = 1440 * pixelPerMinute

Template.eventList.helpers
	days: ->
		oldest = Events.findOne {}, sort: end: 1
		newest =  Events.findOne {}, sort: end: -1

		newestMoment = moment(newest?.end).endOf("day")
		oldestMoment = moment(oldest?.end).startOf("day")
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
			getPreferedStartOfDay(eventMoment).toDate()



Template.eventList_oneDay.helpers
	height: dayHeight
	events: -> 
		end = @toDate()
		start = moment(@).startOf("day").toDate()
		
	
		preferedStartTime = getPreferedStartOfDay(@).toDate()
		lastEnd = preferedStartTime
		events = []
		Events.find({end: {$gte: start, $lt: end}}, sort: "end": 1).forEach (doc) =>
			start = getStartOfEvent doc
			
			if start? and lastEnd? and start.getTime() > lastEnd.getTime() and start.getTime() > preferedStartTime.getTime()
				# gap, add a fake doc
				events.push 
					_id: "before_#{doc._id}"
					isGap: true
					title: "gap"
					start: lastEnd
					end: start
			lastEnd = doc.end
			events.push doc
		events



	


# sanitize event startDate
getSavedEvent = (id) ->
	SavedEvents.findOne userId: Meteor.userId(), eventId: id

Template.eventList_oneEvent.helpers
	
	start: ->
		getStartOfEvent @

	declined: ->
		savedEvent = getSavedEvent @_id
		savedEvent?.state is "declined"
	acknowledged: ->
		savedEvent = getSavedEvent @_id
		savedEvent?.state is "acknowledged"
	top: ->
		mnt = moment @end
		midnight = moment(mnt).endOf "day"
		midnight.diff(mnt, "minutes") * pixelPerMinute

	height: ->
		duration = (new Date @end).getTime() - (new Date getStartOfEvent @).getTime()

		duration/60000 * pixelPerMinute

Template.eventList_oneEvent.events
	'click': ->
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

@Tools = 
	getPreferedStartOfDay: (dayMoment, userId=null) ->
		newMoment = moment dayMoment
		preference = UserSettings.get UserSettings.PROPERTY_START_OF_DAY, null, userId
		if preference?
			[hour, minute] = preference.split ":"
			if hour? and minute?
				return newMoment.set("hour", hour).set("minute", minute)
		return newMoment.startOf "day"
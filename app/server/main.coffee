
timeEntriesHandle = {}

Meteor.methods
	createOrUpdateEntry: (data, modifier, _id) ->
	
		userToken = UserSettings.get "controllrApiKey", null, @userId
		
		if _id?
			_id= parseInt _id, 10
			
			url = "http://controllr.panter.biz/api/entries/#{_id}.json?user_token=#{userToken}"
			HTTP.call "PUT", url,
				data: data
		else 
			url = "http://controllr.panter.biz/api/entries.json?user_token=#{userToken}"

			HTTP.call "POST", url,
				data: data
		
		timeEntriesHandle?.refresh()


	deleteTimeEntry: (data) ->
		userToken = UserSettings.get "controllrApiKey", null, @userId
		url = "http://controllr.panter.biz/api/entries/#{data._id}.json?user_token=#{userToken}"
		HTTP.call "DELETE", url


Meteor.startup ->

	handleIds = (data) ->
		_.map data, (item) ->
			item._id = item.id.toString()
			delete item.id
			item

	transformCalendarEvents = (data) ->

		_.map data, (item) ->

			start = new Date item.start.dateTime || item.start.date
			end = new Date item.end.dateTime || item.end.date
			_id: item.id.toString()
			start: start
			end: end
			bulletPoints: [item.summary]
			sources: ["Calendar"]

	transformRedmineIssues = (data) ->
	
		_.map data, (item) ->
			end = new Date item.updated_on
			
			_id: item.id.toString()
			end: end
			bulletPoints: [item.subject]
			sources: ["Redmine #{item.project.name}"]
		

	Meteor.publishArray 
		name: "calendarList"
		collection: "Calendars"
		refreshTime: 10000
		data: (params)->
			user =  Meteor.users.findOne _id: @userId
			if user?
				result = GoogleApi.get "calendar/v3/users/me/calendarList", user: user
				handleIds result.items

	Meteor.publishArray 
		name: "latestCalendarEvents"
		collection: "Events"
		refreshTime: 10000
		data: (params)->
			user =  Meteor.users.findOne _id: @userId
			if user?
				result = GoogleApi.get "calendar/v3/calendars/#{params.calendarId}/events", user: user, params: params
				filtered = _(result.items).filter (item) ->
					#check if its not a daily event
					# means: it has a datetime for start and end
					item.start.dateTime? and item.end.dateTime
				transformCalendarEvents filtered
	
	Meteor.publishArray 
		name: "redmineProjects"
		collection: "RedmineProjects"
		refreshTime: 10000
		data: (params)->

			return [] unless @userId?
			apiKey = UserSettings.get "redmineApiKey", null, @userId
			redmineUrl = UserSettings.get "redmineUrl", null, @userId

			return [] unless apiKey? and redmineUrl?
			url = "#{redmineUrl}/projects.json?key=#{apiKey}&limit=100"

			result = HTTP.get url
			return [] unless result?.data?.projects?

			handleIds result.data.projects

	Meteor.publishArray 
		name: "redmineIssues"
		collection: "Events"
		refreshTime: 10000
		data: (params)->
	
			return [] unless @userId?
			apiKey = UserSettings.get "redmineApiKey", null, @userId
			redmineUrl = UserSettings.get "redmineUrl", null, @userId

			return [] unless apiKey? and redmineUrl?

			url = "#{redmineUrl}/issues.json?key=#{apiKey}&project_id=#{params.project_id}&limit=200&assigned_to_id=me&updated_on=#{params.updated_on}"

			result = HTTP.get url

			return [] unless result?.data?.issues?

			transformRedmineIssues result.data.issues

	Meteor.publishArray 
		name: "githubEvents"
		collection: "Events"
		refreshTime: 10000
		data: (params)->

			return [] unless @userId?
			githubAccessToken = UserSettings.get "githubAccessToken", null, @userId
			githubUsername = UserSettings.get "githubUsername", null, @userId

			return [] unless githubAccessToken? and githubUsername?

			url = "https://api.github.com/users/#{githubUsername}/events?access_token=#{githubAccessToken}"


			result = HTTP.get url, headers: "User-Agent": "timetracking-app"
			return [] unless result?.data?

			events = []
			for item in result.data
				switch item.type
					when "PushEvent"
						bulletPoints = _(item?.payload?.commits).map (commit) -> "#{commit.message}"

						events.push 
							_id: item.id.toString()
							end: new Date item.created_at
							bulletPoints: bulletPoints
							sources: ["Github #{item.repo.name}"]
			events


	Meteor.publishArray 
		name: "projects"
		collection: "Projects"
		refreshTime: 10000
		data: (params)->
			userToken = UserSettings.get "controllrApiKey", null, @userId

			if userToken?
				result = HTTP.get "http://controllr.panter.biz/api/projects.json?user_token=#{userToken}&with_times=false&scope=active"
				if result.data?
					filtered = _(result.data).filter (project) ->
						project.active
					handleIds filtered

	Meteor.publishArray 
		refreshHandle: timeEntriesHandle
		name: "time_entries"
		collection: "TimeEntries"
		refreshTime: 10000
		data: (params)->
			shortnameQueryParam = ""
			userToken = UserSettings.get "controllrApiKey", null, @userId
			url = "http://controllr.panter.biz/api/entries.json?user_token=#{userToken}"

			for param in ["date_from", "date_to", "project_shortnames", "employee_usernames"]
				if _(params[param]).isArray()
					for value in params[param]
						url += "&#{param}[]=#{value}"
				else 
					url += "&#{param}="+params[param] if params[param]?

			result = HTTP.get url
			if result.data?
				_(result.data).map (entry) ->
					dayMoment = moment entry.day

					# start and end have only time on the controller
					createMoment = (dateString) ->
						[garbage, time] = dateString.split "T"
						[h,m,sWithTimeZone] = time.split ":" 
						aMoment = moment dayMoment
						aMoment.hour h
						aMoment.minute m
						aMoment.second 0
						aMoment
					if entry.start?
						startMoment = createMoment entry.start
					else 
						startMoment = dayMoment
					if entry.end?
						endMoment = createMoment entry.end
					else
						endMoment = moment(dayMoment).add entry.duration, "minutes"


					entry._id = entry.id.toString()
					delete entry.id
					entry.start = startMoment.toDate()
					entry.end = endMoment.toDate()
					

					entry

	Meteor.publishArray 
		name: "project_states"
		collection: "ProjectStates"
		refreshTime: 10000
		data: (params)->
			userToken = UserSettings.get "controllrApiKey", null, @userId
			
			result = HTTP.get "http://controllr.panter.biz/api/project_states.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data
	Meteor.publishArray 
		name: "allTasks"
		collection: "Tasks"
		refreshTime: 10000
		data: (params)->
			userToken = UserSettings.get "controllrApiKey", null, @userId
			
			result = HTTP.get "http://controllr.panter.biz/api/tasks.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data



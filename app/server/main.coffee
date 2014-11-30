
Meteor.methods
	"createOrUpdateEntry": (data)->
		userToken = UserSettings.get "controllrApiKey", null, @userId
		console.log data
		if data._id?
			HTTP.call "PUT", "http://controllr.panter.biz/api/entries.json?user_token=#{userToken}",
				data: data
		else
			HTTP.call "POST", "http://controllr.panter.biz/api/entries.json?user_token=#{userToken}",
				data: data




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
		

	Meteor.publishRestApi 
		name: "calendarList"
		collection: "Calendars"
		apiCall: (params)->
			user =  Meteor.users.findOne _id: @userId
			if user?
				result = GoogleApi.get "calendar/v3/users/me/calendarList", user: user
				handleIds result.items

	Meteor.publishRestApi 
		name: "latestCalendarEvents"
		collection: "Events"
		apiCall: (params)->
			user =  Meteor.users.findOne _id: @userId
			if user?
				result = GoogleApi.get "calendar/v3/calendars/#{params.calendarId}/events", user: user, params: params
				transformCalendarEvents result.items
	
	Meteor.publishRestApi 
		name: "redmineProjects"
		collection: "RedmineProjects"
		refreshTime: 10000
		apiCall: (params)->
		
			return [] unless @userId?
			apiKey = UserSettings.get "redmineApiKey", null, @userId
			redmineUrl = UserSettings.get "redmineUrl", null, @userId

			return [] unless apiKey? and redmineUrl?
			url = "#{redmineUrl}/projects.json?key=#{apiKey}"
			console.log url
			result = HTTP.get url
			return [] unless result?.data?.projects?
		
			handleIds result.data.projects

	Meteor.publishRestApi 
		name: "redmineIssues"
		collection: "Events"
		refreshTime: 10000
		apiCall: (params)->
	
			return [] unless @userId?
			apiKey = UserSettings.get "redmineApiKey", null, @userId
			redmineUrl = UserSettings.get "redmineUrl", null, @userId

			return [] unless apiKey? and redmineUrl?
				
			url = "#{redmineUrl}/issues.json?key=#{apiKey}&project_id=#{params.project_id}&limit=200&assigned_to_id=me&updated_on=#{params.updated_on}"

			result = HTTP.get url

			return [] unless result?.data?.issues?
			
			transformRedmineIssues result.data.issues

	Meteor.publishRestApi 
		name: "githubEvents"
		collection: "Events"
		refreshTime: 10000
		apiCall: (params)->
	
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
			
					
				
			
				

	Meteor.publishRestApi 
		name: "projects"
		collection: "Projects"
		refreshTime: 10000
		apiCall: (params)->
			userToken = UserSettings.get "controllrApiKey", null, @userId
			
			if userToken?
				result = HTTP.get "http://controllr.panter.biz/api/projects.json?user_token=#{userToken}"
				if result.data?
					handleIds result.data

	Meteor.publishRestApi 
		name: "time_entries"
		collection: "TimeEntries"
		apiCall: (params)->
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

					# start and end are wrong in the controllr
					# they have only the time and not the right day
					# also, they have a wrong timezone suffix
					fixDay = (aMoment) ->

						aMoment.year dayMoment.year()
						aMoment.month dayMoment.month()
						aMoment.date dayMoment.date()
						# currently, time zone is one hour shifted
						aMoment.subtract 1, "hours"
						aMoment
					if entry.start?
						startMoment = fixDay moment entry.start
					else 
						startMoment = dayMoment
					if entry.end?
						endMoment = fixDay moment entry.end
					else
						endMoment = moment(dayMoment).add entry.duration, "minutes"
					

					entry._id = entry.id.toString()
					entry.start = startMoment.toDate()
					entry.end = endMoment.toDate()
					

					entry

	Meteor.publishRestApi 
		name: "project_states"
		collection: "ProjectStates"
		apiCall: (params)->
			userToken = UserSettings.get "controllrApiKey", null, @userId
			
			result = HTTP.get "http://controllr.panter.biz/api/project_states.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data
	Meteor.publishRestApi 
		name: "allTasks"
		collection: "Tasks"
		apiCall: (params)->
			userToken = UserSettings.get "controllrApiKey", null, @userId
			
			result = HTTP.get "http://controllr.panter.biz/api/tasks.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data

	Meteor.publish "savedEvents", ->
		SavedEvents.find userId: @userId


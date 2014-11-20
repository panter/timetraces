userToken = "C_yxC5TvLpxzzNWjwhxk"
Meteor.methods
	"create.entry": (data)->
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
			source: "Calendar"

	transformRedmineIssues = (data) ->
	
		_.map data, (item) ->

			end = new Date item.updated_on
			
			_id: item.id.toString()
			end: end
			bulletPoints: [item.subject]
			source: "Redmine"
		

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
			apiKey = UserSettings.get UserSettings.PROPERTY_REDMINE_API_KEY, null, @userId
			return [] unless apiKey?
			url = "http://pm.panter.ch/projects.json?key=#{apiKey}"

			result = HTTP.get url
			return [] unless result?.data?.projects?
		
			handleIds result.data.projects

	Meteor.publishRestApi 
		name: "redmineIssues"
		collection: "Events"
		refreshTime: 10000
		apiCall: (params)->
	
			return [] unless @userId?
			apiKey = UserSettings.get UserSettings.PROPERTY_REDMINE_API_KEY, null, @userId
			return [] unless apiKey?
				
			url = "http://pm.panter.ch/issues.json?key=#{apiKey}&project_id=#{params.project_id}&limit=200&assigned_to_id=me&updated_on=#{params.updated_on}"

			result = HTTP.get url

			return [] unless result?.data?.issues?
			
			transformRedmineIssues result.data.issues
				

	Meteor.publishRestApi 
		name: "projects"
		collection: "Projects"
		refreshTime: 10000
		apiCall: (params)->
			result = HTTP.get "http://controllr.panter.biz/api/projects.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data


	Meteor.publishRestApi 
		name: "project_states"
		collection: "ProjectStates"
		apiCall: (params)->
			result = HTTP.get "http://controllr.panter.biz/api/project_states.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data
	Meteor.publishRestApi 
		name: "allTasks"
		collection: "Tasks"
		apiCall: (params)->
			result = HTTP.get "http://controllr.panter.biz/api/tasks.json?user_token=#{userToken}"
			if result.data?
				handleIds result.data

	Meteor.publish "savedEvents", ->
		SavedEvents.find userId: @userId


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

	Meteor.publishRestApi 
		name: "calendarList"
		collection: "Calendars"
		apiCall: (params)->
			user =  Meteor.users.findOne _id: @userId
			if user?
				result = GoogleApi.get 'calendar/v3/users/me/calendarList', user: user
				handleIds result.items
		
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


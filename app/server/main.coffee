userToken = "C_yxC5TvLpxzzNWjwhxk"
Meteor.methods
	"create.entry": (data)->
		HTTP.call "POST", "http://controllr.panter.biz/api/entries.json?user_token=#{userToken}",
			data: data


Meteor.startup ->

	apis = [{
				name: "projects"
				collection: Projects
				url: "http://controllr.panter.biz/api/projects.json?user_token=#{userToken}"
				publish: ->
					
					Projects.find {}, fields: _id: 1, description:1, shortname: 1, project_state_id: 1
			}
			
			{
				name: "tasks"
				collection: Tasks
				url: "http://controllr.panter.biz/api/tasks.json?user_token=#{userToken}"
				publish: (projectId) ->
					
					
					Tasks.find {project_id: parseInt(projectId,10)}
			}

			{
				name: "project_states"
				collection: ProjectStates
				url: "http://controllr.panter.biz/api/project_states.json?user_token=#{userToken}"
				publish: () ->
					ProjectStates.find()
			}
		]
	
	refreshData = (api) ->
		
		result= HTTP.get api.url
		for entry in result.data
			_id = entry.id.toString()
			delete entry.id
			api.collection.update {_id: _id}, {$set: entry}, upsert: true

	for api in apis
		do (api) ->
			Meteor.publish api.name, (data) ->
				console.log this
				Meteor.defer -> refreshData api
				api.publish.apply this, arguments

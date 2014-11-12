

Template.postForm.events
	'change .selectProject': (event) ->
		projectId = parseInt($(event.currentTarget).val(), 10)
		Session.set "currentProject", projectId

Template.projectsSelect.events
	'click .project-state': (event, template)->
		values = []
		template.$(".project-state:checked").each (index, input) ->
			values.push parseInt $(input).val(),10
		Session.set "selectedProjectStates", values

getFilteredProjects = ->
	projectStates = Session.get "selectedProjectStates"
	if not projectStates? or projectStates.length == 0
		selector = {}
	else
		selector = project_state_id: $in: projectStates
	Projects.find(selector, sort: shortname: 1)


Template.projectsSelect.helpers
	project_states: -> ProjectStates.find()
	
	projects: getFilteredProjects

###
	customers: ->
		_.uniq getFilteredProjects().map (project) ->
			project.shortname.split("-")[0]
###

Template.postForm.helpers

	projects: -> Projects.find()
	tasks: -> Tasks.find 
	taskIdOptions: -> 
		Tasks.find project_id: Session.get "currentProject"
		.map (task) ->
			label: task.name, value: task._id
	schema: -> new SimpleSchema
		user_id:
			type: Number
			label: "User ID"
		task_id: 
			type: Number
			label: "Task ID"
		description:
			type: String
			label: "Description"
		duration_hours:
			type: String
			label: "Duration"
		day:
			type: Date
			label: "Date"
		billable:
			type: Boolean
			label: "Billable"


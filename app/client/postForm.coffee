

AutoForm.hooks
	createOrUpdateTimeEntryForm: 
		after: createOrUpdateEntry: ->
			$("##{@formId}").closest ".modal"
			.modal "hide"

	
sanitizeTime = (date) ->
	moment(date).format "HH:mm"
			
sanitizeStartEndTime = (timeEntry) ->
	timeEntry.start = sanitizeTime timeEntry.start
	timeEntry.end = sanitizeTime timeEntry.end
	timeEntry


Template.postForm.helpers
	timeEntry: ->
		Session.set "currentProjectId", @timeEntry.project_id
		Session.set "currentTaskId", @timeEntry.task_id
		sanitizeStartEndTime @timeEntry
	billable: ->

		taskId = Session.get("currentTaskId")?.toString()
		projectId = Session.get("currentProjectId")
		billable_by_default = Tasks.findOne({_id: taskId, project_id: projectId})?.billable_by_default ? false

		return @timeEntry.billable ? billable_by_default


Template.postForm.events
	'change .projectId': (event, template) ->
		projectId =  parseInt $(event.currentTarget).val(),10
		Session.set "currentProjectId", projectId
	'change [name="task_id"]': (event) ->
		taskId =  parseInt $(event.currentTarget).val(),10
		Session.set "currentTaskId", taskId
	'click .btn-delete': (event, template) ->
		Meteor.call "deleteTimeEntry", template.data.timeEntry

Template.projectsSelect.events
	'click .project-state': (event, template)->
		values = []
		template.$(".project-state:checked").each (index, input) ->
			values.push parseInt $(input).val(),10
		Session.set "selectedProjectStates", values


###
getFilteredProjects = ->
	projectStates = Session.get "selectedProjectStates"
	if not projectStates? or projectStates.length == 0
		selector = {}
	else
		selector = project_state_id: $in: projectStates
	Projects.find(selector, sort: shortname: 1).map (project) ->
		project.


Template.projectsSelect.helpers
	project_states: -> ProjectStates.find()
	projects: getFilteredProjects


	customers: ->
		_.uniq getFilteredProjects().map (project) ->
			project.shortname.split("-")[0]
###



Template.postForm.helpers
	
	controllrIsSetUp: ->
		key = UserSettings.get "controllrApiKey"
		userID = UserSettings.get "controllrUserId"
		return userID? and key?
	projects: -> Projects.find({}, sort: shortname: 1).map (project) ->
		value: parseInt project._id, 10
		label: project.shortname+" "+project.description
	
	taskIdOptions: -> 
	
		Tasks.find project_id: Session.get "currentProjectId"
		.map (task) ->
			label: task.name, 
			value: parseInt task._id,10

	schema: -> 
		
		
		new SimpleSchema
			_id: 
				type: String
				label: "ID"
				optional: yes
			user_id:
				type: Number
				label: "User ID"
			task_id: 
				type: Number
				label: "Task ID"
			project_id: 
				type: Number
				label: "Project ID"
				
			description:
				type: String
				label: "Description"
			duration_hours:
				type: String
				label: "Duration"
				optional: yes
			start: 
				type: String
				label: "Start"
			end:
				type: String
				label: "End"
			day:
				type: Date
				label: "Date"
			billable:
				type: Boolean
				label: "Billable"


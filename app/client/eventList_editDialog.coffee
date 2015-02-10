

AutoForm.hooks
	createOrUpdateTimeEntryForm: 

		after: createOrUpdateEntry: (doc)->
			$("##{@formId}").closest ".modal"
			.modal "hide"
			return doc # success


getCurrentTimeEntry = ->
	timeEntry = Session.get "timeEntryToEdit"
	if timeEntry?
		Session.set "currentProjectId", timeEntry.project_id
		Session.set "currentTaskId", timeEntry.task_id
	timeEntry

Template.eventList_editDialog.helpers
	footerButtons: ->
		timeEntry = getCurrentTimeEntry()
		if not timeEntry? or timeEntry.new
			[
				(class: "btn btn-primary", label: "Insert", type: "submit")
			]
		else
			[
				(class: "btn btn-delete btn-danger", label: "Delete")
				(class: "btn btn-primary", label: "Update", type: "submit")
				
			]

	title: ->
		timeEntry = getCurrentTimeEntry()
		if not timeEntry? or timeEntry.new
			"new Time Entry"
		else
			"Edit Entry #{timeEntry._id}"

	timeEntry: getCurrentTimeEntry

	billable: ->
		if @timeEntry?.billable?
			@timeEntry.billable
		else
			taskId = Session.get("currentTaskId")?.toString()
			projectId = Session.get("currentProjectId")

			billable_by_default = Tasks.findOne({_id: taskId, project_id: projectId})?.billable_by_default ? false

			return billable_by_default

	controllrIsSetUp: ->
		key = UserSettings.get "controllrApiKey"
		userID = UserSettings.get "controllrUserId"
		return userID? and key?

	projects: -> 
		Projects.find({}, sort: shortname: 1).map (project) ->
			value: parseInt project._id, 10
			label: project.shortname+" "+project.description
	
	taskIdOptions: -> 
		Tasks.find project_id: Session.get("currentProjectId") ? @timeEntry?.project_id
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


Template.eventList_editDialog.events
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



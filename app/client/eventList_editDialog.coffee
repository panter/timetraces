

AutoForm.hooks
	createOrUpdateTimeEntryForm: 
		after: 
			method: (error, result)->
				if error?
					alert error
				else if @formAttributes.meteormethod is "createTimeEntry"
					$("##{@formId}").closest ".modal"
					.modal "hide"
					return result # success
			"method-update": (error, result)->
				if error?
					alert error

				else if @formAttributes.meteormethod is "updateTimeEntry"
					$("##{@formId}").closest ".modal"
					.modal "hide"
					return result # success


getCurrentTimeEntry = ->
	Session.get "timeEntryToEdit"


Template.eventList_editDialog.helpers
	formType: ->
		if getCurrentTimeEntry()?.new then "method" else "method-update"
	method: ->
		if getCurrentTimeEntry()?.new then "createTimeEntry" else "updateTimeEntry"

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
			taskId = Session.get("currentTaskId")
			projectId = Session.get("currentProjectId")

			billable_by_default = Tasks.findOne({_id: taskId, project_id: projectId})?.billable_by_default ? false

			return billable_by_default

	controllrIsSetUp: ->
		key = UserSettings.get "controllrApiKey"
		userID = UserSettings.get "controllrUserId"
		return userID? and key?

	projects: -> 
		Projects.find({}, sort: shortname: 1).map (project) ->
			value: project._id
			label: project.shortname+" "+project.description
	
	taskIdOptions: -> 
		timeEntry = getCurrentTimeEntry()

		options = Tasks.find project_id: Session.get("currentProjectId") ? timeEntry?.project_id
		.map (task) ->
			label: task.name
			value: task._id
	
		return options

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
		projectId =  $(event.currentTarget).val()
		if projectId? and projectId.length > 0
			Session.set "currentProjectId", projectId
	'change [name="task_id"]': (event) ->
		
		if $(event.currentTarget).val()?.length > 0
			taskId =  $(event.currentTarget).val()
			Session.set "currentTaskId", taskId
	'click .btn-delete': (event, template) ->
		Meteor.call "deleteTimeEntry", template.data.timeEntry





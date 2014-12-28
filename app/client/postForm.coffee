

	
sanitizeTime = (date) ->
	moment(date).format "HH:mm"

Router.route 'editTimeEntry',
	path: "timeEntry/:timeEntryId"
	template: "postForm"
	waitOn: share.defaultSubscriptions
	data: ->

		timeEntry = TimeEntries.findOne @params.timeEntryId
		if timeEntry?
			timeEntry.start = sanitizeTime timeEntry.start
			timeEntry.end = sanitizeTime timeEntry.end
			Session.set "currentProjectId", timeEntry.project_id
			timeEntry: timeEntry
			new: false


findTaskID = (event) ->

	sourceTaskMap = 
		redmine: "Development"
		github: "Development"
		calendar: "Customer Meeting"


	for keyword, taskName of sourceTaskMap
		if event?.sources?.join(" ").toLowerCase().indexOf(keyword) >= 0
			task = Tasks.findOne project_id: Session.get("currentProjectId"), name: taskName
			return parseInt task._id, 10 if task?


Router.route 'newTimeEntry',
	path: "timeEntry"
	template: "postForm"
	waitOn: share.defaultSubscriptions
	data: ->
		currentEvent = Session.get "currentEvent"
		# find possible project
		if currentEvent?

			if currentEvent.project?._id?
				Session.set "currentProjectId", parseInt currentEvent.project._id, 10
			taskId = findTaskID currentEvent


			timeEntry: 
				description: currentEvent?.bulletPoints?.map((point) -> "- #{point}").join "\n"
				project_id: Session.get "currentProjectId"
				task_id: taskId
				billable: currentEvent.billable
				user_id: UserSettings.get "controllrUserId"
				start: sanitizeTime currentEvent?.start
				end: sanitizeTime currentEvent?.end
				day: moment(currentEvent?.start).toDate()
			new: true


AutoForm.hooks
	createOrUpdateTimeEntryForm: 
		after: createOrUpdateEntry: ->
			window.history.back()

Template.postForm.events
	'change .projectId': (event, template) ->
		projectId =  parseInt $(event.currentTarget).val(),10
		Session.set "currentProjectId", projectId
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
		label: project.shortname
	
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


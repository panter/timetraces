subscriptions = -> [
			Meteor.subscribe "projects"
			Meteor.subscribe "project_states"
			Meteor.subscribe "allTasks"
			Meteor.subscribe "time_entries",
				employee_usernames: UserSettings.get "controllrUsername"
				date_from: moment().startOf("day").subtract(UserSettings.get("numberOfWeeks", 2), "weeks").format()
		
		]

sanitizeTime = (date) ->
	moment(date).format "HH:mm"

Router.route 'editTimeEntry',
	path: "timeEntry/:timeEntryId"
	template: "postForm"
	subscriptions: subscriptions
	data: ->
		if @ready()
			timeEntry = TimeEntries.findOne @params.timeEntryId
			timeEntry.start = sanitizeTime timeEntry.start
			timeEntry.end = sanitizeTime timeEntry.end
			Session.set "currentProjectId", timeEntry.project_id
			timeEntry: timeEntry
			new: false

findProject = (event) ->
	traces = [event?.source]
	traces = traces.concat event?.bulletPoints
	console.log traces
	for trace in traces
		for word in trace.split /[\s/]+/
			project = Projects.findOne shortname: word
			return project if project?
findTaskID = (event) ->

	sourceTaskMap = 
		redmine: "Development"
		github: "Development"
		calendar: "Customer Meeting"


	for keyword, taskName of sourceTaskMap
		if event?.source?.toLowerCase().indexOf(keyword) >= 0
			task = Tasks.findOne project_id: Session.get("currentProjectId"), name: taskName
			return parseInt task._id, 10 if task?


Router.route 'newTimeEntry',
	path: "timeEntry"
	template: "postForm"
	subscriptions: subscriptions
	data: ->
		currentEvent = Session.get "currentEvent"
		# find possible project
		if currentEvent?
			project = findProject currentEvent
			if project?
				Session.set "currentProjectId", parseInt project._id, 10
			taskId = findTaskID currentEvent


		timeEntry: 
			description: currentEvent?.bulletPoints?.map((point) -> "- #{point}").join "\n"
			project_id: Session.get "currentProjectId"
			task_id: taskId
			user_id: UserSettings.get "redmineUserId"
			start: sanitizeTime currentEvent?.start
			end: sanitizeTime currentEvent?.end
			day: moment(currentEvent?.start).toDate()
		new: true

Template.postForm.rendered = ->
	AutoForm.hooks
		onError: (operation, error) ->
			console.log operation, error

		

Template.postForm.events
	'change .projectId': (event, template) ->
		Session.set "currentProjectId", projectId

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
	

	projects: -> Projects.find().map (project) ->
		value: parseInt project._id, 10
		label: project.shortname
	
	taskIdOptions: -> 
	
		Tasks.find project_id: Session.get "currentProjectId"
		.map (task) ->
			label: task.name, 
			value: parseInt task._id,10

	schema: -> 
		
		
		new SimpleSchema
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
				optional: true
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


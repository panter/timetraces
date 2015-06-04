store = new Meteor.Collection "userPreferences"
@UserSettingsStore = store
store.attachSchema new SimpleSchema
	_id: 
		type: String
	minimumMergeTime:
		type: Number
		label: "Minimum Merge Time (minutes)"
		optional: true
	startOfDay:
		type: String
		label: "Start of Day"
		optional: true
	numberOfDays:
		type: Number
		label: "Number of Days to show"
		optional: true
	projectMap:
		type: [Object]
	"projectMap.$.keyword":
		label: "Keyword"
		type: String
	"projectMap.$.projectId":
		label: "Project"
		type: String
		autoform:
			type: "select2"
			options: ->
				Projects.find().map (doc) -> 
					label: "#{doc.shortname} #{doc.description}"
					value: doc._id



	calendars:
		type: [String]
		label: "Calendars"
		optional: true
	sourceEnabled_calendar:
		type: Boolean
		label: "Calendar events enabled"
		defaultValue: yes
	sourceEnabled_redmine:
		type: Boolean
		label: "Redmine enabled"
		defaultValue: yes
	redmineProjects:
		type: [String]
		label: "RedmineProjects"
		optional: true
	redmineApiKey: 
		type: String
		label: "redmineApiKey"
		optional: true
	redmineUrl: 
		type: String
		label: "redmine URL"
		optional: true
	eventListViewMode:
		type: String
		label: "Event List Mode"
		optional: true
		allowedValues: ['calendar', 'list']
	
		autoform: 
			options: [
				{label: "List", value: "list"}
				{label: "Calendar", value: "calendar"}
				]

	controllrUserId: 
		type: String
		label: "Controllr User ID"
		optional: true
	controllrUsername: 
		type: String
		label: "Controllr User Name"
		optional: true
	controllrApiKey:
		type: String
		label: "Controllr Api Key"
		optional: true
	sourceEnabled_github:
		type: Boolean
		label: "Github enabled"
		defaultValue: yes
	githubAccessToken:
		type: String
		label: "Github Access Token"
		optional: true
	githubUsername:
		type: String
		label: "Github Username"
		optional: true
	sourceEnabled_location:
		type: Boolean
		label: "Locations enabled"
		defaultValue: yes
	locationServiceUser:
		type: Object
		blackbox: yes
		optional: yes
	locationServiceMinDistance:
		type: Number
		optional: yes

	

if Meteor.isClient
	Meteor.subscribe "userPreferences"
if Meteor.isServer
	Meteor.publish "userPreferences", ->
		if @userId?
			unless store.findOne(@userId)?
				store.insert _id: @userId
			store.find @userId






@UserSettings = 
	PROPERTY_CALENDARS: "calendars"
	PROPERTY_REDMINE_PROJECTS: "redmineProjects"
	PROPERTY_REDMINE_API_KEY: "redmineApiKey"
	PROPERTY_START_OF_DAY: "startOfDay"
	PROPERTY_EVENT_VIEW_MODE: "eventListViewMode"
	PROPERTY_MINIMUM_MERGE_TIME: "minimumMergeTime"
	PROPERTY_CONTROLLR_USERNAME: "controllrUsername"
	getListSetting: (property, userId=null)-> 
		 @get property, [], userId
	get: (property, defaultVal = null, userId = null) ->
		fullProperty = "#{property}"
		fields = {}
		fields[fullProperty] = 1

		unless userId?
			userId = Meteor.userId() # on server Metoer.userId() does not work here
		user = store.findOne(userId, fields: fields) 
		user?[property] || defaultVal
		#user?.profile?[property] || defaultVal


	hasListSetting: (property, id, userId=null) ->
		@getListSetting(property, userId)?.indexOf(id) >=0
	set: (property, value) ->
		fullProperty = "#{property}"
		$set = {}
		$set[fullProperty] = value
		unless store.findOne(Meteor.userId())? 
			store.insert _id: Meteor.userId()
		store.update Meteor.userId(), {$set: $set}

	observeChanges: (property, callbacks) ->
		selector = {}
		selector[property] = $exists: yes
		fields = {}
		fields[property] = 1
		store.find(selector, fields: fields).observeChanges callbacks





		
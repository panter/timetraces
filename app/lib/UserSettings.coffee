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
	numberOfWeeks:
		type: Number
		label: "Number of Weeks to show"
		optional: true
	calendars:
		type: [String]
		label: "Calendars"
		optional: true
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

	githubAccessToken:
		type: String
		label: "Github Access Token"
		optional: true
	githubUsername:
		type: String
		label: "Github Username"
		optional: true

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
	
		store.update Meteor.userId(), {$set: $set}, upsert: true






		
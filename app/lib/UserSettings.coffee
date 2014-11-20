store = new Meteor.Collection "userPreferences"

if Meteor.isClient
	Meteor.subscribe "userPreferences"
if Meteor.isServer
	Meteor.publish "userPreferences", ->
		store.find @userId

@UserSettings = 
	PROPERTY_CALENDARS: "calendars"
	PROPERTY_REDMINE_PROJECTS: "redmineProjects"
	PROPERTY_REDMINE_API_KEY: "redmineApiKey"
	PROPERTY_START_OF_DAY: "startOfDay"
	PROPERTY_EVENT_VIEW_MODE: "eventListViewMode"
	PROPERTY_MINIMUM_MERGE_TIME: "minimumMergeTime"
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
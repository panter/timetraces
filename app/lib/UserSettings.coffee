@UserSettings = 
	PROPERTY_CALENDARS: "calendars"
	PROPERTY_REDMINE_PROJECTS: "redmineProjects"
	PROPERTY_REDMINE_API_KEY: "redmineApiKey"
	PROPERTY_START_OF_DAY: "startOfDay"
	getListSetting: (property, user=null)-> 
		 @get property, [], user
	get: (property, defaultVal = null, user = null) ->
		user = Meteor.user() unless user? # serverside you cant use Meteor.user() if not in Meteor.method
		user?.profile?[property] || defaultVal


	hasListSetting: (property, id, user=null) ->
		@getListSetting(property, user)?.indexOf(id) >=0
	set: (property, value) ->
		fullProperty = "profile.#{property}"
		$set = {}
		$set[fullProperty] = value
		Meteor.users.update {_id: Meteor.userId()}, $set: $set
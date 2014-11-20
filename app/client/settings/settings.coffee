
checkboxSaveEvent = (property) ->
	(event, template) ->
		usedProps = []
		template.$("input[type='checkbox']").each (index, input) ->
			$input = $ input
			if $input.is ":checked"
				usedProps.push $input.val()
		UserSettings.set property, usedProps



Template.settings_general.helpers
	startOfDay: -> UserSettings.get UserSettings.PROPERTY_START_OF_DAY
	minimumMergeTime:  -> UserSettings.get UserSettings.PROPERTY_MINIMUM_MERGE_TIME
	viewMode: -> UserSettings.get UserSettings.PROPERTY_EVENT_VIEW_MODE
Template.settings_general.events
	'change .start-of-day': (event) ->
		UserSettings.set UserSettings.PROPERTY_START_OF_DAY, $(event.currentTarget).val()
	'change .minimum-merge-time': (event) ->
		UserSettings.set UserSettings.PROPERTY_MINIMUM_MERGE_TIME, $(event.currentTarget).val()
	'change .view-mode': (event) ->
		UserSettings.set UserSettings.PROPERTY_EVENT_VIEW_MODE, $(event.currentTarget).val()
	
Template.settings_calendarList.helpers
	calendars: ->
		Calendars.find()
	isUsed: (id) -> UserSettings.hasListSetting UserSettings.PROPERTY_CALENDARS, id

Template.settings_calendarList.events
	'click input': checkboxSaveEvent UserSettings.PROPERTY_CALENDARS

Template.settings_redmine.helpers
	apiKey: -> UserSettings.get UserSettings.PROPERTY_REDMINE_API_KEY
	projects: ->
		RedmineProjects.find()
	isUsed: (id) -> UserSettings.hasListSetting UserSettings.PROPERTY_REDMINE_PROJECTS, id


Template.settings_redmine.events
	'click input[type="checkbox"]': checkboxSaveEvent UserSettings.PROPERTY_REDMINE_PROJECTS
	'change .apiKey': (event, template)->
		apiKey = $(event.currentTarget).val()
		UserSettings.set UserSettings.PROPERTY_REDMINE_API_KEY, apiKey

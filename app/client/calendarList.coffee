

Template.calendarList.helpers
	calendars: ->
		Calendars.find()
	isUsed: (id)-> 
		Meteor.user()?.profile?.usedCalendars?.indexOf(id) >=0
Template.calendarList.events
	'click input': (event, template) ->
		usedCalendars = []
		template.$("input").each (index, input) ->
			$input = $ input
			if $input.is ":checked"
				usedCalendars.push $input.val()
	
		Meteor.users.update {_id: Meteor.userId()}, $set: "profile.usedCalendars": usedCalendars
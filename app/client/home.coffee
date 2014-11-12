Template.homeNavigation.helpers
	routes: ->
		_.map Router.routes, (route) -> route.getName()

		
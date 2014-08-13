class GitDashboardMainView extends KDView

  constructor:(options = {}, data)->
    options.cssClass = 'GitDashboard main-view'
    super options, data

  viewAppended:->
    @addSubView new KDView
      partial  : "Welcome to Git Dashboard app!"
      cssClass : "welcome-view"

class GitDashboardController extends AppController

  constructor:(options = {}, data)->
    options.view    = new GitDashboardMainView
    options.appInfo =
      name : "Git Dashboard"
      type : "application"

    super options, data

do ->

  # In live mode you can add your App view to window's appView
  if appView?
    view = new GitDashboardMainView
    appView.addSubView view

  else
    KD.registerAppClass GitDashboardController,
      name     : "Gitdashboard"
      routes   :
        "/:name?/Gitdashboard" : null
        "/:name?/alexchistyakov/Apps/Gitdashboard" : null
      dockPath : "/alexchistyakov/Apps/Gitdashboard"
      behavior : "application"
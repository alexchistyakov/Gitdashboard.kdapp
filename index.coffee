class GitDashboardController extends AppController

  constructor:(options = {}, data)->
    
    options.view    = new GitDashboardMainView
    options.appInfo =
      name : "Git Dashboard"
      type : "application"

    super options, data

do ->
  OAuth.initialize "D6R6uhEmh7kmXCVT9YzSwvHP-tk"  
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
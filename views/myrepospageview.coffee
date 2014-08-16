class GitDashboardMyReposPageView extends KDView
  constructor:(options = {}, data)->
    @controller = new RepoDataController
    @authToken = options.authToken
    unless @authToken?
        throw new Error "No authentication token provided"
    options.cssClass = 'Gitdashboard'
    super options, data

  viewAppended:->
    @addSubView @container = new KDListView
        cssClass:"container"
    @controller.getMyRepos @repoReceived,@authToken
  repoReceived: (repoView) =>
    @container.addSubView repoView
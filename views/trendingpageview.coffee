class GitDashboardTrendingPageView extends KDView

  constructor:(options = {}, data)->
    @controller = new RepoDataController
    options.cssClass = 'Gitdashboard'
    super options, data

  viewAppended:->
    @addSubView @container = new KDListView
        cssClass:"container"
    @controller.getTrendingRepos(@repoReceived)
  repoReceived: (repoView) =>
    @container.addSubView repoView
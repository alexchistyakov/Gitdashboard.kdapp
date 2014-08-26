class GitDashboardTrendingPageView extends KDView

  constructor:(options = {}, data)->
    @controller = options.dataController
    options.cssClass = 'Gitdashboard'
    super options, data
    @controller.on "path-checked",@bound "beginLoad"

  viewAppended:->
    @addSubView @container = new KDListView
        cssClass:"container"
    @addSubView new KDLoaderView
        showLoader: true
  beginLoad: =>
      @container.empty()
      @controller.getTrendingRepos(@repoReceived)
  repoReceived: (repoView) =>
    @container.addSubView repoView
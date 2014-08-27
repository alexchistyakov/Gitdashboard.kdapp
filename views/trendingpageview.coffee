class GitDashboardTrendingPageView extends KDView

  constructor:(options = {}, data)->
    @controller = options.dataController
    options.cssClass = 'Gitdashboard'
    super options, data
    @controller.on "path-checked",@bound "beginLoad"
    @controller.on "trending-page-downloaded", @bound "hideLoader"
  viewAppended:->
    @addSubView @container = new KDListView
        cssClass:"container"
    @addSubView @loader = new KDLoaderView
        showLoader: true
  beginLoad: ->
      console.log "POST PATH CHECKED"
      @controller.getTrendingRepos(@repoReceived)
  repoReceived: (repoView) =>
    @container.addSubView repoView
  hideLoader: ->
      @loader.hide()
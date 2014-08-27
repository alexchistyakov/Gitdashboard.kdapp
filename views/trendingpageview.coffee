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
        
    @addSubView @searchBox = new KDInputView
      cssClass: "searchBox"
      placeholder: "Search..."

    @searchBox.on 'keydown', (e) =>
      if e.keyCode is 13
        @container.empty()
        @controller.getSearchedRepos(@repoReceived, @searchBox.getValue())
        $(".returnToTrendingPageButton").animate(opacity: 1)

    @addSubView @returnToTrendingPageButton = new KDButtonView
      title: "Return to Trending Page"
      cssClass: "returnToTrendingPageButton clean-gray"
      callback: =>
        $(".returnToTrendingPageButton").animate(opacity: 0)
        @container.empty()
        @controller.getTrendingRepos(@repoReceived)
  
  beginLoad: ->
      console.log "POST PATH CHECKED"
      @controller.getTrendingRepos(@repoReceived)
  
  repoReceived: (repoView) =>
    @container.addSubView repoView
  
  hideLoader: ->
      @loader.hide()
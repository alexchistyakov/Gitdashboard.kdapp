class GitDashboardTrendingPageView extends KDView

  constructor:(options = {}, data)->
    @controller = new RepoDataController
    options.cssClass = 'Gitdashboard'
    super options, data

  viewAppended:->     
    @container = new KDListView
      cssClass:"container"

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

    @addSubView @container
    @controller.getTrendingRepos(@repoReceived)
  repoReceived: (repoView) =>
    @container.addItemView repoView
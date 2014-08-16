class GitDashboardMainView extends KDView
    constructor:(options = {}, data)->
        options.cssClass = 'GitDashboard'
        super options, data
    viewAppended: ->
        
        @addSubView @loginButton = new KDButtonView
            cssClass: "login-button"
            title: "Connect with GitHub"
            callback: @oauthAuthentication
        @addSubView @tabView = new KDTabView
            cssClass:"tab-view"
        @tabView.getTabHandleContainer().setClass "handle-container"
        @tabView.addPane @trendingPagePane = new KDTabPaneView
            title: "Trending"
        @trendingPagePane.setMainView new GitDashboardTrendingPageView
        
        handle.setClass "handle" for handle in @tabView.handles
        
        if OAuth.create("github") is not false
            @initPersonal()
    oauthAuthentication: =>
        callback = @initPersonal
        OAuth.popup("github",options={cache: true})
        .done (result) ->
            callback()
        .fail (err) ->
            console.log err
    initPersonal: =>
        @tabView.addPane @myReposPagePane = new KDTabPaneView
            title: "My Repos"
        @myReposPagePane.setMainView new GitDashboardMyReposPageView
            authToken: OAuth.create("github")
        @loginButton.hide()
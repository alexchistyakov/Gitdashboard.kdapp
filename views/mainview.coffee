class GitDashboardMainView extends KDView
    constructor:(options = {}, data)->
        options.cssClass = 'GitDashboard'
        super options, data
        @kiteHelper = new KiteHelper
        @controller = new RepoDataController
            kiteHelper: @kiteHelper
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
            dataController: @controller
            
        handle.setClass "handle" for handle in @tabView.handles
        
        @addSubView @vmSelector = new VMSelectorView
            callback: @switchVM
            kiteHelper: @kiteHelper
            cssClass: "vm-selector"

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
            dataController: @controller
        @loginButton.hide()
    switchVm: (vm) =>
        @overlay = new KDOverlayView if not @overlay?
            isRemovable: false
            color: "#000"
            container: @
        @kiteHelper.getKite().then (kite) =>
             @overlay.remove()
             delete @overlay
        .catch (err) => 
            @vmSelector.tunOffVmModal()

class GitDashboardMainView extends KDView
    constructor:(options = {}, data)->
        options.cssClass = 'GitDashboard'
        super options, data
        @kiteHelper = new KiteHelper
        @controller = new RepoDataController
            kiteHelper: @kiteHelper

    viewAppended: =>
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
            callback: @switchVm
            kiteHelper: @kiteHelper
            cssClass: "vm-selector"

        if OAuth.create("github") is not false
            @initPersonal()
            
    oauthAuthentication: =>
        OAuth.popup "github", cache: true
        .done (result) =>
            @initPersonal()
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
        @kiteHelper.getKite().then (kite) =>
             @overlay.remove()
             delete @overlay
        .catch (err) => 
            @vmSelector.turnOffVmModal(vm)

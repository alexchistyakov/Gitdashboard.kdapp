class GitDashboardMainView extends KDView
    constructor:(options = {}, data)->
        options.cssClass = 'GitDashboard'
        super options, data
        @kiteHelper = new KiteHelper
        window.kh = @kiteHelper
        @dataManager = new RepoDataManager
            kiteHelper: @kiteHelper
        window.dm = @dataManager
        @controller = new RepoDataController
            dataManager: @dataManager
        @controller.on "tab-open-request", @bound "openConsoleTab"
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
            closable: false
        @tabView.addPane @searchPagePane = new KDTabPaneView
            title: "Search"
            closable: false
        @searchPagePane.setMainView new GitdashboardSearchPaneView
            controller: @controller
        @trendingPagePane.setMainView new GitDashboardTrendingPageView
            dataController: @controller
        @tabView.showPane @trendingPagePane
        handle.setClass "handle" for handle in @tabView.handles
        
        @addSubView @vmSelector = new VMSelectorView
            callback: @switchVm
            kiteHelper: @kiteHelper
            container: @
            cssClass: "vm-selector"

        if token = OAuth.create("github") is not false
            @initPersonal token
            
    oauthAuthentication: =>
        OAuth.popup("github", cache: true)
        .done (result) =>
            @initPersonal result
        .fail (err) ->
            console.log err

    initPersonal: (token)=>
        @tabView.addPane @myReposPagePane = new KDTabPaneView
            title: "My Repos"
            closable: false
        @myReposPagePane.setMainView new GitDashboardMyReposPageView
            authToken: token
            dataController: @controller
        @loginButton.hide()
        @dataManager.token = token
        @dataManager.checkSSHKeys().then (exist) =>
            if not exist
                container = new KDView
                    partial: "No SSH keys were found on your VM. They are needed to clone private repositories. Would you like us to generate and add them for you?"
                container.addSubView new KDButtonView
                    title: "Sure"
                    cssClass: "cupid-green"
                    callback: =>
                        modal.destroy()
                        OAuth.create("github").me().then (me) =>
                            container = new KDView
                                partial: "Please enter a passphrase for your SSH keys and press enter. If you do not want to set a passphrase, leave the field empty"
                            container.addSubView input = new KDInputView
                                placeholder: "Passphrase"
                                type: "password"
                            input.on 'keydown', (e) =>
                                if e.keyCode is 13
                                    @dataManager.generateSSHKeys(me.email,input.getValue() if input.getValue()).then =>
                                        @dataManager.postSSHKey(@kiteHelper.getVm()).then =>
                                            modal.destroy()
                            modal = new KDModalView
                                title: "SSH keys not found"
                                overlay         : yes
                                overlayClick    : no
                                width           : 400
                                height          : "auto"
                                cssClass        : "new-kdmodal"
                                view            : container
                container.addSubView new KDButtonView
                    title: "No thanks"
                    cssClass: "small-gray"
                    callback: =>
                        modal.destroy()
                modal = new KDModalView
                    title: "SSH keys not found"
                    overlay         : yes
                    overlayClick    : no
                    width           : 400
                    height          : "auto"
                    cssClass        : "new-kdmodal"
                    view            : container
            else
                @dataManager.compareSSHKeys (exists) =>
                    unless exists
                        container = new KDView
                            partial: "Your SSH keys are not on GitHub. You will not be able to clone private repos. Would you like us to add them for you?"
                        container.addSubView new KDButtonView
                            title: "Sure"
                            cssClass: "cupid-green"
                            callback: =>
                                modal.destroy()
                                @dataManager.postSSHKey(@kiteHelper.getVm())
                        container.addSubView new KDButtonView
                            title: "No thanks"
                            cssClass: "small-gray"
                            callback: =>
                                modal.destroy()
                        modal = new KDModalView
                            title: "SSH keys not on GitHub"
                            overlay         : yes
                            overlayClick    : no
                            width           : 400
                            height          : "auto"
                            cssClass        : "new-kdmodal"
                            view            : container
    switchVm: (vm) =>
        @kiteHelper.getKite().then (kite) =>
             @overlay.remove()
             delete @overlay
        .catch (err) => 
            @vmSelector.turnOffVmModal(vm)
    openConsoleTab: (repoView) =>
        KD.singletons.appManager.require 'Terminal', =>
            @tabView.addPane @terminalPaneTab = new KDTabPaneView
                title: repoView.getOptions().name
                cssClass: "terminal-pane"
                closable: true
            @terminalPaneTab.setMainView @terminal = new TerminalPane
                cssClass: "terminal"
            window.test = @terminal
            $(window).trigger("resize")
            @terminal.runCommand "clear"
            @terminal.runCommand "cd #{repoView.openDir}"
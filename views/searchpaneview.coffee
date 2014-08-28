class GitdashboardSearchPaneView extends KDView
    constructor: (options = {},data) ->
        super options,data
        @controller = options.controller
        @controller.on "search-results-downloaded",@bound "hideLoader"
        @loading = false
        
    viewAppended: =>
        @addSubView @searchBox = new KDInputView
            cssClass: "searchBox"
            placeholder: "Search..."
        @searchBox.on 'keydown', (e) =>
          if e.keyCode is 13
            if not loading or not Boolean(@searchBox.getValue())
                loading = true
                @loader.show()
                @container.empty()
                @controller.getSearchedRepos(@repoReceived, @searchBox.getValue())
        @addSubView @loader = new KDLoaderView
            showLoader: false;
        @addSubView @container = new KDListView
            cssClass: "container"
    repoReceived: (repoView) =>
        if repoView is false
            @container.empty()
            @hideLoader()
            @container.addItemView new KDView
                partial: "Woah, slow down. Github can't handle that many search requests. Try again in a minute"
            loading = false
        else
            @container.addItemView repoView
    hideLoader: =>
        loading = false
        @loader.hide()
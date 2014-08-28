class RepoView extends KDListItemView
    constructor: (options={},data) ->
        options.name        or= "Dummy Name"
        options.user        or= "user"
        options.description or= "Description goes here"
        options.authorGravatarUrl or= ""
        options.cloneUrl    or= null
        options.stars       or= 0
        options.language    or= "Language"
        options.cssClass      = KD.utils.curry "repoview-container", options.cssClass
        options.url         or= ""
        options.sshCloneUrl or= null
        @state                = NOT_CLONED
        @openDir              = "/"
        @controller           = options.controller
        if options.description.length > maxSymbolsInDescription
            options.description = options.description.substring(0,maxSymbolsInDescription)+"..."
        else
            options.description
        super options,data
    viewAppended: ->
        {user,name,description,authorGravatarUrl,stars,language} = @getOptions()

        @addSubView new KDCustomHTMLView
            tagName: "img"
            cssClass: "gravatar"
            size:
                width: 40
                height: 40
            attributes:
                src: authorGravatarUrl

        @addSubView new KDLabelView
            title: "#{user}/#{name}"
            cssClass: "name"

        @addSubView new KDLabelView
            title: stars
            cssClass: "starsLabel"

        @addSubView new KDLabelView
            title: language
            cssClass: "languageLabel"

        @addSubView new KDCustomHTMLView
            tagName: "div"
            cssClass: "description"
            partial: description

        @addSubView @cloneButton = new KDButtonView
        @state = LOADING
        @updateView()
        @updateState()
    cloneToMachine: =>
        new GitdashboardCloneModal
            repoView: @
            cloneUrl: @getOptions().cloneUrl
            dataManager: @controller.dataManager

    click:(event) ->
        {url} = @getOptions()
        window.open url,"_blank"
        
    updateState: =>
        {name} = @getOptions()
        if @controller.dataManager.repositoryIsListed name
            @state = CLONED
            @openDir = @controller.dataManager.getRepoDirectory name
        else
            @state = NOT_CLONED
        @updateView()
    updateView: =>
        @cloneButton.enable()
        @cloneButton.unsetClass "state-cloned"
        @cloneButton.unsetClass "state-uncloned"
        @cloneButton.unsetClass "state-cloning"
        @cloneButton.unsetClass "state-loading"
        @cloneButton.setClass "clone-button"
        @cloneButton.setCallback undefined
        @cloneButton.hideLoader()
        if @state is CLONED
            @cloneButton.setClass "state-cloned"
            @cloneButton.setTitle "Open"
            @cloneButton.setCallback =>
                @controller.createTab @
        else if @state is NOT_CLONED
            @cloneButton.setTitle "Clone"
            @cloneButton.setCallback @cloneToMachine
            @cloneButton.setClass "state-uncloned"
        else if @state is CLONING
            @cloneButton.disable()
            @cloneButton.setClass "state-cloning"
            @cloneButton.setTitle "Cloning..."
        else if @state is LOADING
            @cloneButton.setClass "state-loading"
            @cloneButton.showLoader()
            @cloneButton.setTitle "Loading"
    
    writeInstalled: (path)=>
        @controller.dataManager.listRepository @getOptions().name, path
        .then =>
            @updateState()
            
        
    
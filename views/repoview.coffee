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
        @kiteHelper           = options.kiteHelper
        @state                = NOT_CLONED
        @updateState()
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
            
    cloneToMachine: =>
        new GitdashboardCloneModal
            repoView: @
            cloneUrl: @getOptions().cloneUrl
            kiteHelper: @kiteHelper

    click:(event) ->
        {url} = @getOptions()
        window.open url,"_blank"
        
    updateState: =>
        if not exists
            @state = NOT_CLONED
        else
            @kiteHelper.run
                command: "cd ~/.gitdashboard; cat repodata | grep "+@getOptions().name
            , (err,res) =>
                if not res.stdout
                    @state = NOT_CLONED
                else
                    @state = CLONED
        @updateView()
    upadateView: =>
        if @state is CLONED
            @cloneButton.enable()
            @cloneButton.unsetClass "cupid-green"
            @cloneButton.setClass "small-blue"
            @cloneButton.setTitle "Open"
        else if @state is NOT_CLONED
            @cloneButton.enable()
            @cloneButton.setTitle "Clone"
            @cloneButton.setCallback @cloneToMachine
            @cloneButton.unsetClass "small-blue"
            @cloneButton.setClass "cupid-green"
        else if @state is CLONING
            @cloneButton.disable()
            @cloneButton.setTitle "Cloning..."
    writeInstalled: (path)=>
        if not directoryExists
            @kiteController.run
                command: "mkdir ~/.gitdashboard; echo \"\" > repodata"
            directoryExists = true
        @kiteController.run
            command: "echo \"#{@getOptions.name} #{path}\" >> repodata"
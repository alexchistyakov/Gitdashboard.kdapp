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
            kiteHelper: @kiteHelper

    click:(event) ->
        {url} = @getOptions()
        window.open url,"_blank"
        
    updateState: =>
        if not root.directoryExists
            @state = NOT_CLONED
        else
            @kiteHelper.run
                command: "cat #{dataPath} | grep "+@getOptions().name+""
            ,(err,res) =>
                console.log res
                if res.exitStatus is 0
                    @openDir = res.stdout.substring res.stdout.indexOf "/"
                    @kiteHelper.run 
                        command: "test -d #{@openDir}/.git"
                    , (err,res) =>
                        if res.exitStatus is 0
                            @state = CLONED
                        else
                            @kiteHelper.run 
                                command: "sed /#{@openDir}/d #{dataPath}"
                else
                    @state = NOT_CLONED
                @updateView()
    updateView: =>
        @cloneButton.enable()
        @cloneButton.unsetClass "small-blue"
        @cloneButton.unsetClass "cupid-green"
        @cloneButton.unsetClass "clean-gray"
        @cloneButton.setCallback undefined
        @cloneButton.hideLoader()
        if @state is CLONED
            @cloneButton.setClass "small-blue"
            @cloneButton.setTitle "Open"
            @cloneButton.setCallback =>
                @controller.createTab @
        else if @state is NOT_CLONED
            @cloneButton.setTitle "Clone"
            @cloneButton.setCallback @cloneToMachine
            @cloneButton.setClass "cupid-green"
        else if @state is CLONING
            @cloneButton.disable()
            @cloneButton.setClass "clean-gray"
            @cloneButton.setTitle "Cloning..."
        else if @state is LOADING
            @cloneButton.setClass "clean-gray"
            @cloneButton.showLoader()
            @cloneButton.setTitle "Loading"
    writeInstalled: (path)=>
        @kiteHelper.run
            command: "echo #{@getOptions().name} #{path} >> #{dataPath}"
        ,(err,res) =>
            @updateState()
            
        
    
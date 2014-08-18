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

        @addSubView new KDButtonView
            title: "Clone"
            callback: @cloneToMachine
            cssClass: "cupid-green clone-button"
    cloneToMachine: (vm,path)=>
        console.log "Cloned"
    click:(event) ->
        {url} = @getOptions()
        window.open url,"_blank"
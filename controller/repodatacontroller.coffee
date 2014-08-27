class RepoDataController extends KDController
    constructor:(options={},data) ->
        @appStorage = KD.getSingleton('appStorageController').storage('Gitdashboard', '0.1')
        { trendingPageController } = KD.singletons
        return trendingPageController if trendingPageController
    
        super options, data
        @kiteHelper = options.kiteHelper
        @registerSingleton "trendingPageController", this, yes
        @kiteHelper.getKite().then (kite) =>
            kite.fsExists(path:dataPath).then (exists) =>
                root.directoryExists = exists
                console.log exists
                if exists
                    @readRepoData().then (readData) =>
                        data = readData.split "\n"
                        for dataLine in data
                            i = dataLine.indexOf " "
                            root.repodata[dataLine.substring 0,i] = dataLine.substring i+1
                        console.log repodata
                        @verifyList root.repodata
                        .then =>
                            @emit "path-checked"
        
    getSearchedRepos:(callback, topic)=>
        link = encodeURI("https://api.github.com/search/repositories?q=#{topic}&sort=stars")
        $.getJSON(link).then (json) =>
            for i in [0...searchResultCount] when json.items[i]?
              callback(@repoViewFromJson(json.items[i]))    
    
    getTrendingRepos:(callback)->
        @appStorage.fetchStorage =>
            Promise.all(searchKeywords.map (topic) =>
                link = encodeURI("https://api.github.com/search/repositories?q=#{topic}&sort=stars&order=desc")
                return $.getJSON(link).then (json) =>
                    for i in [0...reposPerTopic] when json.items[i]?
                        @generateOptions(json.items[i])
            ).then (results) =>
                repos = @formatResults(results)
                console.log repos
                for repoO in repos
                    @appendExtras(repoO)
                    callback(new RepoView repoO)
                @emit "trending-page-downloaded"
                KD.utils.defer =>
                    @appStorage.setValue "repos" , JSON.stringify repos
            .catch (err) =>
                KD.utils.defer =>
                    options = JSON.parse Encoder.htmlDecode @appStorage.getValue("repos")
                    for option in options
                        @appendExtras(option)
                        callback(new RepoView option)
                    @emit "trending-page-downloaded"

    getMyRepos:(callback,authToken)->
        authToken.get("/user/repos")
        .done (response) =>
            for repo in response
                options = @appendExtras @generateOptions repo
                callback(new RepoView options)
        .fail (err) ->
            console.log err

    formatResults: (results) ->
        repos = flatten(results)
        repos = bubbleSort(repos)
        if repos.length > reposInTrending 
            repos = repos[0...reposInTrending]
        return repos
    generateOptions: (item) ->
        {
            name: item.name
            user: item.owner.login
            authorGravatarUrl: item.owner.avatar_url
            cloneUrl: item.clone_url
            description: item.description
            stars: item.stargazers_count
            language: item.language
            url: item.html_url
        }
    appendExtras: (list) =>
        list["kiteHelper"] = @kiteHelper
        list["controller"] = @
        return list
    createTab: (repoView) =>
        @emit "tab-open-request",repoView
    
    readRepoData: =>
        @kiteHelper.run
            command: "cat #{dataPath}"
        .then (res) => res.stdout
    
    repositoryIsListed: (name) =>
        console.log root.repodata
        if root.repodata[name]?
            return true
        else 
            return false
    gitPresentInRepoFolder: (dir) =>
        console.log dir
        @kiteHelper.run 
            command: "test -d #{dir}/.git"
        .then (res) => res.exitStatus is 0
    unlistRepository: (name,path) =>
        if root.repodata[name]?
            delete root.repodata[name]
            @kiteHelper.run 
                command: "sed /#{path}/d #{dataPath} > #{dataPath}"
            .then (res) => res.exitStatus is 0
                    
    listRepository: (name,path) =>
        root.repodata[name] = path
        @kiteHelper.run
            command: "echo #{name} #{path} >> #{dataPath}"
        .then (res) => res.exitStatus is 0
    getRepoDirectory: (name) =>
        root.repodata[name]
    verifyList: (list) =>
        keys = Object.keys(list)
        Promise.all( keys.map (key)=>
            @gitPresentInRepoFolder list[key]
            .then (present) =>
                console.log list[key]+" "+present
                if not present
                    key
        ).then (results) =>
            console.log results
            results = results.filter(Boolean)
            Promise.all( results.map (data) =>
                console.log "Removing"
                console.log data
                @unlistRepository data, @getRepoDirectory data
            )

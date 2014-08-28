class RepoDataController extends KDController
    constructor:(options={},data) ->
        @appStorage = KD.getSingleton('appStorageController').storage('Gitdashboard', '0.1')
        { repoDataController } = KD.singletons
        return repoDataController if repoDataController
    
        super options, data
        @dataManager = options.dataManager
        @registerSingleton "repoDataController", this, yes
        @dataManager.checkDataPath().then (exists) =>
            if exists
                @dataManager.readRepoData().then =>
                    @dataManager.verifyRepoData().then =>
                        @emit "path-checked"
        
    getSearchedRepos:(callback, topic)=>
        link = encodeURI("https://api.github.com/search/repositories?q=#{topic}&sort=stars")
        $.getJSON(link).then (json) =>
            for i in [0...searchResultCount] when json.items[i]?
              options = @generateOptions(json.items[i])
              @appendExtras(options)
              callback(new RepoView options)
            @emit "search-results-downloaded"
        .fail (err) =>
            callback false
    
    getTrendingRepos:(callback)->
        @appStorage.fetchStorage =>
            Promise.all(searchKeywords.map (topic) =>
                link = encodeURI("https://api.github.com/search/repositories?q=#{topic}&sort=stars&order=desc")
                return $.getJSON(link).then (json) =>
                    for i in [0...reposPerTopic] when json.items[i]?
                        @generateOptions(json.items[i])
            ).then (results) =>
                repos = @formatResults(results)
                for repoO in repos
                    @appendExtras(repoO)
                    callback(new RepoView repoO)
                @emit "trending-page-downloaded"
                KD.utils.defer =>
                    @appStorage.setValue "repos" , JSON.stringify repos
            .catch (err) =>
                KD.utils.defer =>
                    console.log err
                    value = @appStorage.getValue("repos")
                    decode = value.replace(/&quot;/g,"\"")
                    options = JSON.parse decode
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
            sshCloneUrl: item.ssh_url
        }
    appendExtras: (list) =>
        list["controller"] = @
        return list
    createTab: (repoView) =>
        @emit "tab-open-request",repoView

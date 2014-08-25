class RepoDataController extends KDController
    constructor:(options={},data) ->
        @appStorage = KD.getSingleton('appStorageController').storage('Gitdashboard', '0.1')
        { trendingPageController } = KD.singletons
        return trendingPageController if trendingPageController
    
        super options, data
        @kiteHelper = options.kiteHelper
        @registerSingleton "trendingPageController", this, yes
        @kiteHelper.getKite().then (kite) =>
            kite.fsExists("~/.gitdashboard").then (exists) =>
                directoryExists = exists
        
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
                    repoO["kiteHelper"] = @kiteHelper
                    callback(new RepoView repoO)
                @appStorage.setValue "repos" , JSON.stringify repos
            .catch (err) =>
                console.log "Throttle load"
                console.log "Block"
                options = JSON.parse Encoder.htmlDecode @appStorage.getValue("repos")
                for option in options
                    option["kiteHelper"] = @kiteHelper
                    callback(new RepoView option)
        ,true
    getMyRepos:(callback,authToken)=>
        authToken.get("/user/repos")
        .done (response) =>
            for repo in response
                repo["kiteHelper"] = @kiteHelper
                callback(new RepoView @generateOptions(repo))
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
        
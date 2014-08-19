class RepoDataController extends KDController
    constructor:(options={},data) ->
        @appStorage = KD.getSingleton('appStorageController').storage('Gitdashboard', '0.1')
        { trendingPageController } = KD.singletons
        return trendingPageController if trendingPageController
    
        super options, data
    
        @registerSingleton "trendingPageController", this, yes
        
    getTrendingRepos:(callback)->
            Promise.all(searchKeywords.map (topic) =>
                link = encodeURI("https://api.github.com/search/repositories?q=#{topic}&sort=stars&order=desc")
                return $.getJSON(link).then (json) =>
                    for i in [0...reposPerTopic] when json.items[i]?
                        {
                            name: json.items[i].name
                            user: json.items[i].owner.login
                            authorGravatarUrl: json.items[i].owner.avatar_url
                            cloneUrl: json.items[i].clone_url
                            description: json.items[i].description
                            stars: json.items[i].stargazers_count
                            language: json.items[i].language
                            url: json.items[i].html_url
                        }
            ).then (results) =>
                repos = @formatResults(results)
                console.log repos
                for repoO in repos
                    callback(new RepoView repoO)
                @appStorage.setValue "repos" , repos
            .catch (err) =>
                console.log "Throttle load"
                console.log "Block"
                options = @appStorage.getValue("repos")
                for option in options
                    callback(new RepoView option)
    getMyRepos:(callback,authToken)->
        repoViewFromJson = @repoViewFromJson
        authToken.get("/user/repos")
        .done (response) ->
            for repo in response
                callback(repoViewFromJson(repo))
        .fail (err) ->
            console.log err
    formatResults: (results) ->
        repos = flatten(results)
        repos = bubbleSort(repos)
        if repos.length > reposInTrending 
            repos = repos[0...reposInTrending]
        return repos
        
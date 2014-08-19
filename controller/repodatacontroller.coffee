class RepoDataController extends KDController
    constructor:(options={},data) ->
        @appStorage = KD.getSingleton('appStorageController').storage('Terminal', '1.0.1')
        { trendingPageController } = KD.singletons
        return trendingPageController if trendingPageController
    
        super options, data
    
        @registerSingleton "trendingPageController", this, yes
        
    getTrendingRepos:(callback)->
        Promise.all(searchKeywords.map (topic) =>
            link = encodeURI("https://api.github.com/search/repositories?q=#{topic}&sort=stars&order=desc")
            return $.getJSON(link).then (json) =>
                for i in [0...reposPerTopic] when json.items[i]?
                    @repoViewFromJson(json.items[i])
        ).then (results) =>
            @formatResults(results)
            console.log @, @appStorage
            @appStorage.fetchStorage =>
                @appStorage.setValue 'results' , results
        .catch (err) =>
            console.log @, @appStorage
            @appStorage.fetchStorage =>
                console.log @appStorage.getValue "results"
    getMyRepos:(callback,authToken)->
        repoViewFromJson = @repoViewFromJson
        authToken.get("/user/repos")
        .done (response) ->
            for repo in response
                callback(repoViewFromJson(repo))
        .fail (err) ->
            console.log err
    repoViewFromJson: (json) ->
        new RepoView
            name: json.name
            user: json.owner.login
            authorGravatarUrl: json.owner.avatar_url
            cloneUrl: json.clone_url
            description: json.description
            stars: json.stargazers_count
            language: json.language
            url: json.html_url
    formatResults: (results) ->
        repos = flatten(results)
        repos = bubbleSort(repos)
        if repos.length > reposInTrending 
            repos = repos[0...reposInTrending]
        for repo in repos
            callback(repo)
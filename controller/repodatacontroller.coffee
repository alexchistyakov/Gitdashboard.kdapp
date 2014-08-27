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
                    @readRepoData (readData)=>
                        data = readData.split "\n"
                        for dataLine in data
                            i = dataLine.indexOf " "
                            root.repodata[dataLine.substring 0,i] = dataLine.substring i+1
                        console.log repodata
                        @verifyList root.repodata, =>
                            @emit "path-checked"
        
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
    
    readRepoData:(callback) =>
        @kiteHelper.run
            command: "cat #{dataPath}"
        , (err,res) =>
            if not err and res
                callback(res.stdout)
    
    repositoryIsListed: (name) =>
        console.log root.repodata
        if root.repodata[name]?
            return true
        else 
            return false
    gitPresentInRepoFolder: (dir,callback) =>
        console.log dir
        @kiteHelper.run 
            command: "test -d #{dir}/.git"
        ,(err,res) =>
            console.log ">>>>>>>>>"+res.exitStatus
            if not err and res
                callback(res.exitStatus is 0)
    unlistRepository: (name,path,callback) =>
        if root.repodata[name]?
            delete root.repodata[name]
            @kiteHelper.run 
                command: "sed /#{path}/d #{dataPath} > #{dataPath}"
            , (err,res) =>
                if not err and res
                    callback res.exitStatus is 0 if callback?
    listRepository: (name,path,callback) =>
        root.repodata[name] = path
        @kiteHelper.run
            command: "echo #{name} #{path} >> #{dataPath}"
        , (err,res) =>
            if not err and res
                callback res.exitStatus is 0 if callback?
    getRepoDirectory: (name) =>
        root.repodata[name]
    verifyList: (list,callback) =>
        keys = []
        for key in list
            if list.isOwnProperty key
                keys.push key
        Promise.all( keys.map (key)=>
            console.log @gitPresentInRepoFolder list[key], (present) =>
                console.log list[key]+" "+present
                if not present
                    key
        ).then (results) =>
            console.log results
            Promise.all( results.map (data) =>
                return @unlistRepository data, @getDirectory data
            ).then =>
                callback()
                        
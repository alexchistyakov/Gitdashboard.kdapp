class RepoDataManager 
    constructor: (options = {}, data) ->
        @token = null
        @kiteHelper = options.kiteHelper
        @useSSHCloneProtocol = false
        @repodata = {}
    readRepoData: =>
        @kiteHelper.run
            command: "cat #{dataPath}"
        .then (readData) => 
            data = readData.stdout.split "\n"
            for dataLine in data
                i = dataLine.indexOf " "
                @repodata[dataLine.substring 0,i] = dataLine.substring i+1
    
    repositoryIsListed: (name) =>
        if not @repodata?
            false
        else if @repodata[name]?
            true
        else 
            false
            
    gitPresentInRepoFolder: (dir) =>
        @kiteHelper.run 
            command: "test -d #{dir}/.git"
        .then (res) => res.exitStatus is 0
        
    unlistRepository: (name,path) =>
        if @repodata[name]?
            delete @repodata[name]
            @kiteHelper.run 
                command: "sed /#{path}/d #{dataPath} > #{dataPath}"
            .then (res) => res.exitStatus is 0
                    
    listRepository: (name,path) =>
        @repodata[name] = path
        @kiteHelper.run
            # This is done to  make sure there are no duplicates if the user logged out  while cloning
            command: "sed /#{path}/d #{dataPath} > #{dataPath}; echo #{name} #{path} >> #{dataPath}"
        .then (res) => res.exitStatus is 0
        
    getRepoDirectory: (name) =>
        @repodata[name]
        
    verifyRepoData: =>
        keys = Object.keys(@repodata)
        Promise.all( keys.map (key)=>
            @gitPresentInRepoFolder @repodata[key]
            .then (present) =>
                if not present
                    key
            .catch (err) =>
                console.log err
        ).then (results) =>
            results = results.filter(Boolean)
            Promise.all( results.map (data) =>
                @unlistRepository data, @getRepoDirectory data
            )
        .catch (err) =>
            console.log err
    checkDataPath: =>
        @kiteHelper.getKite().then (kite) =>
            kite.fsExists(path:dataPath).then (exists)=>
                @directoryExists = exists
            
    cloneRepo: (name,url,path) =>
        @kiteHelper.run
            # Makes it so the app still registers repo if user logged out while cloning
            command: "git clone #{url} #{path}; echo #{name} #{path} >> #{dataPath}"
            
    checkSSHKeys: =>
        @kiteHelper.run
            command: "test -f ~/.ssh/id_rsa.pub && test -f ~/.ssh/id_rsa"
        .then (res) =>
            console.log res
            res.exitStatus is 0
        .catch (err) =>
            console.log err
    generateSSHKeys: (email,passphrase="") =>
        @kiteHelper.run
            command: "echo -e \"\n\n\n\" | ssh-keygen -t rsa -N #{passphrase} -C #{email}"
        .catch (err) =>
            console.log err
    readSSHKeys: =>
        @kiteHelper.run
            command: "cat ~/.ssh/id_rsa.pub"
        .then (res) =>
            res.stdout
        .catch (err) =>
            console.log err
    compareSSHKeys: (callback)=>
        @token.get("/user/keys").done (res) =>
            @readSSHKeys().then (key) =>
                ret = false
                for onlineKey in res
                    if onlineKey.key is key.substring 0,key.lastIndexOf " "
                        ret = true
                callback(ret)
    
    postSSHKey: (title) =>
        @readSSHKeys().then (key) =>
            @token.post "/user/keys",
                contentType: "application/json; charset=utf-8",
                dataType: "json",
                "data": JSON.stringify
                    "title": "Koding@"+title.substring(0,title.indexOf ".")
                    "key": key
            .done (res) =>
                console.log res
            .fail (err) =>
                console.log err
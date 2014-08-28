class RepoDataManager 
    constructor: (options = {}, data) ->
        @token = OAuth.create "github"
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
            command: "echo #{name} #{path} >> #{dataPath}"
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
        ).then (results) =>
            results = results.filter(Boolean)
            Promise.all( results.map (data) =>
                @unlistRepository data, @getRepoDirectory data
            )
    checkDataPath: =>
        @kiteHelper.getKite().then (kite) =>
            kite.fsExists(path:dataPath).then (exists)=>
                @directoryExists = exists
            
    cloneRepo: (url,path) =>
        @kiteHelper.run
            command: "git clone #{url} #{path}"
            
    checkSSHKeys: =>
        @kiteHelper.run
            command: "test -f ~/.ssh/id_rsa.pub && test -f ~/.ssh/id_rsa"
        .then (res) =>
            console.log res
            res.exitStatus is 0
    generateSSHKeys: (email,passphrase="") =>
        @kiteHelper.run
            command: "echo -e \"\n#{passphrase}\n#{passphrase}\n\" | ssh-keygen -t rsa -C #{email}"
    readSSHKey: =>
        @kiteHelper.run
            command: "cat ~/.ssh/id_rsa.pub"
        .then (res) =>
            res.stdout
    compareSSHKeys: =>
        @token.get "/user/keys"
        .done (res) =>
            readSSHKey().then (key) =>
                for item in items when item.key is key
                    item
    
    postSSHKey: (key,title) =>
        @token.post "/user/keys",
            title: title
            key: key
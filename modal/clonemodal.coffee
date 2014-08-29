class GitdashboardCloneModal extends KDModalView

  constructor: (options = {}, data)->
    options.cssClass = "clone-modal"
    @repoView = options.repoView
    @dataManager = options.dataManager
    
    @finderController = new NFinderController
        hideDotFiles:true
        nodeIdPath: "path"
        nodeParentIdPath: "parentPath"
        foldersOnly: true
        contextMenu: false
        loadFilesOnInit: true
        
    @dataManager.kiteHelper.getKite().then (kite) =>
        @unmountAll()
        @finderController.mountVm @dataManager.kiteHelper.getVmByName @dataManager.kiteHelper.getVm()
        @finderController.isNodesHiddenFor = -> true
    super options, data
    
  viewAppended:->
    @addSubView @nameInput = new KDInputView
        placeholder: "Name"

    @addSubView @finderController.getView()

    @addSubView new KDButtonView
        title: "Clone to my VM"
        cssClass: "cupid-green"
        callback: =>
            unless @nameInput.getValue() is ""
                @beginClone()
  beginClone: =>
    fullPath = @finderController.treeController.selectedNodes[0].data.path+"/"+@nameInput.getValue()
    fullPath = fullPath.substring fullPath.indexOf "/"
    console.log fullPath
    @repoView.state = CLONING
    @repoView.updateView()
    @destroy()
    @dataManager.cloneRepo(@repoView.getOptions().name,@repoView.getOptions().cloneUrl, fullPath).then (cloned) =>
        if not cloned
            new KDModalView
                title: "Error occured while cloning"
        else 
            @repoView.writeInstalled(fullPath)
  unmountAll: =>
    console.log @finderController.unmountVm vmR.hostnameAlias for vmR in @dataManager.kiteHelper._vms
    
class GitdashboardCloneModal extends KDModalView

  constructor: (options = {}, data)->
    options.cssClass = "clone-modal"
    @cloneUrl = options.cloneUrl
    @repoView = options.repoView
    @kiteHelper = options.kiteHelper
    
    @finderController = new NFinderController
        hideDotFiles:true
        nodeIdPath: "path"
        nodeParentIdPath: "parentPath"
        foldersOnly: true
        contextMenu: false
        loadFilesOnInit: true
        
    @kiteHelper.getKite().then (kite) =>
        @unmountAll()
        @finderController.mountVm @kiteHelper.getVmByName @kiteHelper.getVm()
        @finderController.isNodesHiddenFor = -> true
    super options, data
    
  viewAppended:->
    @kiteHelper.getReady().then =>
        
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
    @kiteHelper.run
        command: "git clone "+@cloneUrl+" "+fullPath
        password: null
    ,(err,res) =>
        if err? or res.exitStatus is not 0
            new KDModalView
                title: "Error"
                view: new KDView
                    partial: err
        else 
            @repoView.writeInstalled(fullPath)
  unmountAll: =>
    @finderController.unmountVm vmR.vmName for vmR in @finderController.vms
    
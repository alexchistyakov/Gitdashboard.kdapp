class GitdashboardCloneModal extends KDModalView

  constructor: (options = {}, data)->
    options.cssClass = "clone-modal"
    @repoView = options.repoView
    
    @kiteHelper = options.kiteHelper
    
    console.log @kiteHelper
    @vmSelector = new VMSelectorView
        callback: @switchVM
        kiteHelper: @kiteHelper

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
            callback: @beginClone

        @addSubView new KDButtonView
            title: "Cancel"
            callback: @cancel
  beginClone: =>
    fullPath = @finderController.treeController.selectedNodes[0].data.path+""+@nameInput.getValue
  unmountAll: =>
    @finderController.unmountVm vmR.vmName for vmR in @finderController.vms
    
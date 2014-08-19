class GitdashboardCloneModal extends KDModalView

  constructor: (options = {}, data)->
    options.cssClass = "clone-modal"
    @repoView = options.repoView

    @kiteHelper = new KiteHelper
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

    @finderController.isNodesHiddenFor = -> true
    @finderController.unmountVm vm.hostnameAlias for vm in @finderController.vms
    super options, data

  viewAppended:->
    @kiteHelper.getReady().then =>
        @addSubView @vmSelector

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

  switchVM: (vm) =>
    @finderController.unmountVm @currentVm if @currentVm?
    @finderController.mountVm @kiteHelper.getVmByName vm
    @currentVm = vm

  beginClone: =>
    console.log @finderController.treeController.selectedNodes[0]

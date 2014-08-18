class GitdashboardCloneModal extends KDModalView
  constructor: (options = {}, data)->
    options.cssClass = "clone-modal"
    @repoView = options.repoView
    
    @kiteHelper = new KiteHelper
    @finderController = new NFinderController
        hideDotFiles:true
    @finderController.isNodesHiddenFor = -> true
    super options, data
  viewAppended:->
    @addSubView new VMSelectorView
        callback: @switchVM
        kitHelper: @kiteHelper
    @addSubView @nameInput new KDInputView
        placeholder: "Name"
    @addSubView @finderController.getView()
    @addSubView new KDButtonView 
        title: "Clone to my VM"
        cssClass: "cupid green"
        callback: @beginClone
    @addSubView new KDButtonView
        title: "Cancel"
        callback: @cancel
  switchVM: (vm) =>
    @finderController.mountVm vm
    @currentVm = vm
  beginClone: =>
    console.log @fileController.treeController.selectedNodes[0]
  
class VMSelectorView extends KDView
  constructor: (options={},data) ->
      @kiteHelper = options.kiteHelper
      options.callback or= undefined
      super options,data
  viewAppended: ->
    console.log "Appended"
    @kiteHelper.getReady().then =>
      console.log "Ready"
      @addSubView @header = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'header'
        partial       : @namify(@kiteHelper.getVm())

      @addSubView @selection = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'selection'

      @updateList()

  namify: (hostname)->
    return hostname.split(".")[0]

  updateList: ->
    @selection.updatePartial ""
    {vmController} = KD.singletons
    console.log "Iteration begin"
    @kiteHelper.getVms().forEach (vm)=>
      @selection.addSubView vmItem = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : "item"
        click         : =>
          @chooseVm vm.hostnameAlias if !@hasClass "disabled"
      console.log "View added"
      if vm.hostnameAlias is @kiteHelper.getVm()
        vmItem.setClass "active"
      console.log "Active checked"
      vmItem.addSubView new KDCustomHTMLView
        tagName       : 'span'
        cssClass      : "bubble"
      console.log "Active checked 1"
      vmItem.addSubView new KDCustomHTMLView
        tagName       : 'span'
        cssClass      : "name"
        partial       : @namify vm.hostnameAlias
      console.log "Active checked 2"
      vmController.info vm.hostnameAlias, (err, vmn, info)=>
        vmItem.setClass info?.state.toLowerCase()
        
      console.log "VM is loaded"
  chooseVm: (vm)->
    {callback} = @getOptions()
    @kiteHelper.setDefaultVm vm
    callback(vm)
    @header.updatePartial @namify vm
    @updateList()

  turnOffVm: (vm)->

    @kiteHelper.turnOffVm(vm).then =>
      # Wait for Koding to register other vm is off
      KD.utils.wait 10000, =>
        @installer.init()
        @updateList()
    .catch (err)=>
      

  turnOffVmModal: ->
      unless @modal
        {vmController} = KD.singletons
        @addSubView container = new KDCustomHTMLView
            tagName         : 'div'

        @kiteHelper.getVms().forEach (vm)=>
          container.addSubView vmItem = new KDCustomHTMLView
            tagName       : 'div'
            cssClass      : "item"
            partial       : """
              <div class="bubble"></div>
              #{vm.hostnameAlias}
            """
            click         : (event)=>
              @turnOffVm vm.hostnameAlias
              @removeModal()

          vmController.info vm.hostnameAlias, (err, vmn, info)=>
            if info?.state != "RUNNING"
              vmItem.destroy()

        @modal = new KDModalView
          title           : "Choose VM To Turn Off"
          overlay         : yes
          overlayClick    : no
          width           : 400
          height          : "auto"
          cssClass        : "new-kdmodal"
          view            : container
          cancel          : => @removeModal()

  removeModal: ->
    @modal.destroy()
    delete @modal

  disabled: (disabled)->
    if disabled
      @setClass "disabled"
    else
      @unsetClass "disabled"

class VMSelectorView extends KDView
  constructor: (options={},data) ->
      @kiteHelper = options.kiteHelper
      @container = options.container
      options.callback or= undefined
      super options,data

  viewAppended: ->
    console.log @kiteHelper.ready
    @addSubView @loader = new KDLoaderView
        showLoader    : yes
        size          :
          width       : 20
    @kiteHelper.ready =>
      
      @addSubView @header = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'header'
        partial       : @namify(@kiteHelper.getVm())
        click         : => @selection.toggleClass "hidden"
        
      @addSubView @selection = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : 'selection hidden'
      @updateList()
      @loader.setClass "hidden"

    @kiteHelper.getKite()
  namify: (hostname)->
    return hostname.split(".")[0]

  updateList: ->
    @selection.updatePartial ""
    {vmController} = KD.singletons
    @kiteHelper.getVms().forEach (vm)=>
      @selection.addSubView vmItem = new KDCustomHTMLView
        tagName       : 'div'
        cssClass      : "item"
        click         : =>
          @chooseVm vm.hostnameAlias if !@hasClass "disabled"
      if vm.hostnameAlias is @kiteHelper.getVm()
        vmItem.setClass "active"
      vmItem.addSubView new KDCustomHTMLView
        tagName       : 'span'
        cssClass      : "bubble"
      vmItem.addSubView new KDCustomHTMLView
        tagName       : 'span'
        cssClass      : "name"
        partial       : @namify vm.hostnameAlias
      vmController.info vm.hostnameAlias, (err, vmn, info)=>
        vmItem.setClass info?.state.toLowerCase()

  chooseVm: (vm)=>
    {callback} = @getOptions()
    @kiteHelper.setDefaultVm vm
    callback(vm)
    @header.updatePartial @namify vm
    @updateList()
    

  turnOffVm: (vm,toMount)->
      console.log @overlay
      unless @overlay?
        @overlay = new KDOverlayView
            isRemovable: false
            color: "#000"
            container: @container
            title: "Please wait while we switch VMs"
        @header.setClass "hidden"
        @selection.setClass "hidden"
        @loader.unsetClass "hidden"
        @kiteHelper.turnOffVm(vm).then =>
          # Wait for Koding to register other vm is off
          KD.utils.wait 10000, =>
            @chooseVm(toMount)
            @updateList()
            @header.unsetClass "hidden"
            @selection.unsetClass "hidden"
            @loader.setClass "hidden"
            @overlay.remove()
            delete @overlay
        .catch (err)=>
            console.log err


  turnOffVmModal:(toMount) ->
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
              @turnOffVm vm.hostnameAlias,toMount
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

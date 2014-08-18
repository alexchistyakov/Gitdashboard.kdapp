class FinderView extends KDView

  constructor: (options = {}, data) ->

    super options, data
    @finderController = new NFinderController {
        hideDotFiles : yes
    }
    @addSubView @finderController.getView()
      # Temporary fix, until its fixed in upstream ~ GG
    @finderController.isNodesHiddenFor = -> yes

  openFile: (file) ->
  
    file.fetchContents (err, contents) =>
    
      unless err
        
        panel = @getDelegate()
        {CSSEditor, JSEditor} = panel.panesByName

        switch file.getExtension()
          when 'css', 'styl'
          then editor = CSSEditor
          else editor = JSEditor
        
        editor.openFile file, contents
        
        @emit "switchMode", 'develop'
        
      else
        
        new KDNotificationView
          type     : "mini"
          cssClass : "error"
          title    : "Sorry, couldn't fetch file content, please try again..."
          duration : 3000

  loadFile: (path)->

    file = FSHelper.createFileFromPath path

    kite = KD.getSingleton('vmController').getKiteByVmName file.vmName
    return  callback {message: "VM not found"}  unless kite

    @openFile file
    
  initWithVM: (vm) =>
    @finderController.mountVm vm
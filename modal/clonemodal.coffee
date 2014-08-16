class GitdashboardCloneModal extends KDModalView
  constructor: (options = {}, data)->
    @kiteHelper = new KiteHelper
    
    options.cssClass = "clone-modal"
    super options, data
    

  
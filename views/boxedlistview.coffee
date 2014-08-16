class BoxedListView extends KDView
    constructor: (options={},data) ->
        options.header           or= "Dummy Header"
        options.seeMoreCallback  or= undefined
        options.cssClass         = KD.utils.curry "boxedlist-container", options.cssClass
        super options,data
    viewAppended: ->
        {header,seeMoreCallback} = @getOptions()
        @addSubView new KDHeaderView
          title: header
          type: "big"
          cssClass: "box-header"
        @addSubView @list = new KDListView
          cssClass: "list"
        @addSubView @seeMoreButton = new KDButtonView
          title: "See more"
          callback: seeMoreCallback
          cssClass: "seemore-button"
    addRepo: (repoView) ->
        @list.addItemView repoView
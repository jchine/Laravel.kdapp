class LaravelApp extends JView

  constructor:->

    super

    @listenWindowResize()

    @dashboardTabs = new KDTabView
      hideHandleCloseIcons : yes
      hideHandleContainer  : yes
      cssClass             : "laravel-installer-tabs"

    @buttonGroup = new KDButtonGroupView
      buttons       :
        "Dashboard" :
          cssClass  : "clean-gray toggle"
          callback  : => @dashboardTabs.showPaneByIndex 0
        "Create a new Laravel App" :
          cssClass  : "clean-gray"
          callback  : => @dashboardTabs.showPaneByIndex 1

    @dashboardTabs.on "PaneDidShow", (pane)=>
      if pane.name is "dashboard"
        @buttonGroup.buttonReceivedClick @buttonGroup.buttons.Dashboard
      else
        @buttonGroup.buttonReceivedClick @buttonGroup.buttons["Create a new Laravel App"]

  viewAppended:->

    super

    @dashboardTabs.addPane dashboard = new DashboardPane
      cssClass : "dashboard"
      name     : "dashboard"

    @dashboardTabs.addPane installPane = new InstallPane
      name     : "install"

    @dashboardTabs.showPane dashboard

    installPane.on "LaravelInstalled", (formData)->
      dashboard.putNewItem formData, no

    @_windowDidResize()

  _windowDidResize:->

    @dashboardTabs.setHeight @getHeight() - @$('>header').height()

  pistachio:->

    """
    <header>
      <figure></figure>
      <article>
        <h3>Laravel Dashboard</h3>
        <p>This application create Laravel App with the composer.</p>
        <p>You can maintain all your Laravel apps via the dashboard.</p>
      </article>
      <section>
      {{> @buttonGroup}}
      </section>
    </header>
    {{> @dashboardTabs}}
    """

class LaravelSplit extends KDSplitView

  constructor:(options, data)->

    @output = new KDScrollView
      tagName  : "pre"
      cssClass : "terminal-screen"

    @laravelapp = new LaravelApp

    options.views = [ @laravelapp, @output ]

    super options, data

  viewAppended:->

    super

    @panels[1].setClass "terminal-tab"

class LaravelPane extends KDTabPaneView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

kite         = KD.getSingleton "kiteController"
{nickname}   = KD.whoami().profile
appStorage = new AppStorage "laravel-installer", "1.0"

class InstallPane extends LaravelPane

  constructor:->

    super

    @form = new KDFormViewWithFields
      callback              : @bound "installLaravel"
      buttons               :
        install             :
          title             : "Create Laravel instance"
          style             : "cupid-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
      fields                :
        name                :
          label             : "Name of Laravel App:"
          name              : "name"
          placeholder       : "type a name for your app..."
          defaultValue      : "trylaravel"
          validate          :
            rules           :
              required      : "yes"
              regExp        : /(^$)|(^[a-z\d]+([_][a-z\d]+)*$)/i
            messages        :
              required      : "a name for your laravel app is required!"
          nextElement       :
            timestamp       :
              name          : "timestamp"
              type          : "hidden"
              defaultValue  : Date.now()
        domain              :
          label             : "Domain :"
          name              : "domain"
          itemClass         : KDSelectBox
          defaultValue      : "#{nickname}.kd.io"
        laravelversion      :
          label             : "Laravel Version :"
          name              : "laravelversion"
          itemClass         : KDSelectBox
          defaultValue      : "4"

    @form.on "FormValidationFailed", => @form.buttons["Create Laravel instance"].hideLoader()

    vmc = KD.getSingleton 'vmController'

    vmc.fetchVMs (err, vms)=>
      if err then console.log err
      else
        vms.forEach (vm) =>
          vmc.fetchVMDomains vm, (err, domains) =>
            newSelectOptions = []
            usableDomains = [domain for domain in domains when not /^(vm|shared)-[0-9]/.test domain].first
            usableDomains.forEach (domain) =>
              newSelectOptions.push {title : domain, value : domain}

            {domain} = @form.inputs
            domain.setSelectOptions newSelectOptions
        

    newVersionOptions = []
    # Implement later, pip only supports stable version
    #newVersionOptions.push {title : "Latest (git)", value : "git"}
    newVersionOptions.push {title : "4", value : "4"}

    {laravelversion} = @form.inputs
    laravelversion.setSelectOptions newVersionOptions

  completeInputs:(fromPath = no)->

    {path, name, pathExtension} = @form.inputs
    if fromPath
      val  = path.getValue()
      slug = KD.utils.slugify val
      path.setValue val.replace('/', '') if /\//.test val
    else
      slug = KD.utils.slugify name.getValue()
      path.setValue slug

    slug += "/" if slug

    pathExtension.inputLabel.updateTitle "/#{slug}"

  checkPath: (name, callback)->
    instancesDir = "laravelapp"

    kite.run "[ -d /home/#{nickname}/Web/#{instancesDir}/#{name} ] && echo 'These directories exist'"
    , (err, response)->
      if response
        console.log "You have already a Laravel instance with the name \"#{name}\". Please delete it or choose another path"
      callback? err, response

  showInstallFail: ->
    new KDNotificationView
        title     : "Laravel instance exists already. Please delete it or choose another name"
        duration  : 3000

  installLaravel: =>
    domain = @form.inputs.domain.getValue()
    name = @form.inputs.name.getValue()
    laravelversion = @form.inputs.laravelversion.getValue()
    timestamp = parseInt @form.inputs.timestamp.getValue(), 10


    console.log "LARAVEL VERSION", laravelversion
    @checkPath name, (err, response)=>
      if err # means there is no such folder
        console.log "Starting install with formData", @form

        #If you change it, grep the source file because this variable is used
        instancesDir = "laravelapp"
        tmpAppDir = "#{instancesDir}/tmp"

        kite.run "mkdir -p '#{tmpAppDir}'", (err, res)=>
          if err then console.log err
          else
            laravelScript = """
                          sudo apt-get install php5-mcrypt
                          curl -sS https://getcomposer.org/installer | php
                          php composer.phar create-project laravel/laravel #{name} --prefer-dist
                          mv .composer #{name} vendor/ composer.phar Web/
                          sudo chmod -R 777 Web/#{name}/app/storage
                          rm -rf laravelapp
                          echo '*** -> Installation successfull, Laravel is ready for your artisan skills.'
                          """

            newFile = FSHelper.createFile
              type   : 'file'
              path   : "#{tmpAppDir}/laravelScript.sh"
              vmName : @vmName

            newFile.save laravelScript, (err, res)=>
              if err then warn err
              else
                @emit "fs.saveAs.finished", newFile, @

            installCmd = "bash #{tmpAppDir}/laravelScript.sh\n"
            formData = {timestamp: timestamp, domain: domain, name: name, laravelversion: laravelversion}

            modal = new ModalViewWithTerminal
              title   : "Creating Laravel Instance: '#{name}'"
              width   : 700
              overlay : no
              terminal:
                height: 500
                command: installCmd
                hidden: no
              content : """
                        <div class='modalformline'>
                          <p>Using Laravel <strong>#{laravelversion}</strong></p>
                          <br>
                          <i>note: your sudo password is your koding password. </i>
                        </div>
                        """

            @form.buttons.install.hideLoader()
            appStorage.fetchValue 'blogs', (blogs)->
              blogs or= []
              blogs.push formData
              appStorage.setValue "blogs", blogs

            @emit "LaravelInstalled", formData

      else # there is a folder on the same path so fail.
        @form.buttons.install.hideLoader()
        @showInstallFail()

  pistachio:-> "{{> this.form}}"


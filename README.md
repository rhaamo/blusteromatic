Blusteromatic
=============

1.  About

    Blusteromatic is a remote renderer for blender files. Just upload a blend file, configure it, and render it!

2.  Features

    * Blend file upload
    * Nodes assignment based on render type and engine
    * Multiple render per job
    * Single or Animation support
    * Support for custom blender-python file
    * Support for any render engine supported by blender
    
3.  Installation

    We are assuming the following infos about the installation:
    
    * Node and dispatcher installed under the same user : "blusteromatic"
    * Nginx will be used, and the dispatcher run under unicorn
    * RVM will be used for the ruby

3. 1.  Prerequirements

    \# = root
    
    $ = under 'blusteromatic'
    
    \# useradd -m -s /bin/bash blusteromatic
    \# sudo su - blusteromatic
    
    Install RVM : https://rvm.io// with a ruby-1.9.x
    
     $ echo 'export RAILS_ENV=production' >> .bash_profile
     
     $ cd
     
     $ git clone git://github.com/rhaamo/blusteromatic.git
     
     $ cd blusteromatic/server
     
     $ bundle install
     
     Create the 'config/database.yml' file.
     
     $ rake db:create db:migrate
     
     $ rake assets:clean assets:precompile
     
     $ rake tmp:create

3. 2.  Unicorn / nginx

     $ cd ~/blusteromatic/
     
     $ cp misc/unicorn.rb ~/
     
     Edit unicorn.rb according to your options (ruby version, paths)
     
     \# cp /home/blusteromatic/blusteromatic/misc/nginx_blusteromatic /etc/nginx/sites-availables/
     
     \# ln -s /etc/nginx/sites-availables/nginx_blusteromatic /etc/nginx/sites-enabled/nginx_blusteromatic 

     Edit /etc/nginx/sites-enabled/nginx_blusteromatic with your options

3. 3.  Node

     \# apt-get install screen
     
     \# sudo su - blusteromatic
     
     $ screen
     
     $ cd blusteromatic/node-ruby
     
     $ bundle install
     
     Create the config.yml file
     
     $ ruby node.rb
     
     Ctrl-a d to detach screen, etc... See manpage for screen.

4.  License

    Blusteromatic is licensed under the MIT license.
    
    node-ruby is licensed under the MIT license.

5.  Contact
  
    Rhaamo : rhaamo *at* sigpipe *dot* me
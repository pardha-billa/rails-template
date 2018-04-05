**Application Usage**

The main usage of this application is to jump start the brand new application loaded with required stuff.

Here are the ways to use this template while creating a new application

`rails new myapp -d postgresql -m https://raw.githubusercontent.com/pardha-billa/rails-template/master/template.rb`

Or if you have downloaded this repo, you can reference template.rb locally:

`rails new myapp -d postgresql -m template.rb`

Here we are using foreman to start our servers. In general, foreman uses 5000 port. You can modifiy it in Procfile if needed.

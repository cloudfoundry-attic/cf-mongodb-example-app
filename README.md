# Example MongoDB Application [![Build Status](https://travis-ci.org/pivotal-cf/cf-mongodb-example-app.svg)](https://travis-ci.org/pivotal-cf/cf-mongodb-example-app)

This simple application illustrates the use of the Pivotal MongoDB data service in a Ruby application running on Pivotal Cloud Foundry.

## Installation

#### Create a MongoDB service instance

Find your MongoDB service via `cf marketplace`.

```
$ cf marketplace
Getting services from marketplace in org testing / space testing as me...
OK

service       plans     description
p-mongodb   default   MongoDB service
```

Our service is called `p-mongodb`.  To create an instance of this service, use:

```
$ cf create-service p-mongodb default mongodb
```

#### Push the Example Application

The example application comes with a Cloud Foundry `manifest.yml` file, which provides all of the defaults necessary for an easy `cf push`.

```
$ cf push
Using manifest file cf-mongodb-example-app/manifest.yml

Creating app mongodb-example-app in org testing / space testing as me...
OK

Using route mongodb-example-app.example.com
Binding mongodb-example-app.example.com to mongodb-example-app...
OK

Uploading mongodb-example-app...
Uploading from: cf-mongodb-example-app
...
Showing health and status for app mongodb-example-app in org testing / space testing as me...
OK

requested state: started
instances: 0/1
usage: 256M x 1 instances
urls: mongodb-example-app.10.244.0.34.xip.io

     state     since                    cpu    memory          disk
#0   running   2014-04-10 01:42:43 PM   0.0%   75.5M of 256M   0 of 1G
```

If you now curl the application, you'll see that the application has detected that it's not bound to a mongodb instance.

```
$ curl http://mongodb-example-app.example.com/

  You must bind a MongoDB service instance to this application.

  You can run the following commands to create an instance and bind to it:

$ cf create-service mongodb default mongodb-instance
$ cf bind-service app-name mongodb-instance
```

#### Bind the Instance

Now, simply bind the mongodb instance to our application.

```
$ cf bind-service mongodb-example-app mongodb
Binding service mongodb to app mongodb-example-app in org testing / space testing as me...
OK
TIP: Use 'cf push' to ensure your env variable changes take effect
$ cf push
```

## Usage

You can now read and write records by GETting and POSTing to `/table/key`.  Be sure to create the table, first.  In the example below, we create a table named `entries`, add a key/value pair named `foo` with a value of `bar`, and retrieve the value back from `foo`.

```
$ export APP=mongodb-example-app.example.com
$ curl -X POST $APP/entries/foo/bar
$ curl -X GET  $APP/entries/foo
bar
```

Of course, be sure to replace `example.com` with the actual domain of your Pivotal Cloud Foundry installation.

# SKO Demo

## About

This project was originally developed for EY to demonstrate their "Audit Workspace" concept backed by Hadoop.  It is comprised of a web app based on JHipster, a relational database (H2) and HDP.  The primary function of the project is to allow a user to creates an Audit Workspace which ultimately:

* Creates a unique directory structure in HDFS
* Creates a unique Hive Database
* Loads an application specific schema into Hive
* Loads user uploaded data into the Hive database

## About JHipster

This project was built using [JHipster] (https://jhipster.github.io/).  JHipster is essentially a Yeoman Generator that builds out a modern web application using many of the tools I know and love, such as:

* [Spring Boot](http://projects.spring.io/spring-boot/)
* [AngularJS](https://angularjs.org/)
* [Bootstrap](http://getbootstrap.com/)
* [Hibernate](http://hibernate.org/)

In addition to basic scaffolding, JHipster provides a number of great features out of the box:

* Monitoring with Metrics
* Caching with ehcache (local cache) or hazelcast (distributed cache)
* Optional HTTP session clustering with hazelcast
* Optimized static resources (gzip filter, HTTP cache headers)
* Log management with Logback, configurable at runtime
* Connection pooling with HikariCP for optimum performance
* Builds a standard WAR file or an executable JAR file


## Steps to setup the project locally 


### Prepare

* Install Java from the Oracle website.
* Depending on your preferences, install either Maven or Gradle.
* Install Git from git-scm.com. We recommend you also use a tool like SourceTree if you are starting with Git.
* Install Node.js from the Node.js website. This will also install npm, which is the node package manager we are using in the next commands.
* Install Yeoman: npm install -g yo						( May need to run as Admin, use sudo) 
* Install Bower: npm install -g bower						( May need to run as Admin, use sudo) 
* Install Grunt: npm install -g grunt						( May need to run as Admin, use sudo) 
* Install JHipster: npm install -g generator-jhipster		( May need to run as Admin, use sudo) 

### Get the code

git clone <project-url>
git checkout sko

### Setup IDE

- Complete Maven Setup - 

* Open Maven Preferences by selecting IntelliJ IDEA -> Maven 
* Make sure 
	o Either M2_HOME is set as environment variable or override the path in the preferences. 
	o Make sure path of settings.xml and repository is correctly shown in the preferences. If no, override and provide correct values. 
	

- Project Language Level - 
* Right click on the project, choose "Open Module Settings"
* Select Project from the left hand side menu
* Make sure Project language level "7.0 - Diamonds, ARM, multi-catch etc." is selected. 
	
- Create Run Configuration - 

* Using IntelliJ, Select File->Import Project.
* Locate the project and select pom.xml to import project as Maven project
* Once imported, Select Run->Edit Configurations  & create a new configuration 
 	Name : Run
	Main Class : com.hortonworks.poc.ey.Application
	VM Options : -Dorg.jboss.logging.provider=slf4j -Xmx2g -Xms2g -XX:MaxPermSize=512m
	Working Directory : <Absolute-path-to-the-project>/eyboot
	Use classpath of module : eyboot
	Before launch : Make
	<Click Apply and then Ok>



### Build 

To ensure everything is compiling fine, compile the project first by choosing Build->Make Project


### Application Configuration 

The main configuration that needs to be updated for the application are the end points for hadoop services.
Open file <project-home-directory>/eyboot/src/main/resources/config/application-dev.yml
Scroll to the bottom and change the following properties to correctly point to your local hadoop cluster
hadoop:
    hive:
        baseUrl: jdbc:hive2://sandbox.hortonworks.com:10000
        metastoreUrl: thrift://sandbox.hortonworks.com:9083
        username: hive
    hdfs:
        url: hdfs://sandbox.hortonworks.com:8020
        username: hdfs
    webhcat:
        baseUrl: http://sandbox.hortonworks.com:50111/templeton/v1


### Run

To start the server, choose Run->Run'Run' 

### Access  

Access the application at http://localhost:8080/#/login

user id = admin 
password = admin 



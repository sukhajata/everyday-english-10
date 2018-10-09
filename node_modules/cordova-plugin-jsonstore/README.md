# Cordova Plugin for JSONStore SDK


## Before you begin

Make sure you install the following tools and libraries.

* You should already have Node.js/npm and the Cordova package installed. If you don't, you can download and install Node from [https://nodejs.org/en/download/](https://nodejs.org/en/download/).

* The Cordova CLI tool is also required to use this plugin. You can find instructions to install Cordova and set up your Cordova app at [https://cordova.apache.org/#getstarted](https://cordova.apache.org/#getstarted).

To create a Cordova application, use the Cordova Plugin for JSONStore SDK:

1. Create a Cordova application
1. Add Cordova platforms
1. Add Cordova plugin
1. Configure your platform 


## Installing the Cordova Plugin for JSONStore SDK

### 1. Creating a Cordova application

1. Run the following commands to create a new Cordova application. Alternatively you can use an existing application as well. 

	```
	$ cordova create {appName}
	$ cd {appName}
	```
	
1. Edit `config.xml` file and set the desired application name in the `<name>` element instead of a default HelloCordova.

1. Continue editing `config.xml`. 
##### iOS
  For iOS, update the `<platform name="ios">` element with a deployment target declaration as shown in the code snippet below.

	```XML
	<platform name="ios">
		<preference name="deployment-target" value="8.0" />
		<!-- add deployment target declaration -->
	</platform>
	```
##### Android
  For Android, update the `<platform name="android">` element with a minimum and target SDK versions as shown in the code snippet below.

	```XML
	<platform name="android">
		<preference name="android-minSdkVersion" value="15" />
		<preference name="android-targetSdkVersion" value="23" />
		<!-- add minimum and target Android API level declaration -->
	</platform>
	```

	> The minSdkVersion should be above 14.
	
	> The targetSdkVersion should always reflect the latest Android SDK available from Google.

### 2. Adding Cordova platforms

Run the following commands for the platforms that you want to add to your Cordova application

```Bash
cordova platform add ios

cordova platform add android

cordova platform add windows
```

### 3. Adding Cordova plugin

Run the following command from your Cordova application's root directory to add the ibm-mfp-core plugin:

```Bash
cordova plugin add https://github.com/ibm-bluemix-mobile-services/jsonstore-cordova
```

You can check if the plugin installed successfully by running the following command, which lists your installed Cordova plugins:

```Bash
cordova plugin list
```



### 4. Configuring your platform
#### Configuring Your iOS Environment 

1. Build your iOS project by running the following command:

```Bash
cordova build ios
```

#### Configuring your Android Environment

1. Build your Android project by running the following command:

```Bash
cordova build android
```


#### Configuring your Windows Phone Enviroment
1. Build your Windows project by running the following command:
```Bash
	cordova build windows
```


### 5. Security

**Note on Security**: By default security is disabled and if you wish to use it please follow the instructions below. You can retrieve the files needed by extacting them from **jsonstore_encryption.zip**.

#### Configuring your iOS environment



1. Add the following files to your `Link Binary with Libraries` in `Build Phases`:

```Bash
	SQLCipher.framework
	libSQLCipherDatabase.a
```
#### Configuring your Android enviroment

1. Add the following files to your `libs` 

```Bash
	jsonstore_encrypt.jar	
	sqlcipher.jar
```

2. Add the following files to your `jniLibs`
```Bash
	 |-armeabi
	 	-libdatabase_sqlcipher.so
	 	-libsqlcipher_android.so
	 	-libstlport_shared.so
	 	- libuvpn.so
 	 |-x86
 	 	-libdatabase_sqlcipher.so
	 	-libsqlcipher_android.so
	 	-libstlport_shared.so
	 	- libuvpn.so
```

3. Add the following to your `build.gradle` within the `dependencies` block.

```Bash
	 compile fileTree(dir: 'libs', include: ['*.jar'])
```

4. Add the following to your `assets` directory.

```Bash
	icudt46l.zip	
	 |-armeabi
	 	-libcrypto.so.1.0.0.zip
	 	-libssl.so.1.0.0.zip
 	 |-x86
 		-libcrypto.so.1.0.0.zip
	 	-libssl.so.1.0.0.zip
```


#### API References


*Initialize and open connections, get an Accessor, and add data*

```Javascript

		var collectionName = 'people';
        
        // Object that defines all the collections.
        var collections = {
            // Object that defines the 'people' collection.
            people : {
                // Object that defines the Search Fields for the 'people' collection.
                searchFields : {name: 'string', age: 'integer'}
            }
        };
        // Optional options object.
        var options = {
            // Optional username, default 'jsonstore'.
            username : 'saito',
            // Optional password, default no password.
            password : '123',
        };

        JSONStore.init(collections, options)
            .then(function () {
                // Data to add, you probably want to get
                // this data from a network call
                var data = [{name: 'saito', age: 10}];

                // Optional options for add.
                var addOptions = {
                    // Mark data as dirty (true = yes, false = no), default true.
                    markDirty: true
                };
                // Get an accessor to the people collection and add data.
                return JSONStore.get(collectionName).add(data, addOptions);
        })
        .then(function (numberOfDocumentsAdded) {
            // Add was successful.
        })
        .fail(function (errorObject) {
            // Handle failure for any of the previous JSONStore operations (init, add).
        });
```
        
*Find - locate documents inside the Store*
    
```Javascript
        var collectionName = 'people';

        // Find all documents that match the queries.
        var queryPart1 = JSONStore.QueryPart()
                   .equal('name', 'ayumu')
                   .lessOrEqualThan('age', 10)

        var options = {
            // Returns a maximum of 10 documents, default no limit.
            limit: 10,
            // Skip 0 documents, default no offset.
            offset: 0,
            // Search fields to return, default: ['_id', 'json'].
            filter: ['_id', 'json'],
            // How to sort the returned values, default no sort.
            sort: [{name: constant.ASCENDING}, {age: constant.DESCENDING}]
        };
        
        JSONStore.get(collectionName)
        // Alternatives:
        // - findById(1, options) which locates documents by their _id field
        // - findAll(options) which returns all documents
        // - find({'name': 'ayumu', age: 10}, options) which finds all documents
        // that match the query.
            .advancedFind([queryPart1], options)
                .then(function (arrayResults) {
                    // arrayResults = [{_id: 1, json: {name: 'ayumu', age: 10}}]
            })
            .fail(function (errorObject) {
                // Handle failure.
            });
```
            
*Replace - change the documents that are already stored inside a Collection*
```Javascript
        var collectionName = 'people';
        
        // Documents will be located with their '_id' field 
        // and replaced with the data in the 'json' field.
        var docs = [{_id: 1, json: {name: 'hayatashin', age: 99}}];

        var options = {
            // Mark data as dirty (true = yes, false = no), default true.
            markDirty: true
        };

        JSONStore.get(collectionName)
            .replace(docs, options)
                .then(function (numberOfDocumentsReplaced) {
                    // Handle success.
            })
            .fail(function (errorObject) {
                // Handle failure.
            }); 
            
```

*Remove - delete all documents that match the query*

```Javascript
        var collectionName = 'people';
        // Remove all documents that match the queries.
        var queries = [{_id: 1}];

        var options = {
            // Exact match (true) or fuzzy search (false), default fuzzy search.
            exact: true,
            // Mark data as dirty (true = yes, false = no), default true.
            markDirty: true
        };

        JSONStore.get(collectionName)
            .remove(queries, options)
                .then(function (numberOfDocumentsRemoved) {
                    // Handle success.
                })
                .fail(function (errorObject) {
                    // Handle failure.
                });
 ```            
                
*Count - gets the total number of documents that match a query*
    
```Javascript
        var collectionName = 'people';
        // Count all documents that match the query.
        // The default query is '{}' which will 
        // count every document in the collection.
        var query = {name: 'shin'}; 
        var options = {
            // Exact match (true) or fuzzy search (false), default fuzzy search.
            exact: true
        };

        JSONStore.get(collectionName)
            .count(query, options)
                .then(function (numberOfDocumentsThatMatchedTheQuery) {
                    // Handle success.
                })
                .fail(function (errorObject) {
                    // Handle failure.
                });
```
                
*Destroy - wipes data for all users, destroys the internal storage, and clears security artifacts*


```Javascript

        JSONStore.destroy()
            .then(function () {
                // Handle success.
            })
            .fail(function (errorObject) {
                // Handle failure.
            });
```

*Security - enable encryption*

```Javascript
		JSONStore.setEncryption(true);
```
 
           
*Security - close access to all opened Collections for the current user*

```Javascript
        JSONStore.closeAll()
            .then(function () {
                // Handle success.
            })
            .fail(function (errorObject) {
                // Handle failure.
            }); 
 ```

*Security - change the password that is used to access a Store*
   
 ```Javascript 
        // The password should be user input. 
        // It is hard-coded in the example for brevity.
        var oldPassword = '123';
        var newPassword = '456';

        var clearPasswords = function () {
            oldPassword = null;
            newPassword = null;
        };

        // Default username if none is passed is: 'jsonstore'.
        var username = 'kenshin';

        JSONStore.changePassword(oldPassword, newPassword, username)
            .then(function () {
                // Make sure you do not leave the password(s) in memory.
                clearPasswords();
                // Handle success.
            })
            .fail(function (errorObject) {
                // Make sure you do not leave the password(s) in memory.
                clearPasswords();
                // Handle failure.
            }); 
            
 ```
 
*Check whether a document is dirty*
```Javascript
        var collectionName = 'people';
        var doc = {_id: 1, json: {name: 'hoshikata', age: 99}};

        JSONStore.get(collectionName)  
            .isDirty(doc)
                .then(function (isDocumentDirty) {
                    // Handle success.
                    // isDocumentDirty - true if dirty, false otherwise.
                })
                .fail(function (errorObject) {
                    // Handle failure.
                });
 ```
                
*Check the number of dirty documents*
```Javascript
        var collectionName = 'people';
        JSONStore.get(collectionName)  
            .countAllDirty()
                .then(function (numberOfDirtyDocuments) {
                    // Handle success.
                })
                .fail(function (errorObject) {
                    // Handle failure.
                });   
```             
                
*Remove a collection.* 
```Javascript
        var collectionName = 'people';

        JSONStore.get(collectionName)
            .removeCollection()
                .then(function () {
                    // Handle success.
                    // Note: You must call the 'init' API to re-use the empty collection.
                    // See the 'clear' API if you just want to remove all data that is inside.
                })  
                .fail(function (errorObject) {
                    // Handle failure.
                });
 ```
                
*Clear all data that is in a collection*

```Javascript

       var collectionName = 'people';
        JSONStore.get(collectionName)
            .clear()
                .then(function () {
                    // Handle success.
                    // Note: You might want to use the 'removeCollection' API
                    // instead if you want to change the search fields.
                })
                .fail(function (errorObject) {
                    // Handle failure.
                }); 
```
                
*Start a transaction, add some data, remove a document, commit the transaction and roll back the transaction if there is a failure*

```Javascript
        JSONStore.startTransaction()
            .then(function () {
                // Handle startTransaction success.
                // You can call every JSONStore API method except:
                // init, destroy, removeCollection, and closeAll.

                var data = [{name: 'junko'}];
                return JSONStore.get(collectionName).add(data);
            })
            .then(function () {
                    var docs = [{_id: 1, json: {name: 'junko'}}];
                    return JSONStore.get(collectionName).remove(docs);
            })
            .then(function () {
                return JSONStore.commitTransaction();
            })
            .fail(function (errorObject) {
                // Handle failure for any of the previous JSONStore operation.
                //(startTransaction, add, remove).
                JSONStore.rollbackTransaction()
                    .then(function () {
                        // Handle rollback success.
                    })
                    .fail(function () {
                        // Handle rollback failure.
                    })
            });
```
            
*Get file information*
```Javascript
        JSONStore.fileInfo()
            .then(function (res) {
                //res => [{isEncrypted : true, name : kyo, size : 3072}]
            })
            .fail(function () {
                // Handle failure.
            }); 
 ```
            
*Search with like, rightLike, and leftLike*
 ```Javascript   
        // Match all records that contain the search string on both sides.
        // %searchString%
        var arr1 = JSONStore.QueryPart().like('name', 'ca');  // returns {name: 'carlos', age: 10}
        var arr2 = JSONStore.QueryPart().like('name', 'los');  // returns {name: 'carlos', age: 10}

        // Match all records that contain the search string on the left side and anything on the right side.
        // searchString%
        var arr1 = JSONStore.QueryPart().rightLike('name', 'ca');  // returns {name: 'carlos', age: 10}
        var arr2 = JSONStore.QueryPart().rightLike('name', 'los');  // returns nothing

        // Match all records that contain the search string on the right side and anything on the left side.
        // %searchString
        var arr = JSONStore.QueryPart().leftLike('name', 'ca');  // returns nothing
        var arr2 = JSONStore.QueryPart().leftLike('name', 'los');  // returns {name: 'carlos', age: 10}
```
# License

This project is licensed under the terms of the Apache 2 license.
> You can find the license [here](https://github.com/ibm-bluemix-mobile-services/jsonstore-android/blob/development/LICENSE).
/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */
#import <Cordova/CDVPlugin.h>

/**
 Interface with the JSONStore JavaScript API and native code.
 */
@interface StoragePlugin : CDVPlugin

/**
 Used to ensure operations execute serially and in order.
 */
@property (nonatomic, strong) dispatch_queue_t operationQueue;

/**
 Actually creates the database table based on the json schema passed in.
 @param command CDVInvokedUrlCommand
 */
-(void)provision:(CDVInvokedUrlCommand*)command;

/**
 Checks if the keychain is populated with security metadata. If there is security metadata, this method returns 1 (true), meaning there is no need to populate the keychain. However, if the keychain is not populated, this method returns 0 (false), meaning the keychain needs to be populated with security metadata.
 @param command CDVInvokedUrlCommand
 */
-(void)isKeyGenRequired:(CDVInvokedUrlCommand*)command;

/**
 Takes user data in the form of a string of JSON and stores it in the database. If the JSON document is an array, each of the top level objects in the array are stored as individual documents.
 @param command CDVInvokedUrlCommand
 */
-(void)store:(CDVInvokedUrlCommand*)command;

/**
 Enablement for JSONStore Encryption
 @param command CDVInvokedUrlCommand
*/
-(void)encrypt:(CDVInvokedUrlCommand*)command;

/**
 Takes a query as a json document and returns an array of the matched records.
 @param command CDVInvokedUrlCommand
 */
-(void)find:(CDVInvokedUrlCommand*)command;

/**
 Takes an array of query parts as json objects and returns an array of the matched records.
 @param command CDVInvokedUrlCommand
 */
-(void)advancedFind:(CDVInvokedUrlCommand*)command;

/**
 Takes an integer or an array of integers that map to _id.
 @param command CDVInvokedUrlCommand
 */
-(void)findById:(CDVInvokedUrlCommand*)command;

/**
 Take a document or documents and replace their contents in the database.
 @param command CDVInvokedUrlCommand
 */
-(void)replace:(CDVInvokedUrlCommand*)command;

/**
 Marks a document as deleted in the database, the actual deletion does not take place until a sync of that document is performed.
 @param command CDVInvokedUrlCommand
 */
-(void)remove:(CDVInvokedUrlCommand*)command;

/**
 The number of records that are marked as dirty in the local store.
 @param command CDVInvokedUrlCommand
 */
-(void)localCount:(CDVInvokedUrlCommand*)command;

/**
 The number of records that are in the database (excluding those that are marked deleted).
 @param command CDVInvokedUrlCommand
 */
-(void)count:(CDVInvokedUrlCommand*)command;

/**
 Checks if a specific document is marked dirty in the database, returns YES or NO.
 @param command CDVInvokedUrlCommand
 */
-(void) isDirty:(CDVInvokedUrlCommand*)command;

/**
 Returns an Array of documents that are marked dirty in the database.
 @param command CDVInvokedUrlCommand
 */
-(void) allDirty:(CDVInvokedUrlCommand*)command;

/**
 Either remove the dirty flag for records that are added or updated, or deletes the records marked as delete. This method should only be called after a successful sync of a record.
 @param command CDVInvokedUrlCommand
 */
-(void) markClean:(CDVInvokedUrlCommand*)command;

/**
 Drops a table in the database, returns a BOOL.
 @param command CDVInvokedUrlCommand
 */
-(void) dropTable:(CDVInvokedUrlCommand*)command;

/**
 Close the persistent store that contains all the collections. After a close, all collections are unusable until provision is called again.
 @param command CDVInvokedUrlCommand
 */
-(void) closeDatabase:(CDVInvokedUrlCommand*)command;

/**
 Takes the set of items that are needed to encrypt the database and stores them in the keychain.
 @param command CDVInvokedUrlCommand
 */
-(void)changePassword:(CDVInvokedUrlCommand*)command;

/**
 Does not require any parameters (other than the callback), and removes all items from the keychain and destroys the database file.
 @param command CDVInvokedUrlCommand
 */
-(void)destroyDbFileAndKeychain:(CDVInvokedUrlCommand*)command;

/**
 Removes all data from a collection and recreates it with the same search fields.
 @param command CDVInvokedUrlCommand
 */
-(void)clear:(CDVInvokedUrlCommand*)command;

/**
 Smarter replace, lets users pick what to use as the replacement criteria (replace forces usage of '_id', smart replace lets you pick other fields).
 @param command CDVInvokedUrlCommand
 */
-(void)change:(CDVInvokedUrlCommand*)command;

/**
 Returns information about the JSONStore files.
 @param command CDVInvokedUrlCommand
 */
-(void) fileInfo:(CDVInvokedUrlCommand*)command;

/**
 Starts a transaction.
 @param command CDVInvokedUrlCommand
 */
-(void) startTransaction:(CDVInvokedUrlCommand*)command;

/**
 Commits a transaction.
 @param command CDVInvokedUrlCommand
 */
-(void) commitTransaction:(CDVInvokedUrlCommand*)command;

/**
 Rolls back a transaction.
 @param command CDVInvokedUrlCommand
 */
-(void) rollbackTransaction:(CDVInvokedUrlCommand*)command;

#pragma  mark PRIVATE API METHODS

/**
 Checks if the database file is encrypted.
 @param command CDVInvokedUrlCommand
 @private
 */
-(void) _isStoreEncrypted:(CDVInvokedUrlCommand*)command;

@end

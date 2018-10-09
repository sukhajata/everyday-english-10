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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "StoragePlugin.h"
#import <JSONStore/JSONStoreFramework.h>

@implementation StoragePlugin

- (void) pluginInitialize
{
    [super pluginInitialize];
    
    if (! self.operationQueue) {
        self.operationQueue = dispatch_queue_create("com.worklight.jsonstore.storageplugin", DISPATCH_QUEUE_SERIAL);
    }
}

-(void) provision: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
       dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSDictionary* searchFields = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                BOOL dropFirst = [options[JSON_STORE_FLAG_DROP_COLLECTION] boolValue];
                NSString* password = options[JSON_STORE_FLAG_COLLECTION_PASSWORD];
                NSDictionary* additionalSearchFields = options[JSON_STORE_FLAG_ADDITIONAL_SEARCH_FIELDS];
                NSString* username = options[JSON_STORE_FLAG_USERNAME];
                BOOL localKeyGen = [options[JSON_STORE_FLAG_LOCAL_KEYGEN] boolValue];
                NSString* secureRandom = options[JSON_STORE_FLAG_SECURE_RANDOM];
                BOOL analytics = [options[JSON_STORE_FLAG_ANALYTICS] boolValue];
                
                /* Feature removed from Altair
                BOOL osSecurity = [options[JSON_STORE_FLAG_REQUIRE_OS_SECURITY] boolValue];
                NSString* osSecurityMessage = options[JSON_STORE_FLAG_OS_SECURITY_MESSAGE];
                */
                
                JSONStoreCollection* collection = [[JSONStoreCollection alloc] initWithName:collectionName];
                
                collection.searchFields = (NSMutableDictionary*) searchFields;
                collection.additionalSearchFields = (NSMutableDictionary*) additionalSearchFields;
                collection._dropFirst = dropFirst;
                
                JSONStoreOpenOptions* ops = [[JSONStoreOpenOptions alloc] init];
                
                ops.username = username;
                ops.password = password;
                //ops.analytics = analytics;
                
                /* Feature removed from Altair
                ops.requireOperatingSystemSecurity = osSecurity;
                ops.operatingSystemSecurityMessage = osSecurityMessage;
                */
                
                if (! localKeyGen && [secureRandom length]) {
                    ops.secureRandom = secureRandom;
                }
                
                NSError* error = nil;
                
                [[JSONStore sharedInstance] openCollections:@[collection] withOptions:ops error:&error];
                
                int rc = collection.wasReopened ? JSON_STORE_PROVISION_TABLE_EXISTS : JSON_STORE_RC_OK;

                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:rc];
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void)encrypt:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
            BOOL encrypt = command.arguments[0];
            CDVPluginResult * pluginResult = nil;
            
            @try{
                [[JSONStore sharedInstance] setEncryption:encrypt];
            }@catch(NSException *exception){
                NSLog(@"Exception: %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
            
        });
    }];
}

-(void)isKeyGenRequired:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            NSString* username = command.arguments[0];
            
            CDVPluginResult *pluginResult = nil;
            
            @try {
                JSONStoreSecurityManager* secMgr = [[JSONStoreSecurityManager alloc] initWithUsername:username];
                
                int keyChainIsFullyPopulated = [[NSNumber numberWithBool:[secMgr isKeyChainFullyPopulated]] intValue];
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                    messageAsInt:keyChainIsFullyPopulated];
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception: %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) store: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult* pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* data = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                BOOL markDirty = [options[JSON_STORE_FLAG_IS_ADD] boolValue];
                NSDictionary* additionalSearchFields = options[JSON_STORE_FLAG_ADDITIONAL_SEARCH_FIELDS];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    JSONStoreAddOptions* aops = [[JSONStoreAddOptions alloc] init];
                    aops.additionalSearchFields = (NSMutableDictionary*) additionalSearchFields;
                    
                    NSError* error = nil;
                    
                    NSNumber* docsStored = [col addData:data
                                     andMarkDirty:markDirty
                                      withOptions:aops
                                            error:&error];

                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[docsStored intValue]];
                    }
                }
                
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception: %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void)advancedFind:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray *input = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                NSNumber* limit = options[JSON_STORE_FLAG_LIMIT];
                NSNumber* offset = options[JSON_STORE_FLAG_OFFSET];
                NSArray* sort = options[JSON_STORE_FLAG_SORT];
                NSArray* filter = options[JSON_STORE_FLAG_FILTER];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    JSONStoreQueryOptions* ops = [[JSONStoreQueryOptions alloc] init];
                    
                    ops.limit = limit;
                    ops.offset = offset;
                    ops._sort = (NSMutableArray*) sort;
                    ops._filter= (NSMutableArray*) filter;
                    
                    NSError* error = nil;
                    
                    NSMutableArray* queryParts = [[NSMutableArray alloc] initWithCapacity:5];
                    
                    if ([JSONStoreValidator isArray:input]) {
                     
                        for (NSDictionary* queryPart in input) {
                            
                            if ([JSONStoreValidator isDictionary:queryPart]) {
                                
                                JSONStoreQueryPart* query = [[JSONStoreQueryPart alloc] init];
                                
                                for (NSString* key in queryPart) {
                                    
                                    id current = queryPart[key];
                                    
                                    if ([JSONStoreValidator isArray:current]) {
                                        
                                        if ([key rangeOfString:JSON_STORE_KEY_FIND_LIKE].location != NSNotFound) {
                                            query._like = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_NOT_LIKE].location != NSNotFound) {
                                            query._notLike = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_RIGHT_LIKE].location != NSNotFound) {
                                            query._rightLike = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_NOT_RIGHT_LIKE].location != NSNotFound) {
                                            query._notRightLike = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_LEFT_LIKE].location != NSNotFound) {
                                            query._leftLike = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_NOT_LEFT_LIKE].location != NSNotFound) {
                                            query._notLeftLike = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_LESS_THAN].location != NSNotFound) {
                                            query._lessThan = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_LESS_OR_EQUAL_THAN].location != NSNotFound) {
                                            query._lessOrEqualThan = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_GREATER_THAN].location != NSNotFound) {
                                            query._greaterThan = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_GREATER_OR_EQUAL_THAN].location != NSNotFound) {
                                            query._greaterOrEqualThan = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_EQUAL].location != NSNotFound) {
                                            query._equal = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_FIND_NOT_EQUAL].location != NSNotFound) {
                                            query._notEqual = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_INSIDE].location != NSNotFound) {
                                            query._inside = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_NOT_INSIDE].location != NSNotFound) {
                                            query._notInside = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_BETWEEN].location != NSNotFound) {
                                            query._between = (NSMutableArray*) current;
                                        } else if([key rangeOfString:JSON_STORE_KEY_NOT_BETWEEN].location != NSNotFound) {
                                            query._notBetween = (NSMutableArray*) current;
                                        }
                                        
                                        [queryParts addObject:query];
                                    }
                                }
                            }
                        }
                    }
                    
                    NSArray* results = [col findWithQueryParts:queryParts
                                                       andOptions:ops
                                                            error:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsArray:results];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception: %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) find: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray *queries = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                NSNumber* limit = options[JSON_STORE_FLAG_LIMIT];
                NSNumber* offset = options[JSON_STORE_FLAG_OFFSET];
                BOOL exactMatch = [options[JSON_STORE_FLAG_EXACT] boolValue];
                NSArray* sort = options[JSON_STORE_FLAG_SORT];
                NSArray* filter = options[JSON_STORE_FLAG_FILTER];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    JSONStoreQueryOptions* ops = [[JSONStoreQueryOptions alloc] init];
                    
                    ops.limit = limit;
                    ops.offset = offset;
                    ops._sort = (NSMutableArray*) sort;
                    ops._filter= (NSMutableArray*) filter;
                    
                    NSError* error = nil;
                    
                    NSMutableOrderedSet* set = [[NSMutableOrderedSet alloc] initWithCapacity:10];
                    
                    for (NSDictionary* currentQuery in queries) {
                        
                        JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
                        
                        if (exactMatch) {
                            queryPart._equal = (NSMutableArray*) @[currentQuery];
                        } else {
                            queryPart._like = (NSMutableArray*) @[currentQuery];
                        }
                        
                        NSArray* queryParts = @[queryPart];
                        
                        NSArray* resultsArr = [col findWithQueryParts:queryParts
                                                              andOptions:ops
                                                                   error:&error];
                        
                        [set addObjectsFromArray:resultsArr];
                        
                        if (! resultsArr) {
                            break; //Error found, go to failure callback
                        }
                    }
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsArray:[set array]];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception: %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) findById: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* ids = command.arguments[1];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSMutableArray* results = [[NSMutableArray alloc] init];
                    
                    JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
                    
                    for (NSNumber* currentId in ids) {
                        
                        queryPart._ids = (NSMutableArray*) @[currentId];
                        
                        NSArray* partialResults = [col findWithQueryParts:@[queryPart]
                                                                  andOptions:nil
                                                                       error:&error];
                        
                        if(! partialResults) {
                            break;
                        } else {
                            [results addObjectsFromArray:partialResults];
                        }
                    }

                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsArray:results];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception: %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) replace: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* documents = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                BOOL markDirty = ![options[JSON_STORE_FLAG_IS_REFRESH] boolValue];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSNumber* numReplaced = [col replaceDocuments:documents
                                               andMarkDirty:markDirty
                                                      error:&error];
                    
                    if (error) {
                        
                        NSArray* failedDocs = error.userInfo[JSON_STORE_ERROR_OBJ_KEY_DOCS];
                        
                        if (failedDocs) {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                              messageAsArray:failedDocs];
                        } else {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsInt:(int)error.code];
                        }
                        
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[numReplaced intValue]];
                    }
                }
                
            } @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) remove: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* documents =  command.arguments[1];
                NSDictionary* options = command.arguments[2];
                BOOL markDirty = ![options[JSON_STORE_FLAG_IS_ERASE] boolValue];
                BOOL exactMatch = [options[JSON_STORE_FLAG_EXACT] boolValue];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSNumber* numUpdated = [col _removeWithQueries:documents
                                               andMarkDirty:markDirty
                                                 exactMatch:exactMatch
                                                      error:&error];
                    
                    if (error) {
                        
                        NSArray* failedDocs = error.userInfo[JSON_STORE_ERROR_OBJ_KEY_DOCS];
                        
                        if (failedDocs) {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                              messageAsArray:failedDocs];
                        } else {
                            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsInt:(int)error.code];
                        }
                        
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[numUpdated intValue]];
                    }
                }
                
            } @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) localCount: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
            
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSNumber* countResult = [col countAllDirtyDocumentsWithError:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[countResult intValue]];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) count:(CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSDictionary* query = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                BOOL exactMatch = [options[JSON_STORE_FLAG_EXACT] boolValue];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    NSNumber* countResult;
                    
                    if(query == nil || [query count] == 0) {
                        
                        countResult = [col countAllDocumentsAndReturnError:&error];
                        
                    } else {
                        JSONStoreQueryPart* queryPart = [[JSONStoreQueryPart alloc] init];
                        
                        if (exactMatch) {
                            queryPart._equal = (NSMutableArray*) @[query];
                        } else {
                            queryPart._like = (NSMutableArray*) @[query];
                        }
                        
                        countResult = [col countWithQueryParts:@[queryPart]
                                                         error:&error];
                    }
                
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[countResult intValue]];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) isDirty: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSDictionary* document = command.arguments[1];
                int documentId = [document[JSON_STORE_FIELD_ID] intValue];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    int result = [col isDirtyWithDocumentId:documentId
                                                      error:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:result ? JSON_STORE_RC_JS_TRUE : JSON_STORE_RC_JS_FALSE];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) dropTable: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    [col removeCollectionWithError:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:JSON_STORE_RC_OK];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) closeDatabase: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSError* error = nil;
                
                [[JSONStore sharedInstance] closeAllCollectionsAndReturnError:&error];
                
                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:JSON_STORE_RC_OK];
                }
            }
            @catch (NSException *exception) {
                
               NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) markClean: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* documents = command.arguments[1];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSNumber* numCleaned = [col markDocumentsClean:documents
                                                       error:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[numCleaned intValue]];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) allDirty: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* documents = command.arguments[1];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSArray* dirtyDocs = [col _allDirtyWithDocuments:documents
                                                               error:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsArray:dirtyDocs];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) changePassword: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* oldPassword = command.arguments[0];
                NSString* newPassword = command.arguments[1];
                NSString* username = command.arguments[2];
                
                NSError* error = nil;
                
                [[JSONStore sharedInstance] changeCurrentPassword:oldPassword
                                 withNewPassword:newPassword
                                     forUsername:username
                                           error:&error];
                
                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:JSON_STORE_RC_OK];
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) destroyDbFileAndKeychain: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            //Gets the value 'NSNull' if the username is not passed
            NSString* username = command.arguments[0];
        
            @try {
                
                NSError* error = nil;
                
                if (username != (id)[NSNull null] && username && username.length > 0) {
                    
                    [[JSONStore sharedInstance] destroyWithUsername:username error:&error];
                    
                } else {
                    
                    [[JSONStore sharedInstance] destroyDataAndReturnError:&error];
                }
                
                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:JSON_STORE_RC_OK];
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) clear: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    [col clearCollectionWithError:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:JSON_STORE_RC_OK];
                    }
                    
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) change: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
            
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSString* collectionName = command.arguments[0];
                NSArray* data = command.arguments[1];
                NSDictionary* options = command.arguments[2];
                
                NSArray* replaceCriteriaSearchFields = options[JSON_STORE_FLAG_REPLACE_CRITERIA];
                BOOL addNew = [options[JSON_STORE_FLAG_ADD_NEW] boolValue];
                BOOL markDirty = [options[JSON_STORE_FLAG_MARK_DIRTY] boolValue];
                
                JSONStoreCollection* col = [[JSONStore sharedInstance] getCollectionWithName:collectionName];
                
                if (! col) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_DATABASE_NOT_OPEN];
                } else {
                    
                    NSError* error = nil;
                    
                    NSNumber* updatedOrAdded = [col changeData:data withReplaceCriteria:replaceCriteriaSearchFields
                                                  addNew:addNew
                                               markDirty:markDirty
                                                   error:&error];
                    
                    if (error) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                            messageAsInt:(int)error.code];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                            messageAsInt:[updatedOrAdded intValue]];
                    }
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) startTransaction: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSError* error = nil;
                
                BOOL worked = [[JSONStore sharedInstance] startTransactionAndReturnError:&error];
                
                int rc = worked ? JSON_STORE_RC_OK : JSON_STORE_PERSISTENT_STORE_FAILURE;
                
                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:rc];
                }
                
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
            
        });
    }];
}

-(void) commitTransaction: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSError* error = nil;
                
                BOOL worked = [[JSONStore sharedInstance] commitTransactionAndReturnError:&error];
                
                int rc = worked ? JSON_STORE_RC_OK : JSON_STORE_PERSISTENT_STORE_FAILURE;
                
                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:rc];
                }
                
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) rollbackTransaction: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSError* error = nil;
                
                BOOL worked = [[JSONStore sharedInstance] rollbackTransactionAndReturnError:&error];
                
                int rc = worked ? JSON_STORE_RC_OK : JSON_STORE_PERSISTENT_STORE_FAILURE;
                
                if (error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:rc];
                }
                
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

-(void) fileInfo: (CDVInvokedUrlCommand*) command
{
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSError* error = nil;
                
                NSArray* fileInfo = [[JSONStore sharedInstance] fileInfoAndReturnError:&error];
                
                if (error) {
                    
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:JSON_STORE_FILE_INFO_ERROR];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                 messageAsArray:fileInfo];
                }
            }
            @catch (NSException *exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        });
    }];
}

#pragma mark Private

-(void) _isStoreEncrypted: (CDVInvokedUrlCommand*) command {
    
    [self.commandDelegate runInBackground:^{
        
        dispatch_sync(self.operationQueue, ^{
        
            CDVPluginResult *pluginResult = nil;
            
            @try {
                
                NSError* error = nil;
                
                BOOL isEnc = [[JSONStore sharedInstance] _isStoreEncryptedAndReturnError:&error];
                
                if(error) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                        messageAsInt:(int)error.code];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                        messageAsInt:isEnc];
                }
                
                [self.commandDelegate sendPluginResult:pluginResult
                                            callbackId:command.callbackId];
            }
            @catch(NSException* exception) {
                
                NSLog(@"Exception : %@", exception);
                
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsInt:JSON_STORE_PERSISTENT_STORE_FAILURE];
            }
            
        });
    }];
}

@end
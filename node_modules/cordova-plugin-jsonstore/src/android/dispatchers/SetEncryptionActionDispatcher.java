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

package com.jsonstore.dispatchers;


import com.jsonstore.api.JSONStore;
import com.jsonstore.database.DatabaseConstants;
import com.jsonstore.types.JSONStoreContext;
import com.jsonstore.types.JSONStoreParameterType;

import org.apache.cordova.PluginResult;

public class SetEncryptionActionDispatcher extends BaseActionDispatcher {
    private static final String PARAM_ENCRYPT = "encrypt";
    private static final String DISPATCHER_NAME = "encryption";
    
    public SetEncryptionActionDispatcher(android.content.Context context) {
        // These paramaters are NOT loggable since they contain password information
        super(DISPATCHER_NAME, context);
        addParameter(SetEncryptionActionDispatcher.PARAM_ENCRYPT, true, JSONStoreParameterType.BOOLEAN);
        
    }
    
    @Override
    public PluginResult actionDispatch(JSONStoreContext jsContext) {
        try {
            boolean encrypt  = jsContext.getBooleanParameter(SetEncryptionActionDispatcher.PARAM_ENCRYPT);
            JSONStore jsStore = JSONStore.getInstance(getAndroidContext());
            
            jsStore.setEncryption(encrypt);
            
        } catch (Exception e) {
            return new PluginResult(PluginResult.Status.ERROR, DatabaseConstants.RC_DB_NOT_OPEN);
        } 
        
        return new PluginResult(PluginResult.Status.OK, BaseActionDispatcher.RC_OK);
    }
}

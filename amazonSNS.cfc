/*
Copyright 2011 Jeremy Battle (battlejj@gmail.com).

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
component accessors="true" {
	property name="snsVersion" default="2" required="true";
	property name="signatureVersion" default="2";
	property name="defaultURL" default="http://sns.us-east-1.amazonaws.com/";
	property name="signatureMethod" default="HmacSHA1" hint="Signature method for aws; possible values are HmacSHA1 and HmacSHA256";
	property name="awsKey" default="";
	property name="awsSecret" default="";
	
	public amazonSNS function init(required string awsKey, required string awsSecret){
		setSnsVersion(2);
		setSignatureVersion(2);
		setSignatureMethod('HmacSHA256');
		setRegion();
		setAwsKey(arguments.awsKey);
		setAwsSecret(arguments.awsSecret);		
		
		return this;
		
	}
	
	public void function setRegion(required string region = 'REGION_US_E1'){
		
		switch(arguments.region){
			case 'REGION_US_E1': 
				setDefaultURL('http://sns.us-east-1.amazonaws.com/');		
				break;
			case 'REGION_US_W1': 
				setDefaultURL('http://sns.us-west-1.amazonaws.com/');		
				break;
			case 'REGION_EU_W1': 
				setDefaultURL('http://sns.eu-west-1.amazonaws.com/');		
				break;
			case 'REGION_APAC_SE1': 
				setDefaultURL('http://sns.ap-southeast-1.amazonaws.com/');		
				break;
			case 'REGION_APAC_NE1': 
				setDefaultURL('http://sns.ap-northeast-1.amazonaws.com/');		
				break;
		}
		
	}
	
	public struct function addPermission(required string topicArn, required string policyName, required array AWSAccountIds, required array ActionNames){
		
		var action = "AddPermission";
		var timeStamp = amazonDateFormat(now());	
		var cleanedName = removeSpecialChars(arguments.policyName);
		var params = {"Label" = cleanedName, "TopicArn" = arguments.topicArn};
		
		for(var i = 1; i <= arrayLen(arguments.AWSAccountIds); i++){			
			params["AWSAccountId.member.#i#"] = arguments.AWSAccountIds[i];			
		}
		
		for(var i = 1; i <= arrayLen(arguments.ActionNames); i++){
			params["ActionName.member.#i#"] = arguments.ActionNames[i];
		}
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
		var returnSt = {success=true};
	}
	
	public struct function confirmSubscription(boolean AuthenticateOnUnsubscribe = false, required string Token, required String TopicArn){
		
		var action = "ConfirmSubscription";
		var timeStamp = amazonDateFormat(now());	
		var params = {};
			
		params["AuthenticateOnUnsubscribe"] = arguments.AuthenticateOnUnsubscribe;
		params["Token"] = arguments.Token;
		params["TopicArn"] = arguments.TopicArn;
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
				
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());		
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="AuthenticateOnUnsubscribe",value= arguments.AuthenticateOnUnsubscribe);	
		httpService.addParam(type="URL",name="Token",value= arguments.Token);
		httpService.addParam(type="URL",name="TopicArn",value= arguments.TopicArn);	
		httpService.addParam(type="URL",name="Signature",value=trim(signature));	
		
		var returnSt = {success=true};
		
		var result = httpService.send().getPrefix().fileContent;

		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.SubscriptionArn = xmlSearch(result,"//*[local-name()='SubscriptionArn']")[1].xmlText;
			returnSt.message = "Subscription confirmed.";
		}
		
		return returnSt;
		
	} 
	
	public struct function createTopic(required string name){
		var action = "CreateTopic";
		var timeStamp = amazonDateFormat(now());	
		var cleanedName = removeSpecialChars(arguments.name);
		var params = {"Name" = cleanedName};
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
		var returnSt = {success=true};
		
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());
		httpService.addParam(type="URL",name="Name",value=cleanedName);
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="Signature",value=trim(signature));
		
		var result = httpService.send().getPrefix().fileContent;
		
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.topic = xmlSearch(result,"//*[local-name()='TopicArn']")[1].xmlText;
		}
		
		return returnSt;
	}
	
	public struct function deleteTopic(required string topicArn){
		var action = "DeleteTopic";
		var timeStamp = amazonDateFormat(now());	
		var params = {"TopicArn" = arguments.topicArn};
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
		var returnSt = {success=true};
			
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());
		httpService.addParam(type="URL",name="TopicArn",value=arguments.topicArn);
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="Signature",value=trim(signature));	
			
		var result = httpService.send().getPrefix().fileContent;
		
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.message = "Topic successfully deleted.";
		}
		
		return returnSt;
	}
	
	public struct function getTopicAttributes(required string TopicArn){
		var action = "GetTopicAttributes";
		var timeStamp = amazonDateFormat(now());	
		var params = {"TopicArn" = arguments.topicArn};
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
		var returnSt = {success=true};
			
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());
		httpService.addParam(type="URL",name="TopicArn",value=arguments.topicArn);
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="Signature",value=trim(signature));	
			
		var result = httpService.send().getPrefix().fileContent;
		
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.attributes = {};
			var temp = xmlSearch(result,"//*[local-name()='entry']");
			for(i = 1; i <= arrayLen(temp); i++){
				returnSt.attributes[temp[i].key.xmlText] = temp[i].value.xmlText;
			}		
		}
		
		return returnSt;
		
	}
	
	public struct function listSubscriptions(string NextToken){
		var action = "ListSubscriptions";
		var timeStamp = amazonDateFormat(now());	
		var params = {};
		
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);	
		
		if(structKeyExists(arguments,"NextToken") && len(trim(arguments.NextToken))){
			params["NextToken"] = arguments.NextToken;			
			httpService.addParam(type="URL",name="NextToken",value=arguments.NextToken);
		}
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
			
		httpService.addParam(type="URL",name="Signature",value=trim(signature));	
			
		var result = httpService.send().getPrefix().fileContent;
		var returnSt = {success=true};
			
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			//sreturnSt.attributes = xmlSearch(result,"//*[local-name()='entry']");
			returnSt.subscriptions = [];
			var subs = xmlSearch(result,"//*[local-name()='member']");
			for(i = 1; i <= arrayLen(subs); i++){
				var props = { 
					"TopicArn" = subs[i].topicArn.xmlText,
					 "Protocol" = subs[i].protocol.xmlText, 
					 "SubscriptionArn" = subs[i].subscriptionArn.xmlText,
					 "Owner" = subs[i].owner.xmlText,
					 "Endpoint" = subs[i].endpoint.xmlText
				 };
				
				arrayAppend(returnSt.subscriptions,props);
			}		
		}
		
		return returnSt;
	}
	
	public struct function listSubscriptionsByTopic(required string TopicArn, string NextToken){
		var action = "ListSubscriptionsByTopic";
		var timeStamp = amazonDateFormat(now());	
		var params = {"TopicArn" = arguments.TopicArn};
		
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);			
		httpService.addParam(type="URL",name="TopicArn",value=arguments.topicArn);
		
		if(structKeyExists(arguments,"NextToken") && len(trim(arguments.NextToken))){
			params["NextToken"] = arguments.NextToken;			
			httpService.addParam(type="URL",name="NextToken",value=arguments.NextToken);
		}
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
			
		httpService.addParam(type="URL",name="Signature",value=trim(signature));	
			
		var result = httpService.send().getPrefix().fileContent;
		var returnSt = {success=true};
			
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.subscriptions = [];
			var subs = xmlSearch(result,"//*[local-name()='member']");
			for(i = 1; i <= arrayLen(subs); i++){
				var props = { 
					"TopicArn" = subs[i].topicArn.xmlText,
					 "Protocol" = subs[i].protocol.xmlText, 
					 "SubscriptionArn" = subs[i].subscriptionArn.xmlText,
					 "Owner" = subs[i].owner.xmlText,
					 "Endpoint" = subs[i].endpoint.xmlText
				 };
				
				arrayAppend(returnSt.subscriptions,props);
			}		
		}
		
		return returnSt;
	}
	
	public struct function listTopics(){
		var action = "ListTopics";
		var timeStamp = amazonDateFormat(now());	
		var signature = generateSignature(action=action,timestamp=timeStamp);
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="Signature",value=trim(signature));
		
		var result = httpService.send().getPrefix().fileContent;
		var returnSt = { success = true };
		
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			var topicsArray = xmlSearch(result,"//*[local-name()='TopicArn']");
			
			returnSt.topics = [];
			
			for(var i = 1; i <= arrayLen(topicsArray); i++){
				arrayAppend(returnSt.topics,topicsArray[i].XmlText);
			}
			returnSt.message = "Topics retreived successfully.";
		}
				
		return returnSt;
	}
	
	public struct function publish(required string Message, required string TopicArn , string Subject = '', string MessageStructure = ''){
		var action = "Publish";
		var timeStamp = amazonDateFormat(now());	
		var params = {};
		
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());		
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="Message",value= arguments.Message);	
		httpService.addParam(type="URL",name="TopicArn",value= arguments.TopicArn);	
		
		params["Message"] = arguments.Message;
		params["TopicArn"] = arguments.TopicArn;
		
		if(len(trim(arguments.Subject))){
			params["Subject"] = arguments.Subject;	
			httpService.addParam(type="URL",name="Subject",value= arguments.Subject);	
		}
		
		if(len(trim(arguments.MessageStructure))){
				arguments["MessageStructure"] = arguments.MessageStructure;
				httpService.addParam(type="URL",name="MessageStructure",value= arguments.MessageStructure);	
		}

		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
		httpService.addParam(type="URL",name="Signature",value=trim(signature));			
		
		var returnSt = {success=true};
		
		var result = httpService.send().getPrefix().fileContent;
		
		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.messageId = xmlSearch(result,"//*[local-name()='MessageId']")[1].xmlText;
		}
		
		return returnSt;
		
	}
	
	public struct function removePermission(required string Label, required string TopicArn){
		var action = "RemovePermission";
		var timeStamp = amazonDateFormat(now());	
		var params = {};
			
		params["Label"] = arguments.Label;
		params["TopicArn"] = arguments.TopicArn;
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
				
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());		
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);			
		httpService.addParam(type="URL",name="Protocol",value= arguments.Label);
		httpService.addParam(type="URL",name="TopicArn",value= arguments.TopicArn);	
		httpService.addParam(type="URL",name="Signature",value=trim(signature));			
		
		var returnSt = {success=true};
		
		var result = httpService.send().getPrefix().fileContent;

		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.RequestId = xmlSearch(result,"//*[local-name()='RequestId']")[1].xmlText;
			returnSt.message = "Permission was removed successfully.";
		}
		
		return returnSt;
		
	}
	
	public struct function setTopicAttributes(required string AttributeName, required string AttributeValue, required string TopicArn){
		var action = "SetTopicAttributes";
		var timeStamp = amazonDateFormat(now());	
		var params = {};
			
		params["AttributeName"] = arguments.AttributeName;
		params["AttributeValue"] = arguments.AttributeValue;
		params["TopicArn"] = arguments.TopicArn;
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
				
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());		
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="AttributeName",value= arguments.AttributeName);	
		httpService.addParam(type="URL",name="AttributeValue",value= arguments.AttributeValue);
		httpService.addParam(type="URL",name="TopicArn",value= arguments.TopicArn);	
		httpService.addParam(type="URL",name="Signature",value=trim(signature));			
		
		var returnSt = {success=true};
		
		var result = httpService.send().getPrefix().fileContent;

		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.RequestId = xmlSearch(result,"//*[local-name()='RequestId']")[1].xmlText;
			returnSt.message = "Attributes set successfully.";
		}
		
		return returnSt;
		
	}
	
	public struct function subscribe(required string Endpoint, required string Protocol, required string TopicArn){
		var action = "Subscribe";
		var timeStamp = amazonDateFormat(now());	
		var params = {};
			
		params["Endpoint"] = arguments.Endpoint;
		params["Protocol"] = arguments.Protocol;
		params["TopicArn"] = arguments.TopicArn;
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
				
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());		
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);		
		httpService.addParam(type="URL",name="Endpoint",value= arguments.Endpoint);	
		httpService.addParam(type="URL",name="Protocol",value= arguments.Protocol);
		httpService.addParam(type="URL",name="TopicArn",value= arguments.TopicArn);	
		httpService.addParam(type="URL",name="Signature",value=trim(signature));			
		
		var returnSt = {success=true};
		
		var result = httpService.send().getPrefix().fileContent;

		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.SubscriptionArn = xmlSearch(result,"//*[local-name()='SubscriptionArn']")[1].xmlText;
			returnSt.message = "Subscription is pending confirmation.";
		}
		
		return returnSt;
		
	}
	
	public struct function unsubscribe(required string SubscriptionArn){
		var action = "Unsubscribe";
		var timeStamp = amazonDateFormat(now());	
		var params = {"SubscriptionArn" = arguments.SubscriptionArn};
		
		var signature = generateSignature(action=action,timestamp=timeStamp,params=params);
				
		var httpService = new http(); 
		httpService.setCharset("utf-8"); 
		httpService.setMethod("GET"); 
    	httpService.setURL(getDefaultURL());
		httpService.addParam(type="URL",name="Action",value=action);
		httpService.addParam(type="URL",name="AWSAccessKeyId",value=getAwsKey());		
		httpService.addParam(type="URL",name="SignatureMethod",value=getSignatureMethod());
		httpService.addParam(type="URL",name="SignatureVersion",value=getSignatureVersion());		
		httpService.addParam(type="URL",name="Timestamp",value=timeStamp);			
		httpService.addParam(type="URL",name="SubscriptionArn",value= arguments.SubscriptionArn);
		httpService.addParam(type="URL",name="Signature",value=trim(signature));			
		
		var returnSt = {success=true};
		
		var result = httpService.send().getPrefix().fileContent;

		if(arrayLen(xmlSearch(result,"//*[local-name()='Error']"))){
			returnSt.success = false;
			returnSt.errorCode = xmlSearch(result,"//*[local-name()='Code']")[1].xmlText;
			returnSt.message = xmlSearch(result,"//*[local-name()='Message']")[1].xmlText;
		} else {
			returnSt.RequestId = xmlSearch(result,"//*[local-name()='RequestId']")[1].xmlText;
			returnSt.message = "Unsubscribe was successful.";
		}
		
		return returnSt;
		
	}
	
	
	
	private string function amazonDateFormat(required date dateToFormat) hint="Follows the ISO 8601 standard" {
		
		var formattedDate = dateAdd("s", getTimeZoneInfo().utcTotalOffset, arguments.dateToFormat);
		
		return "#dateFormat(formattedDate,"yyyy-mm-dd")#T#timeFormat(formattedDate,'HH:mm:ss')#Z";
		
	}
	
	private function hmacSHA1(required string stringToSign){
		var signatureMethod = getSignatureMethod();
		var awsSecret = getAwsSecret();		
		var signingKey = createObject("java", "javax.crypto.spec.SecretKeySpec").init(awsSecret.getBytes(), signatureMethod);
		var mac = createObject("java", "javax.crypto.Mac").getInstance(signatureMethod);
		mac.init(signingKey);
		var signature = toBase64(mac.doFinal(arguments.stringToSign.getBytes()));

		return trim(signature);		
	}
	
	private function hmacSHA256(required string stringToSign){
		var signatureMethod = getSignatureMethod();
		var awsSecret = getAwsSecret();		
		var signingKey = createObject("java", "javax.crypto.spec.SecretKeySpec").init(awsSecret.getBytes(), signatureMethod);
		var mac = createObject("java", "javax.crypto.Mac").getInstance(signatureMethod);
		mac.init(signingKey);
		var signature = toBase64(mac.doFinal(arguments.stringToSign.getBytes()));

		return trim(signature);		
	}
	
	private string function generateSignature(required string verb = "GET",required string action, required string timestamp){
		
		var structKeys = [];
		var temp = {};
		
		temp["Action"] = arguments.action;
		temp["AWSAccessKeyId"] = getAwsKey();
		temp["SignatureMethod"] = getSignatureMethod();
		temp["SignatureVersion"] = getSignatureVersion();
		temp["Timestamp"] = arguments.timestamp;
		
		if(structKeyExists(arguments,"params") && isStruct(arguments.params)){
			for(key in arguments.params){
				temp["#key#"] = arguments.params[key];				
			}			
		}		

		var structKeys = listToArray(structKeyList(temp));
		 ArraySort(structKeys, "text", "asc");

		var	stringToSign = "#arguments.verb##chr(10)#";
		stringToSign &= "sns.us-east-1.amazonaws.com#chr(10)#";
		stringToSign &= "/#chr(10)#";
		
    	for(var x = 1; x <= arrayLen(structKeys); x++){
    		stringToSign &= structKeys[x] & '=' & urlEncode(temp[structKeys[x]]) & (x < arrayLen(structKeys) ? '&' : '');
    	}
		var signingFunction = variables[getSignatureMethod()];
		
		var signature = signingFunction(stringToSign=trim(stringToSign));

		return signature;
		
	}
	
	private string function urlEncode(required string aString){
		return replacelist(urlencodedformat(arguments.aString), "%2D,%2E,%5F,%7E,+", "-,.,_,~,%20");
    } 
    
    private any function removeSpecialChars(required string filename){
		var badCharsRegex = "[" & "'" & '"' & "##" & "/\\%&`@~!,:;=<>\+\*\?\[\]\^\$\(\)\{\}\|]";
		return replace(reReplace(arguments.filename,badCharsRegex,"","all")," ","-","all");
	}   
	
}